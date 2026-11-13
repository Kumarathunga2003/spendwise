import 'dart:convert';
import 'dart:typed_data';

import '../models/money_transaction.dart';

class CsvPreview {
  final List<MoneyTransaction> entries;
  final List<String> problems;
  const CsvPreview(this.entries, this.problems);
}

/// Quote-aware CSV reader. Accepts SpendWise's own export format, including
/// escaped quotes, commas, CRLF and line breaks inside quoted notes.
List<List<String>> decodeCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '"') {
      if (quoted && i + 1 < text.length && text[i + 1] == '"') {
        field.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (!quoted && c == ',') {
      row.add(field.toString());
      field = StringBuffer();
    } else if (!quoted && (c == '\r' || c == '\n')) {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field = StringBuffer();
      if (row.any((s) => s.isNotEmpty)) rows.add(row);
      row = [];
    } else {
      field.write(c);
    }
  }
  if (quoted) throw const FormatException('Unclosed quote in CSV.');
  row.add(field.toString());
  if (row.any((s) => s.isNotEmpty)) rows.add(row);
  return rows;
}

CsvPreview previewSpendWiseCsv(Uint8List bytes) {
  if (bytes.length > 6 * 1024 * 1024) {
    throw const FormatException('CSV file exceeds 6 MB.');
  }
  final text =
      utf8.decode(bytes, allowMalformed: false).replaceFirst('\uFEFF', '');
  final rows = decodeCsv(text);
  if (rows.isEmpty) throw const FormatException('CSV file is empty.');
  final header = rows.first.map((s) => s.trim().toLowerCase()).toList();
  const expected = [
    'date',
    'type',
    'category',
    'title',
    'amount (lkr)',
    'note'
  ];
  if (header.length != expected.length ||
      !List.generate(expected.length, (i) => header[i] == expected[i])
          .every((e) => e)) {
    throw const FormatException(
        'Unsupported CSV columns. Export a CSV from SpendWise first.');
  }
  final entries = <MoneyTransaction>[];
  final issues = <String>[];
  for (var i = 1; i < rows.length; i++) {
    try {
      final values = rows[i];
      if (values.length != 6) {
        throw const FormatException('Incorrect column count.');
      }
      final parts = values[0].trim().split('/');
      if (parts.length != 3) {
        throw const FormatException('Expected DD/MM/YYYY date.');
      }
      final dd = int.parse(parts[0]),
          mm = int.parse(parts[1]),
          yyyy = int.parse(parts[2]);
      final date = DateTime(yyyy, mm, dd);
      if (date.day != dd || date.month != mm || date.year != yyyy) {
        throw const FormatException('Invalid date.');
      }
      final type = values[1].trim().toLowerCase();
      if (type != 'income' && type != 'expense') {
        throw const FormatException('Invalid type.');
      }
      final amount = double.parse(values[4].trim());
      if (!amount.isFinite ||
          amount <= 0 ||
          (amount * 100 - (amount * 100).round()).abs() > 0.00001) {
        throw const FormatException('Invalid amount.');
      }
      final title = values[3].trim();
      final category = values[2].trim();
      if (title.isEmpty ||
          title.length > 200 ||
          category.isEmpty ||
          category.length > 120 ||
          values[5].length > 5000) {
        throw const FormatException('Invalid text length.');
      }
      entries.add(MoneyTransaction(
          id: 'csv-${DateTime.now().microsecondsSinceEpoch}-$i',
          title: title,
          category: category,
          amount: amount,
          type: type == 'income' ? EntryType.income : EntryType.expense,
          date: date,
          note: values[5],
          walletId: 'wallet-cash'));
    } catch (e) {
      issues.add('CSV row ${i + 1}: $e');
      if (issues.length >= 20) break;
    }
  }
  if (issues.isNotEmpty) return CsvPreview([], issues);
  return CsvPreview(entries, []);
}
