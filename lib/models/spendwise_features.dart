import 'dart:math' as math;

import 'money_transaction.dart';

const defaultWalletId = 'wallet-cash';

String freshFeatureId() => DateTime.now().microsecondsSinceEpoch.toString();

int amountInCents(double amount) {
  if (!amount.isFinite ||
      amount < 0 ||
      amount > 1000000000000 ||
      ((amount * 100) - (amount * 100).round()).abs() > 0.00001) {
    throw const FormatException(
        'Invalid money amount. Use up to two decimal places.');
  }
  return (amount * 100).round();
}

class Wallet {
  final String id;
  final String name;
  final int openingCents;
  final String kind;
  const Wallet(
      {required this.id,
      required this.name,
      required this.openingCents,
      this.kind = 'cash'});

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'opening_cents': openingCents, 'kind': kind};
  factory Wallet.fromJson(Map<String, dynamic> d) => Wallet(
      id: d['id'] as String,
      name: d['name'] as String,
      openingCents: d['opening_cents'] as int,
      kind: d['kind'] as String? ?? 'cash');
}

class SavingsGoal {
  final String id;
  final String title;
  final int targetCents;
  final int savedCents;
  final DateTime? targetDate;
  const SavingsGoal(
      {required this.id,
      required this.title,
      required this.targetCents,
      required this.savedCents,
      this.targetDate});
  double get progress =>
      targetCents == 0 ? 0 : math.min(1, savedCents / targetCents);
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'target_cents': targetCents,
        'saved_cents': savedCents,
        'target_date': targetDate?.toIso8601String()
      };
  factory SavingsGoal.fromJson(Map<String, dynamic> d) => SavingsGoal(
      id: d['id'] as String,
      title: d['title'] as String,
      targetCents: d['target_cents'] as int,
      savedCents: d['saved_cents'] as int,
      targetDate: d['target_date'] == null
          ? null
          : DateTime.parse(d['target_date'] as String));
  SavingsGoal copyWith({int? savedCents}) => SavingsGoal(
      id: id,
      title: title,
      targetCents: targetCents,
      savedCents: savedCents ?? this.savedCents,
      targetDate: targetDate);
}

enum RepeatInterval { daily, weekly, monthly }

class RecurringRule {
  final String id;
  final String title;
  final int amountCents;
  final EntryType type;
  final String category;
  final String walletId;
  final RepeatInterval interval;
  final DateTime nextDate;
  final bool enabled;
  const RecurringRule(
      {required this.id,
      required this.title,
      required this.amountCents,
      required this.type,
      required this.category,
      required this.walletId,
      required this.interval,
      required this.nextDate,
      this.enabled = true});
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount_cents': amountCents,
        'type': type.name,
        'category': category,
        'wallet_id': walletId,
        'interval': interval.name,
        'next_date': nextDate.toIso8601String(),
        'enabled': enabled
      };
  factory RecurringRule.fromJson(Map<String, dynamic> d) => RecurringRule(
      id: d['id'] as String,
      title: d['title'] as String,
      amountCents: d['amount_cents'] as int,
      type: d['type'] == 'income' ? EntryType.income : EntryType.expense,
      category: d['category'] as String,
      walletId: d['wallet_id'] as String? ?? defaultWalletId,
      interval: RepeatInterval.values.byName(d['interval'] as String),
      nextDate: DateTime.parse(d['next_date'] as String),
      enabled: d['enabled'] as bool? ?? true);
  RecurringRule withNextDate(DateTime date) => RecurringRule(
      id: id,
      title: title,
      amountCents: amountCents,
      type: type,
      category: category,
      walletId: walletId,
      interval: interval,
      nextDate: date,
      enabled: enabled);
}

DateTime advanceRecurring(RecurringRule rule, DateTime from) {
  switch (rule.interval) {
    case RepeatInterval.daily:
      return DateTime(from.year, from.month, from.day + 1);
    case RepeatInterval.weekly:
      return DateTime(from.year, from.month, from.day + 7);
    case RepeatInterval.monthly:
      final month = from.month == 12 ? 1 : from.month + 1;
      final year = from.month == 12 ? from.year + 1 : from.year;
      final last = DateTime(year, month + 1, 0).day;
      return DateTime(year, month, math.min(from.day, last));
  }
}

class ExpenseReminder {
  final String id;
  final String title;
  final DateTime when;
  final bool enabled;
  const ExpenseReminder(
      {required this.id,
      required this.title,
      required this.when,
      this.enabled = true});
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'when': when.toIso8601String(),
        'enabled': enabled
      };
  factory ExpenseReminder.fromJson(Map<String, dynamic> d) => ExpenseReminder(
      id: d['id'] as String,
      title: d['title'] as String,
      when: DateTime.parse(d['when'] as String),
      enabled: d['enabled'] as bool? ?? true);
}

