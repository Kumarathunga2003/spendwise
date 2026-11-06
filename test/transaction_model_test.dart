import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/models/money_transaction.dart';
import 'package:spendwise/utils/formatters.dart';

void main() {
  test('transaction survives JSON serialization', () {
    final transaction = MoneyTransaction(
      id: 'sample',
      title: 'Lunch',
      amount: 450.5,
      type: EntryType.expense,
      category: 'Food',
      date: DateTime(2026, 11, 4),
      note: 'School',
    );
    final restored = MoneyTransaction.fromJson(transaction.toJson());
    expect(restored.id, transaction.id);
    expect(restored.title, 'Lunch');
    expect(restored.amount, 450.5);
    expect(restored.date, DateTime(2026, 11, 4));
    expect(restored.type, EntryType.expense);
  });

  test('money formats negative balances', () {
    expect(money(-1200.5), '-Rs. 1,200.50');
    expect(money(5000), 'Rs. 5,000.00');
  });

  test('CSV escapes quotes and commas', () {
    expect(csvEscape('Food, "Lunch"'), '"Food, ""Lunch"""');
  });
}
