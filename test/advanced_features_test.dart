import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/backup_crypto.dart';
import 'package:spendwise/data/finance_snapshot.dart';
import 'package:spendwise/import_export/csv_import.dart';
import 'package:spendwise/models/money_transaction.dart';
import 'package:spendwise/models/spendwise_features.dart';

void main() {
  test('wallet balance uses income minus expense and an opening balance', () {
    final f = FeatureData.empty().copyWith(wallets: [
      const Wallet(id: defaultWalletId, name: 'Cash', openingCents: 20000),
      const Wallet(id: 'bank', name: 'Bank', openingCents: 50000),
    ]);
    final rows = [
      MoneyTransaction(
          id: 'a',
          title: 'Pay',
          amount: 100.25,
          type: EntryType.income,
          category: 'Salary',
          date: DateTime(2026),
          walletId: 'bank'),
      MoneyTransaction(
          id: 'b',
          title: 'Food',
          amount: 30,
          type: EntryType.expense,
          category: 'Food',
          date: DateTime(2026),
          walletId: 'bank'),
    ];
    expect(f.walletBalanceCents('bank', rows), 57025);
    expect(f.walletBalanceCents(defaultWalletId, rows), 20000);
  });
  test('recurring dates advance daily, weekly and across short months', () {
    RecurringRule make(RepeatInterval interval) => RecurringRule(
        id: 'r',
        title: 'Monthly bill',
        amountCents: 1000,
        type: EntryType.expense,
        category: 'Bills',
        walletId: defaultWalletId,
        interval: interval,
        nextDate: DateTime(2027, 1, 31));
    expect(advanceRecurring(make(RepeatInterval.daily), DateTime(2027, 1, 31)),
        DateTime(2027, 2, 1));
    expect(advanceRecurring(make(RepeatInterval.weekly), DateTime(2027, 1, 31)),
        DateTime(2027, 2, 7));
    expect(
        advanceRecurring(make(RepeatInterval.monthly), DateTime(2027, 1, 31)),
        DateTime(2027, 2, 28));
  });
  test('backup roundtrip preserves wallets, goals and transaction wallet IDs',
      () async {
    final features = FeatureData.empty().copyWith(
      wallets: [
        const Wallet(id: defaultWalletId, name: 'Cash', openingCents: 0),
        const Wallet(id: 'bank', name: 'Bank', openingCents: 100)
      ],
      goals: [
        const SavingsGoal(
            id: 'g', title: 'Laptop', targetCents: 100000, savedCents: 2000)
      ],
    );
    final snapshot = FinanceSnapshot(entries: [
      MoneyTransaction(
          id: 'a',
          title: 'Pay',
          amount: 20,
          type: EntryType.income,
          category: 'Salary',
          date: DateTime(2026),
          walletId: 'bank')
    ], budgets: [], darkMode: true, features: features);
    final binary =
        await BackupCrypto.encrypt(snapshot, 'a very strong password 123');
    final result =
        await BackupCrypto.decrypt(binary, 'a very strong password 123');
    expect(result.entries.single.walletId, 'bank');
    expect(result.features.goals.single.savedCents, 2000);
    expect(result.features.wallets.length, 2);
  });
  test('invalid and duplicate wallet IDs are rejected', () {
    expect(
        () => FeatureData.empty().copyWith(wallets: const [
              Wallet(id: defaultWalletId, name: 'Cash', openingCents: 0),
              Wallet(id: defaultWalletId, name: 'Other', openingCents: 0),
            ]).validate(),
        throwsFormatException);
  });
  test('CSV parses quoted commas, escaped quotes and line breaks', () {
    final csv = 'Date,Type,Category,Title,Amount (LKR),Note\r\n'
        '01/11/2026,expense,Food,"Dinner, cafe",125.50,"A ""special"" night\nand dessert"\r\n';
    final result = previewSpendWiseCsv(Uint8List.fromList(utf8.encode(csv)));
    expect(result.problems, isEmpty);
    expect(result.entries.single.title, 'Dinner, cafe');
    expect(result.entries.single.note, 'A "special" night\nand dessert');
  });
  test('CSV rejects invalid dates before committing anything', () {
    final csv = 'Date,Type,Category,Title,Amount (LKR),Note\n'
        '31/02/2026,expense,Food,Wrong,100.00,\n';
    final result = previewSpendWiseCsv(Uint8List.fromList(utf8.encode(csv)));
    expect(result.entries, isEmpty);
    expect(result.problems, isNotEmpty);
  });
}