class FeatureData {
  final List<Wallet> wallets;
  final List<SavingsGoal> goals;
  final List<RecurringRule> recurring;
  final List<ExpenseReminder> reminders;
  const FeatureData(
      {required this.wallets,
      required this.goals,
      required this.recurring,
      required this.reminders});
  factory FeatureData.empty() => const FeatureData(
      wallets: [Wallet(id: defaultWalletId, name: 'Cash', openingCents: 0)],
      goals: [],
      recurring: [],
      reminders: []);
  Map<String, dynamic> toJson() => {
        'schema': 1,
        'wallets': wallets.map((e) => e.toJson()).toList(),
        'goals': goals.map((e) => e.toJson()).toList(),
        'recurring': recurring.map((e) => e.toJson()).toList(),
        'reminders': reminders.map((e) => e.toJson()).toList(),
      };
  factory FeatureData.fromJson(Map<String, dynamic>? d) {
    if (d == null || d.isEmpty) return FeatureData.empty();
    if (d['schema'] != 1) {
      throw const FormatException('Unsupported advanced feature schema.');
    }
    List<T> read<T>(String name, T Function(Map<String, dynamic>) convert) {
      final raw = d[name];
      if (raw is! List) throw FormatException('Invalid $name');
      return raw.map((e) {
        if (e is! Map) throw FormatException('Invalid $name item');
        return convert(Map<String, dynamic>.from(e));
      }).toList();
    }

    final data = FeatureData(
        wallets: read('wallets', Wallet.fromJson),
        goals: read('goals', SavingsGoal.fromJson),
        recurring: read('recurring', RecurringRule.fromJson),
        reminders: read('reminders', ExpenseReminder.fromJson));
    data.validate();
    return data;
  }
  FeatureData copyWith(
          {List<Wallet>? wallets,
          List<SavingsGoal>? goals,
          List<RecurringRule>? recurring,
          List<ExpenseReminder>? reminders}) =>
      FeatureData(
          wallets: wallets ?? this.wallets,
          goals: goals ?? this.goals,
          recurring: recurring ?? this.recurring,
          reminders: reminders ?? this.reminders);
  void validate() {
    if (wallets.isEmpty ||
        wallets.length > 100 ||
        goals.length > 2000 ||
        recurring.length > 2000 ||
        reminders.length > 2000) {
      throw const FormatException('Too many or missing feature records.');
    }
    if (!wallets.any((w) => w.id == defaultWalletId)) {
      throw const FormatException('Default wallet is missing.');
    }
    final walletIds = <String>{};
    for (final w in wallets) {
      if (w.id.isEmpty ||
          w.name.trim().isEmpty ||
          w.name.length > 80 ||
          !walletIds.add(w.id) ||
          w.openingCents.abs() > 100000000000000) {
        throw const FormatException('Invalid wallet.');
      }
    }
    final goalIds = <String>{};
    for (final g in goals) {
      if (g.id.isEmpty ||
          !goalIds.add(g.id) ||
          g.title.trim().isEmpty ||
          g.title.length > 100 ||
          g.targetCents <= 0 ||
          g.savedCents < 0 ||
          g.targetCents > 100000000000000 ||
          g.savedCents > 100000000000000) {
        throw const FormatException('Invalid savings goal.');
      }
    }
    final ruleIds = <String>{};
    for (final r in recurring) {
      if (!ruleIds.add(r.id) ||
          r.title.trim().isEmpty ||
          r.title.length > 100 ||
          r.amountCents <= 0 ||
          r.amountCents > 100000000000000 ||
          !walletIds.contains(r.walletId) ||
          r.nextDate.year < 2000 ||
          r.nextDate.year > 2200) {
        throw const FormatException('Invalid recurring rule.');
      }
    }
    final reminderIds = <String>{};
    for (final r in reminders) {
      if (!reminderIds.add(r.id) ||
          r.title.trim().isEmpty ||
          r.title.length > 100 ||
          r.when.year < 2000 ||
          r.when.year > 2200) {
        throw const FormatException('Invalid reminder.');
      }
    }
  }

  int walletBalanceCents(String walletId, Iterable<MoneyTransaction> entries) {
    final wallet = wallets.firstWhere((w) => w.id == walletId);
    var result = wallet.openingCents;
    for (final transaction in entries) {
      if (transaction.walletId != walletId) continue;
      final cents = amountInCents(transaction.amount);
      result += transaction.type == EntryType.income ? cents : -cents;
    }
    return result;
  }
}
