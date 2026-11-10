import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/money_transaction.dart';
import 'finance_snapshot.dart';

const _entriesKey = 'spendwise.entries.v1';
const _budgetsKey = 'spendwise.budgets.v1';
const _darkKey = 'spendwise.dark_mode.v1';

abstract class FinanceStorage {
  String get description;
  Future<FinanceSnapshot> load();
  Future<void> upsertEntry(MoneyTransaction entry);
  Future<void> deleteEntry(String id);
  Future<void> upsertBudget(BudgetLimit budget);
  Future<void> deleteBudget(String category);
  Future<void> saveDarkMode(bool value);
  Future<void> replaceAll(FinanceSnapshot snapshot);
  /// Remove all in-app financial records and legacy preference copies.
  Future<void> eraseAllUserData();
}

/// Android/iOS/macOS use SQLite. Web/Windows/Linux retain existing preferences
/// until a separate cross-platform SQLite implementation is introduced.
FinanceStorage createFinanceStorage() {
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    return SqliteFinanceStorage();
  }
  return PreferencesFinanceStorage();
}

/// Reads the original v1 keys. Invalid JSON must throw instead of resetting data.
Future<FinanceSnapshot> _readLegacy(SharedPreferencesAsync prefs) async {
  final rawEntries = await prefs.getString(_entriesKey);
  final rawBudgets = await prefs.getString(_budgetsKey);
  final savedMode = await prefs.getBool(_darkKey);
  final rawEntriesList = rawEntries == null ? <dynamic>[] : jsonDecode(rawEntries);
  final rawBudgetList = rawBudgets == null ? <dynamic>[] : jsonDecode(rawBudgets);
  return FinanceSnapshot.fromJson({
    'schema_version': 1,
    'entries': rawEntriesList,
    'budgets': rawBudgetList,
    'dark_mode': savedMode ?? false,
  });
}

class PreferencesFinanceStorage implements FinanceStorage {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  @override
  String get description => 'Local preferences (web/desktop compatibility)';

  @override
  Future<FinanceSnapshot> load() => _readLegacy(_prefs);

