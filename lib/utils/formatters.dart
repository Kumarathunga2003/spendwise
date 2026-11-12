import '../models/money_transaction.dart';

String money(num value) {
  final number = value.abs().toStringAsFixed(2).split('.');
  final digits = number[0];
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final sign = value < 0 ? '-' : '';
  return '${sign}Rs. $grouped.${number[1]}';
}

String shortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

const monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String monthLabel(DateTime date) =>
    '${monthNames[date.month - 1]} ${date.year}';

bool sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

String csvEscape(Object? value) {
  final raw = value?.toString() ?? '';
  final escaped = raw.replaceAll('"', '""');
  return '"$escaped"';
}

String transactionsCsv(Iterable<MoneyTransaction> entries) {
  final lines = <String>['Date,Type,Category,Title,Amount (LKR),Note'];
  for (final entry in entries) {
    lines.add([
      shortDate(entry.date),
      entry.type.name,
      entry.category,
      entry.title,
      entry.amount.toStringAsFixed(2),
      entry.note,
    ].map(csvEscape).join(','));
  }
  return lines.join('\r\n');
}
