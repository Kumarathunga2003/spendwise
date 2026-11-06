import '../models/money_transaction.dart';

/// A portable, validated representation of the entire SpendWise dataset.
/// Keep this schema version stable for encrypted backup compatibility.
class FinanceSnapshot {
  final List<MoneyTransaction> entries;
  final List<BudgetLimit> budgets;
  final bool darkMode;

  FinanceSnapshot({
    required List<MoneyTransaction> entries,
    required List<BudgetLimit> budgets,
    required this.darkMode,
  })  : entries = List.unmodifiable(entries),
        budgets = List.unmodifiable(budgets) {
    validate();
  }

  static int cents(double value) {
    if (!value.isFinite || value <= 0 || value > 1000000000000) {
      throw const FormatException('Amounts must be positive, finite and within range.');
    }
    final scaled = value * 100;
    final rounded = scaled.round();
    if ((scaled - rounded).abs() > 0.00001) {
      throw const FormatException('Amount cannot have more than 2 decimal places.');
    }
    return rounded;
  }

  void validate() {
    if (entries.length > 100000 || budgets.length > 1000) {
      throw const FormatException('Backup exceeds supported record limits.');
    }
    final ids = <String>{};
    for (final e in entries) {
      if (e.id.trim().isEmpty || e.id.length > 200 || !ids.add(e.id)) {
        throw const FormatException('Missing or duplicate transaction ID.');
      }
      if (e.title.trim().isEmpty || e.title.length > 200 ||
          e.category.trim().isEmpty || e.category.length > 120 ||
          e.note.length > 5000 || e.date.year < 1900 || e.date.year > 2200) {
        throw const FormatException('Transaction contains invalid fields.');
      }
      cents(e.amount);
    }
    final categories = <String>{};
    for (final b in budgets) {
      if (b.category.trim().isEmpty || b.category.length > 120 ||
          !categories.add(b.category)) {
        throw const FormatException('Missing or duplicate budget category.');
      }
      cents(b.amount);
    }
  }

  Map<String, dynamic> toJson() => {
        'schema_version': 1,
        'entries': entries.map((e) => e.toJson()).toList(),
        'budgets': budgets.map((e) => e.toJson()).toList(),
        'dark_mode': darkMode,
      };

  factory FinanceSnapshot.fromJson(Map<String, dynamic> data) {
    if (data['schema_version'] != 1 ||
        data['entries'] is! List ||
        data['budgets'] is! List ||
        data['dark_mode'] is! bool) {
      throw const FormatException('Unsupported or incomplete SpendWise backup.');
    }
    final entries = <MoneyTransaction>[];
    for (final record in data['entries'] as List) {
      if (record is! Map<String, dynamic> ||
          (record['type'] != 'income' && record['type'] != 'expense')) {
        throw const FormatException('Invalid transaction type or structure.');
      }
      entries.add(MoneyTransaction.fromJson(record));
    }
    final budgets = <BudgetLimit>[];
    for (final record in data['budgets'] as List) {
      if (record is! Map<String, dynamic>) {
        throw const FormatException('Invalid budget structure.');
      }
      budgets.add(BudgetLimit.fromJson(record));
    }
    return FinanceSnapshot(
      entries: entries,
      budgets: budgets,
      darkMode: data['dark_mode'] as bool,
    );
  }
}