  @override
  Future<void> upsertEntry(MoneyTransaction entry) async {
    final current = await load();
    final list = [...current.entries]..removeWhere((e) => e.id == entry.id);
    list.add(entry);
    await _prefs.setString(_entriesKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  @override
  Future<void> deleteEntry(String id) async {
    final current = await load();
    final list = [...current.entries]..removeWhere((e) => e.id == id);
    await _prefs.setString(_entriesKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  @override
  Future<void> upsertBudget(BudgetLimit budget) async {
    final current = await load();
    final list = [...current.budgets]..removeWhere((e) => e.category == budget.category);
    list.add(budget);
    await _prefs.setString(_budgetsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  @override
  Future<void> deleteBudget(String category) async {
    final current = await load();
    final list = [...current.budgets]..removeWhere((e) => e.category == category);
    await _prefs.setString(_budgetsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  @override
  Future<void> saveDarkMode(bool value) => _prefs.setBool(_darkKey, value);

  @override
  Future<void> replaceAll(FinanceSnapshot snapshot) async {
    snapshot.validate();
    // Best-effort rollback on web/desktop. Only Android SQLite offers fully
    // atomic multi-table replacement in this upgrade.
    final old = await load();
    try {
      await _writeSnapshot(snapshot);
    } catch (_) {
      try { await _writeSnapshot(old); } catch (_) { /* original error wins */ }
      rethrow;
    }
  }

  @override
  Future<void> eraseAllUserData() async {
    // Preferences writes are not atomic. Remove each known user-data key;
    // if any operation fails, propagate the error instead of claiming success.
    await _prefs.remove(_entriesKey);
    await _prefs.remove(_budgetsKey);
    await _prefs.remove(_darkKey);
  }

  Future<void> _writeSnapshot(FinanceSnapshot value) async {
    await _prefs.setString(_entriesKey, jsonEncode(value.entries.map((e) => e.toJson()).toList()));
    await _prefs.setString(_budgetsKey, jsonEncode(value.budgets.map((e) => e.toJson()).toList()));
    await _prefs.setBool(_darkKey, value.darkMode);
  }
}

class SqliteFinanceStorage implements FinanceStorage {
  final SharedPreferencesAsync _legacy = SharedPreferencesAsync();
  Database? _db;

  @override
  String get description => 'SQLite on this device (unencrypted database)';

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'spendwise_v2.db');
    final db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
          type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
          category TEXT NOT NULL,
          date_iso TEXT NOT NULL,
          note TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE budgets (
          category TEXT PRIMARY KEY,
          amount_cents INTEGER NOT NULL CHECK(amount_cents > 0)
        )
      ''');
      await db.execute('CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      await db.execute('CREATE INDEX idx_transactions_date ON transactions(date_iso)');
    });
    try {
      await _migrateLegacyIfNeeded(db);
      _db = db;
      return db;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  Future<void> _migrateLegacyIfNeeded(Database db) async {
    final existing = await db.query('metadata', columns: ['value'],
        where: 'key = ?', whereArgs: ['legacy_import_v1'], limit: 1);
    if (existing.isNotEmpty) return;

    // Parse AND validate before opening the SQL transaction. Errors leave
    // the original preference keys and SQLite data untouched.
    final previous = await _readLegacy(_legacy);
    await db.transaction((txn) async {
      final tCount = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT COUNT(*) FROM transactions')) ?? 0;
      final bCount = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT COUNT(*) FROM budgets')) ?? 0;
      if (tCount == 0 && bCount == 0) {
        for (final entry in previous.entries) {
          await txn.insert('transactions', _entryMap(entry));
        }
        for (final budget in previous.budgets) {
          await txn.insert('budgets', _budgetMap(budget));
        }
        await txn.insert('metadata', {'key': 'dark_mode', 'value': previous.darkMode ? '1' : '0'},
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      // No import when DB already has records: prevents overwriting changes.
      await txn.insert('metadata', {'key': 'legacy_import_v1', 'value': 'complete'},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    // Intentionally do NOT delete the v1 SharedPreferences keys.
  }

  Map<String, Object?> _entryMap(MoneyTransaction e) => {
        'id': e.id,
        'title': e.title,
        'amount_cents': FinanceSnapshot.cents(e.amount),
        'type': e.type.name,
        'category': e.category,
        'date_iso': e.date.toIso8601String(),
        'note': e.note,
      };

  Map<String, Object?> _budgetMap(BudgetLimit e) => {
        'category': e.category,
        'amount_cents': FinanceSnapshot.cents(e.amount),
      };

  @override
  Future<FinanceSnapshot> load() async {
    final db = await _open();
    final integrity = await db.rawQuery('PRAGMA quick_check');
    if (integrity.isEmpty || integrity.first.values.first != 'ok') {
      throw StateError('SQLite integrity check failed. Restore from a verified backup.');
    }
    final rows = await db.query('transactions');
    final limits = await db.query('budgets');
    final modeRow = await db.query('metadata', where: 'key = ?',
        whereArgs: ['dark_mode'], limit: 1);
    return FinanceSnapshot(
      entries: rows.map((r) => MoneyTransaction(
        id: r['id'] as String,
        title: r['title'] as String,
        amount: (r['amount_cents'] as int) / 100,
        type: r['type'] == 'income' ? EntryType.income : EntryType.expense,
        category: r['category'] as String,
        date: DateTime.parse(r['date_iso'] as String),
        note: r['note'] as String,
      )).toList(),
      budgets: limits.map((r) => BudgetLimit(
        category: r['category'] as String,
        amount: (r['amount_cents'] as int) / 100,
      )).toList(),
      darkMode: modeRow.isNotEmpty && modeRow.first['value'] == '1',
    );
  }

  @override
  Future<void> upsertEntry(MoneyTransaction entry) async {
    final db = await _open();
    await db.insert('transactions', _entryMap(entry),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteEntry(String id) async {
    final db = await _open();
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> upsertBudget(BudgetLimit budget) async {
    final db = await _open();
    await db.insert('budgets', _budgetMap(budget),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteBudget(String category) async {
    final db = await _open();
    await db.delete('budgets', where: 'category = ?', whereArgs: [category]);
  }

  @override
  Future<void> saveDarkMode(bool value) async {
    final db = await _open();
    await db.insert('metadata', {'key': 'dark_mode', 'value': value ? '1' : '0'},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> replaceAll(FinanceSnapshot snapshot) async {
    snapshot.validate();
    final db = await _open();
    // Commit all-or-nothing: either the old records stay, or the entire new
    // dataset is installed. This never touches original v1 preference keys.
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('budgets');
      for (final entry in snapshot.entries) {
        await txn.insert('transactions', _entryMap(entry));
      }
      for (final budget in snapshot.budgets) {
        await txn.insert('budgets', _budgetMap(budget));
      }
      await txn.insert('metadata',
          {'key': 'dark_mode', 'value': snapshot.darkMode ? '1' : '0'},
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('metadata',
          {'key': 'legacy_import_v1', 'value': 'complete'},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> eraseAllUserData() async {
    final db = await _open();
    // One SQLite transaction clears the active data and leaves a migration
    // marker, preventing stale preferences from being imported again.
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('budgets');
      await txn.delete('metadata');
      await txn.insert('metadata', {
        'key': 'legacy_import_v1',
        'value': 'complete',
      });
    });

    // Remove old pre-SQLite copies as well. If one removal fails, an error is
    // reported and AppStore will refresh its visible state from SQLite.
    await _legacy.remove(_entriesKey);
    await _legacy.remove(_budgetsKey);
    await _legacy.remove(_darkKey);
  }

}
