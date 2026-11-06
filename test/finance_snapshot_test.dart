import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/finance_snapshot.dart';
import 'package:spendwise/models/money_transaction.dart';

void main() {
  final salary = MoneyTransaction(
    id: 'salary-1',
    title: 'Salary',
    amount: 50000.00,
    type: EntryType.income,
    category: 'Salary',
    date: DateTime(2026, 11, 5),
  );

  test('Snapshot validation and roundtrip retain transaction/budget/theme', () {
    final original = FinanceSnapshot(
      entries: [salary],
      budgets: [const BudgetLimit(category: 'Food', amount: 5000)],
      darkMode: true,
    );
    final restored = FinanceSnapshot.fromJson(original.toJson());
    expect(restored.entries.single.id, 'salary-1');
    expect(restored.entries.single.amount, 50000);
    expect(restored.budgets.single.amount, 5000);
    expect(restored.darkMode, isTrue);
  });

  test('Rejects duplicate transaction IDs', () {
    expect(() => FinanceSnapshot(
      entries: [salary, salary], budgets: [], darkMode: false),
      throwsFormatException);
  });

  test('Rejects fractional cents and invalid amounts', () {
    expect(() => FinanceSnapshot.cents(1.001), throwsFormatException);
    expect(() => FinanceSnapshot.cents(-2), throwsFormatException);
    expect(FinanceSnapshot.cents(19.99), 1999);
  });

  test('Rejects malformed backup data', () {
    expect(() => FinanceSnapshot.fromJson({
      'schema_version': 4, 'entries': [], 'budgets': [], 'dark_mode': true,
    }), throwsFormatException);
  });
}
