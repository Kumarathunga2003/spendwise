import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as plain;
import 'package:sqflite_sqlcipher/sqflite.dart' as secret;

import '../models/money_transaction.dart';
import '../models/spendwise_features.dart';
import 'finance_snapshot.dart';
import 'finance_storage.dart';

/// Uses SQLCipher and a random key wrapped by the Android Keystore.
/// Never creates a replacement encryption key for an existing database.
class SecureSqliteFinanceStorage implements FinanceStorage {
  static const _keyName = 'spendwise.sqlcipher.key.v1';
  static const _fileName = 'spendwise_secure_v1.db';
  static const _legacyFileName = 'spendwise_v2.db';
  static const _prefsKeys = [
    'spendwise.entries.v1',
    'spendwise.budgets.v1',
    'spendwise.dark_mode.v1',
    'spendwise.features.v1',
  ];
  final FlutterSecureStorage _secrets = const FlutterSecureStorage();
  secret.Database? _database;

  @override
  String get description => 'Encrypted SQLCipher database on this device';

  Future<secret.Database> _open() async {
    if (_database != null) return _database!;
    final path = p.join(await secret.getDatabasesPath(), _fileName);
    final exists = await secret.databaseExists(path);
    var password = await _secrets.read(key: _keyName);
    if (exists && (password == null || password.isEmpty)) {
      throw StateError(
          'Encrypted database key missing. Do not reset the app. Restore from a backup.');
    }
    if (password == null) {
      final random = Random.secure();
      password =
          base64Encode(List<int>.generate(32, (_) => random.nextInt(256)));
      await _secrets.write(key: _keyName, value: password);
    }
    final db = await secret.openDatabase(
      path,
      password: password,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE transactions (
          id TEXT PRIMARY KEY, title TEXT NOT NULL,
          amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
          type TEXT NOT NULL CHECK(type IN ('income','expense')),
          category TEXT NOT NULL, date_iso TEXT NOT NULL,
          note TEXT NOT NULL, wallet_id TEXT NOT NULL
        )''');
        await db.execute('''CREATE TABLE budgets (
          category TEXT PRIMARY KEY,
          amount_cents INTEGER NOT NULL CHECK(amount_cents > 0)
        )''');
        await db.execute(
            'CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
        await db
            .execute('CREATE INDEX idx_secure_date ON transactions(date_iso)');
      },
    );
    try {
      await _migrateIfNeeded(db);
      final quick = await db.rawQuery('PRAGMA quick_check');
      if (quick.isEmpty || quick.first.values.first != 'ok') {
        throw StateError('Encrypted database integrity check failed.');
      }
      _database = db;
      return db;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  Future<void> _migrateIfNeeded(secret.Database db) async {
    final rows = await db.query('metadata',
        where: 'key = ?', whereArgs: ['migrated'], limit: 1);
    if (rows.isNotEmpty) {
      await _cleanupLegacy();
      return;
    }
    // Read the *previous* app's database (and its older preferences) without
    // deleting either. If parsing fails, the encrypted database is not marked
    // migrated, and the original remains intact.
    final oldStorage = SqliteFinanceStorage();
    final FinanceSnapshot previous;
    try {
      previous = await oldStorage.load();
      previous.validate();
    } finally {
      await oldStorage.close();
    }
    await _replace(db, previous, markMigrated: true);
    final count = secret.Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM transactions')) ??
        -1;
    final budgets = secret.Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM budgets')) ??
        -1;
    if (count != previous.entries.length ||
        budgets != previous.budgets.length) {
      throw StateError(
          'Secure migration count mismatch. Previous database preserved.');
    }
    // Delete only after verified migration. Old backups outside app are untouched.
    // Failure to remove old files is recoverable but must not be hidden from
    // release security auditing: the startup log reports it via the exception.
    await _cleanupLegacy();
  }

  Future<void> _cleanupLegacy() async {
    final oldPath = p.join(await plain.getDatabasesPath(), _legacyFileName);
    if (await plain.databaseExists(oldPath)) {
      await plain.deleteDatabase(oldPath);
    }
    final prefs = SharedPreferencesAsync();
    for (final key in _prefsKeys) {
      await prefs.remove(key);
    }
  }

  Map<String, Object?> _entry(MoneyTransaction e) => {
        'id': e.id,
        'title': e.title,
        'amount_cents': FinanceSnapshot.cents(e.amount),
        'type': e.type.name,
        'category': e.category,
        'date_iso': e.date.toIso8601String(),
        'note': e.note,
        'wallet_id': e.walletId,
      };
  Future<void> _replace(secret.Database db, FinanceSnapshot snapshot,
      {bool markMigrated = false}) async {
    snapshot.validate();
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('budgets');
      for (final e in snapshot.entries) {
        await txn.insert('transactions', _entry(e));
      }
      for (final b in snapshot.budgets) {
        await txn.insert('budgets', {
          'category': b.category,
          'amount_cents': FinanceSnapshot.cents(b.amount)
        });
      }
      await txn.insert('metadata',
          {'key': 'dark_mode', 'value': snapshot.darkMode ? '1' : '0'},
          conflictAlgorithm: secret.ConflictAlgorithm.replace);
      await txn.insert('metadata',
          {'key': 'features', 'value': jsonEncode(snapshot.features.toJson())},
          conflictAlgorithm: secret.ConflictAlgorithm.replace);
      if (markMigrated) {
        await txn.insert('metadata', {'key': 'migrated', 'value': '1'},
            conflictAlgorithm: secret.ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<FinanceSnapshot> load() async {
    final db = await _open();
    final transactions = await db.query('transactions');
    final budgets = await db.query('budgets');
    final metadata = {
      for (final r in await db.query('metadata'))
        r['key'] as String: r['value'] as String
    };
    return FinanceSnapshot(
      entries: transactions
          .map((r) => MoneyTransaction(
              id: r['id'] as String,
              title: r['title'] as String,
              amount: (r['amount_cents'] as int) / 100,
              type:
                  r['type'] == 'income' ? EntryType.income : EntryType.expense,
              category: r['category'] as String,
              date: DateTime.parse(r['date_iso'] as String),
              note: r['note'] as String,
              walletId: r['wallet_id'] as String))
          .toList(),
      budgets: budgets
          .map((r) => BudgetLimit(
              category: r['category'] as String,
              amount: (r['amount_cents'] as int) / 100))
          .toList(),
      darkMode: metadata['dark_mode'] == '1',
      features: metadata['features'] == null
          ? FeatureData.empty()
          : FeatureData.fromJson(
              jsonDecode(metadata['features']!) as Map<String, dynamic>),
    );
  }

  @override
  Future<void> upsertEntry(MoneyTransaction e) async {
    await (await _open()).insert('transactions', _entry(e),
        conflictAlgorithm: secret.ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteEntry(String id) async {
    await (await _open())
        .delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> upsertBudget(BudgetLimit b) async {
    await (await _open()).insert(
        'budgets',
        {
          'category': b.category,
          'amount_cents': FinanceSnapshot.cents(b.amount)
        },
        conflictAlgorithm: secret.ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteBudget(String category) async {
    await (await _open())
        .delete('budgets', where: 'category = ?', whereArgs: [category]);
  }

  @override
  Future<void> saveDarkMode(bool value) async {
    await (await _open()).insert(
        'metadata', {'key': 'dark_mode', 'value': value ? '1' : '0'},
        conflictAlgorithm: secret.ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveFeatures(FeatureData value) async {
    value.validate();
    await (await _open()).insert(
        'metadata', {'key': 'features', 'value': jsonEncode(value.toJson())},
        conflictAlgorithm: secret.ConflictAlgorithm.replace);
  }

  @override
  Future<void> replaceAll(FinanceSnapshot snapshot) async =>
      _replace(await _open(), snapshot);
  @override
  Future<void> eraseAllUserData() async => _replace(
      await _open(),
      FinanceSnapshot(
          entries: const [],
          budgets: const [],
          darkMode: false,
          features: FeatureData.empty()));
}
