import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/money_transaction.dart';
import '../models/spendwise_features.dart';
import '../utils/formatters.dart';
import 'backup_crypto.dart';
import 'finance_snapshot.dart';
import 'finance_storage.dart';

/// The existing SpendWise UI can keep using the same AppStore API.
/// Writes complete on disk before in-memory UI state is changed.
class AppStore extends ChangeNotifier {
  final FinanceStorage _storage;
  AppStore({FinanceStorage? storage})
      : _storage = storage ?? createFinanceStorage();

  List<MoneyTransaction> _entries = [];
  List<BudgetLimit> _budgets = [];
  FeatureData _features = FeatureData.empty();
  bool _ready = false;
  String? _loadError;
  bool _darkMode = false;
  Future<void> _previousWrite = Future<void>.value();

  bool get ready => _ready;
  String? get loadError => _loadError;
  bool get darkMode => _darkMode;
  String get storageDescription => _storage.description;

  List<MoneyTransaction> get entries {
    final copy = List<MoneyTransaction>.of(_entries);
    copy.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    });
    return List.unmodifiable(copy);
  }

  List<BudgetLimit> get budgets => List.unmodifiable(_budgets);
  FeatureData get features => _features;

  double get totalIncome => _sum(_entries, EntryType.income);
  double get totalExpense => _sum(_entries, EntryType.expense);
  double get balance =>
      totalIncome -
      totalExpense +
      _features.wallets.fold<int>(0, (sum, w) => sum + w.openingCents) / 100;

  // Integer minor-unit aggregation avoids floating-point rounding drift.
  static double _sum(Iterable<MoneyTransaction> values, EntryType type) =>
      values.where((e) => e.type == type).fold<int>(
          0, (total, entry) => total + FinanceSnapshot.cents(entry.amount)) /
      100;

  Iterable<MoneyTransaction> entriesInMonth(DateTime month) =>
      _entries.where((entry) => sameMonth(entry.date, month));

  double incomeForMonth(DateTime month) =>
      _sum(entriesInMonth(month), EntryType.income);

  double expensesForMonth(DateTime month) =>
      _sum(entriesInMonth(month), EntryType.expense);

  double spendingForCategory(String category, DateTime month) =>
      entriesInMonth(month)
          .where((e) => e.type == EntryType.expense && e.category == category)
          .fold<int>(0, (sum, e) => sum + FinanceSnapshot.cents(e.amount)) /
      100;

  double? budgetFor(String category) {
    for (final budget in _budgets) {
      if (budget.category == category) return budget.amount;
    }
    return null;
  }

  FinanceSnapshot get currentSnapshot => FinanceSnapshot(
        entries: _entries,
        budgets: _budgets,
        darkMode: _darkMode,
        features: _features,
      );

  Future<void> load() async {
    try {
      final snapshot = await _storage.load();
      _setState(snapshot);
      // Generate due rules as an atomic database update before showing the UI.
      await _postDueRecurringRules();
      _loadError = null;
    } catch (_) {
      // Fail closed: NEVER replace saved data with an empty list on errors.
      _loadError = 'Could not safely load SpendWise data. Do not uninstall '
          'or clear app storage. Keep your previous backup and check the log.';
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  void _setState(FinanceSnapshot value) {
    _entries = List<MoneyTransaction>.of(value.entries);
    _budgets = List<BudgetLimit>.of(value.budgets);
    _darkMode = value.darkMode;
    _features = value.features;
  }

  void _assertCanWrite() {
    if (!_ready || _loadError != null) {
      throw StateError('Saved data is not ready.');
    }
  }

  // Serializes writes, avoiding races between rapid edits/deletes/restores.
  Future<void> _exclusive(Future<void> Function() action) async {
    final previous = _previousWrite;
    final done = Completer<void>();
    _previousWrite = done.future;
    await previous;
    try {
      _assertCanWrite();
      await action();
    } finally {
      done.complete();
    }
  }

  Future<void> saveEntry(MoneyTransaction entry) => _exclusive(() async {
        final next = [..._entries]..removeWhere((e) => e.id == entry.id);
        next.add(entry);
        FinanceSnapshot(
            entries: next,
            budgets: _budgets,
            darkMode: _darkMode,
            features: _features);
        await _storage.upsertEntry(entry);
        _entries = next;
        notifyListeners();
      });

  Future<void> deleteEntry(String id) => _exclusive(() async {
        await _storage.deleteEntry(id);
        _entries.removeWhere((e) => e.id == id);
        notifyListeners();
      });

  Future<void> setBudget(String category, double amount) =>
      _exclusive(() async {
        final budget = BudgetLimit(category: category, amount: amount);
        final next = [..._budgets]..removeWhere((b) => b.category == category);
        next.add(budget);
        FinanceSnapshot(
            entries: _entries,
            budgets: next,
            darkMode: _darkMode,
            features: _features);
        await _storage.upsertBudget(budget);
        _budgets = next;
        notifyListeners();
      });

  Future<void> removeBudget(String category) => _exclusive(() async {
        await _storage.deleteBudget(category);
        _budgets.removeWhere((b) => b.category == category);
        notifyListeners();
      });

  Future<void> setDarkMode(bool value) => _exclusive(() async {
        await _storage.saveDarkMode(value);
        _darkMode = value;
        notifyListeners();
      });

  Future<Uint8List> exportEncryptedBackup(String passphrase) async {
    _assertCanWrite();
    await _previousWrite;
    return BackupCrypto.encrypt(currentSnapshot, passphrase);
  }

  Future<FinanceSnapshot> previewEncryptedBackup(
          Uint8List file, String passphrase) =>
      BackupCrypto.decrypt(file, passphrase);

  Future<void> restoreSnapshot(FinanceSnapshot snapshot) =>
      _exclusive(() async {
        snapshot.validate();
        await _storage.replaceAll(snapshot);
        _setState(snapshot);
        notifyListeners();
      });

  /// Clears transactions, budgets, theme preference and pre-SQLite legacy data.
  /// External backup/CSV files are separate and not deleted here.
  Future<void> deleteAllData() => _exclusive(() async {
        try {
          await _storage.eraseAllUserData();
          _setState(FinanceSnapshot(
            entries: const [],
            budgets: const [],
            darkMode: false,
            features: FeatureData.empty(),
          ));
          notifyListeners();
        } catch (_) {
          // If deletion was partly committed (e.g. SQLite cleared, legacy
          // preferences cleanup failed), refresh the visible state to match
          // storage instead of showing old records.
          try {
            _setState(await _storage.load());
          } catch (_) {
            _loadError = 'Unable to verify saved data after deletion. '
                'Do not uninstall or clear the app until checked.';
          }
          notifyListeners();
          rethrow;
        }
      });

  /// Updates the wallet/goal/rule/reminder collection after secure persistence.
  Future<void> updateFeatures(FeatureData value) => _exclusive(() async {
        value.validate();
        final validWallets = value.wallets.map((w) => w.id).toSet();
        if (_entries.any((e) => !validWallets.contains(e.walletId))) {
          throw const FormatException(
              'This wallet still has transactions. Move them first.');
        }
        await _storage.saveFeatures(value);
        _features = value;
        notifyListeners();
      });

  Future<void> importTransactions(Iterable<MoneyTransaction> imported) =>
      _exclusive(() async {
        final existing = _entries
            .map((e) =>
                '${e.date.year}-${e.date.month}-${e.date.day}|${e.title.toLowerCase()}|'
                '${e.type.name}|${e.category.toLowerCase()}|${FinanceSnapshot.cents(e.amount)}|${e.note}')
            .toSet();
        final incoming = <MoneyTransaction>[];
        for (final e in imported) {
          final identity =
              '${e.date.year}-${e.date.month}-${e.date.day}|${e.title.toLowerCase()}|'
              '${e.type.name}|${e.category.toLowerCase()}|${FinanceSnapshot.cents(e.amount)}|${e.note}';
          if (existing.add(identity)) incoming.add(e);
        }
        if (incoming.isEmpty) return;
        final next = FinanceSnapshot(
            entries: [..._entries, ...incoming],
            budgets: _budgets,
            darkMode: _darkMode,
            features: _features);
        await _storage.replaceAll(next);
        _setState(next);
        notifyListeners();
      });

  Future<void> _postDueRecurringRules() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactions = [..._entries];
    final ids = transactions.map((e) => e.id).toSet();
    final nextRules = <RecurringRule>[];
    var changed = false;
    for (final rule in _features.recurring) {
      var current = rule;
      var count = 0;
      while (
          current.enabled && !current.nextDate.isAfter(today) && count < 36) {
        final due = current.nextDate;
        final id = 'rec-${rule.id}-${due.year}-${due.month}-${due.day}';
        if (ids.add(id)) {
          transactions.add(MoneyTransaction(
              id: id,
              title: rule.title,
              amount: rule.amountCents / 100,
              type: rule.type,
              category: rule.category,
              date: due,
              walletId: rule.walletId));
          changed = true;
        }
        current = current.withNextDate(advanceRecurring(rule, due));
        count++;
        changed = true;
      }
      nextRules.add(current);
    }
    if (!changed) return;
    final state = FinanceSnapshot(
        entries: transactions,
        budgets: _budgets,
        darkMode: _darkMode,
        features: _features.copyWith(recurring: nextRules));
    await _storage.replaceAll(state);
    _setState(state);
  }

  /// Due recurrences are generated when SpendWise opens or resumes.
  Future<void> processRecurringNow() => _exclusive(_postDueRecurringRules);
}
