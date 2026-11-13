import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/backup_crypto.dart';
import 'package:spendwise/data/finance_snapshot.dart';
import 'package:spendwise/models/money_transaction.dart';

void main() {
  final snapshot = FinanceSnapshot(
    entries: [
      MoneyTransaction(
        id: '1',
        title: 'Food',
        amount: 100.25,
        type: EntryType.expense,
        category: 'Food',
        date: DateTime(2026, 11, 5),
      )
    ],
    budgets: [const BudgetLimit(category: 'Food', amount: 5000)],
    darkMode: true,
  );

  test('Encrypted file roundtrip restores all data', () async {
    final file =
        await BackupCrypto.encrypt(snapshot, 'a-long-backup-passphrase!');
    final restored =
        await BackupCrypto.decrypt(file, 'a-long-backup-passphrase!');
    expect(restored.entries.single.amount, 100.25);
    expect(restored.budgets.single.category, 'Food');
    expect(restored.darkMode, isTrue);
  });

  test('Wrong passphrase fails before any storage change', () async {
    final file =
        await BackupCrypto.encrypt(snapshot, 'a-long-backup-passphrase!');
    await expectLater(BackupCrypto.decrypt(file, 'different-long-passphrase!'),
        throwsFormatException);
  });

  test('Tampering is detected by authenticated encryption', () async {
    final file =
        await BackupCrypto.encrypt(snapshot, 'a-long-backup-passphrase!');
    final tampered = Uint8List.fromList(file);
    tampered[tampered.length - 20] ^= 1;
    await expectLater(
        BackupCrypto.decrypt(tampered, 'a-long-backup-passphrase!'),
        throwsFormatException);
  });
}
