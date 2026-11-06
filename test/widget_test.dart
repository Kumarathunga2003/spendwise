// Starter Flutter counter-app test replaced with SpendWise-specific tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/models/money_transaction.dart';

void main() {
  test('BudgetLimit converts to and from JSON', () {
    const limit = BudgetLimit(category: 'Food', amount: 5000);
    final restored = BudgetLimit.fromJson(limit.toJson());
    expect(restored.category, 'Food');
    expect(restored.amount, 5000);
  });
}
