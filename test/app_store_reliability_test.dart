import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/app_store.dart';
import 'package:spendwise/data/finance_snapshot.dart';
import 'package:spendwise/data/finance_storage.dart';
import 'package:spendwise/models/money_transaction.dart';
import 'package:spendwise/models/spendwise_features.dart';

class FakeFinanceStorage implements FinanceStorage {
  FinanceSnapshot snapshot =
      FinanceSnapshot(entries: [], budgets: [], darkMode: false);
  bool failNextWrite = false;

  @override
  String get description => 'Fake store';
  @override
  Future<FinanceSnapshot> load() async => snapshot;

  void _check() {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('disk failure');
    }
  }

  @override
  Future<void> upsertEntry(MoneyTransaction entry) async {
    _check();
    final entries = [...snapshot.entries]..removeWhere((e) => e.id == entry.id);
    entries.add(entry);
    snapshot = FinanceSnapshot(
        entries: entries,
        budgets: snapshot.budgets,
        darkMode: snapshot.darkMode,
        features: snapshot.features);
  }

  @override
  Future<void> deleteEntry(String id) async {
    _check();
    snapshot = FinanceSnapshot(
        entries: [...snapshot.entries]..removeWhere((e) => e.id == id),
        budgets: snapshot.budgets,
        darkMode: snapshot.darkMode,
        features: snapshot.features);
  }

  @override
  Future<void> upsertBudget(BudgetLimit budget) async {
    _check();
    final budgets = [...snapshot.budgets]
      ..removeWhere((e) => e.category == budget.category);
    budgets.add(budget);
    snapshot = FinanceSnapshot(
        entries: snapshot.entries,
        budgets: budgets,
        darkMode: snapshot.darkMode,
        features: snapshot.features);
  }

  @override
  Future<void> deleteBudget(String category) async {
    _check();
    snapshot = FinanceSnapshot(
        entries: snapshot.entries,
        budgets: [...snapshot.budgets]
          ..removeWhere((e) => e.category == category),
        darkMode: snapshot.darkMode,
        features: snapshot.features);
  }

  @override
  Future<void> saveDarkMode(bool mode) async {
    _check();
    snapshot = FinanceSnapshot(
        entries: snapshot.entries,
        budgets: snapshot.budgets,
        darkMode: mode,
        features: snapshot.features);
  }

  @override
  Future<void> saveFeatures(FeatureData value) async {
    _check();
    snapshot = FinanceSnapshot(
        entries: snapshot.entries,
        budgets: snapshot.budgets,
        darkMode: snapshot.darkMode,
        features: value);
  }

  @override
  Future<void> eraseAllUserData() async {
    _check();
    snapshot = FinanceSnapshot(entries: [], budgets: [], darkMode: false);
  }

  @override
  Future<void> replaceAll(FinanceSnapshot value) async {
    _check();
    snapshot = value;
  }
}

void main() {
  test('Save, edit, budget, and reload preserve state', () async {
    final storage = FakeFinanceStorage();
    final store = AppStore(storage: storage);
    await store.load();
    await store.saveEntry(MoneyTransaction(
        id: '1',
        title: 'Pay',
        amount: 1250.50,
        type: EntryType.income,
        category: 'Salary',
        date: DateTime(2026, 11, 5)));
    await store.setBudget('Food', 5000);
    await store.setDarkMode(true);
    final reopened = AppStore(storage: storage);
    await reopened.load();
    expect(reopened.totalIncome, 1250.50);
    expect(reopened.budgetFor('Food'), 5000);
    expect(reopened.darkMode, isTrue);
  });

  test('Failed write does not alter visible transaction list', () async {
    final storage = FakeFinanceStorage();
    final store = AppStore(storage: storage);
    await store.load();
    storage.failNextWrite = true;
    await expectLater(
        store.saveEntry(MoneyTransaction(
            id: 'failed',
            title: 'Failed',
            amount: 12.00,
            type: EntryType.expense,
            category: 'Food',
            date: DateTime(2026, 11, 5))),
        throwsStateError);
    expect(store.entries, isEmpty);
    expect(storage.snapshot.entries, isEmpty);
  });

  test('Restore replaces data after committing to storage', () async {
    final storage = FakeFinanceStorage();
    final store = AppStore(storage: storage);
    await store.load();
    final snapshot = FinanceSnapshot(
        entries: [],
        budgets: [const BudgetLimit(category: 'Education', amount: 2300)],
        darkMode: true);
    await store.restoreSnapshot(snapshot);
    expect(store.budgetFor('Education'), 2300);
    expect(storage.snapshot.darkMode, isTrue);
  });

  test('Deleting all data clears entries, budgets and preference', () async {
    final storage = FakeFinanceStorage();
    final store = AppStore(storage: storage);
    await store.load();
    await store.saveEntry(MoneyTransaction(
      id: 'test-1',
      title: 'Sample',
      amount: 45.00,
      type: EntryType.expense,
      category: 'Food',
      date: DateTime(2026, 11, 7),
    ));
    await store.setBudget('Food', 500);
    await store.setDarkMode(true);

    await store.deleteAllData();
    expect(store.entries, isEmpty);
    expect(store.budgets, isEmpty);
    expect(store.darkMode, false);

    final restarted = AppStore(storage: storage);
    await restarted.load();
    expect(restarted.entries, isEmpty);
    expect(restarted.budgets, isEmpty);
    expect(restarted.darkMode, false);
  });

  test('Failed deletion does not claim success or clear visible records',
      () async {
    final storage = FakeFinanceStorage();
    final store = AppStore(storage: storage);
    await store.load();
    await store.saveEntry(MoneyTransaction(
      id: 'test-2',
      title: 'Saved',
      amount: 20.00,
      type: EntryType.income,
      category: 'Salary',
      date: DateTime(2026, 11, 7),
    ));
    storage.failNextWrite = true;
    await expectLater(store.deleteAllData(), throwsStateError);
    expect(store.entries.length, 1);
    expect(storage.snapshot.entries.length, 1);
  });
}
