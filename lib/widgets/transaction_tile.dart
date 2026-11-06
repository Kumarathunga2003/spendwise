import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/money_transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'spend_ui.dart';
import 'transaction_form.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.entry,
    required this.store, this.editable = false});
  final MoneyTransaction entry;
  final AppStore store;
  final bool editable;

  Future<void> _delete(BuildContext context) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text('Delete "${entry.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete')),
        ],
      ),
    );
    if (approved != true || !context.mounted) return;
    try {
      await store.deleteEntry(entry.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete transaction')));
      }
    }
  }

  Future<void> _details(BuildContext context) async {
    final income = entry.type == EntryType.income;
    final color = income ? SpendColors.green : SpendColors.orange;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: SpendIconBadge(icon: categoryIcon(entry.category),
              color: color, size: 58)),
            const SizedBox(height: 12),
            Text(entry.title, textAlign: TextAlign.center,
              style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 7),
            Text('${income ? '+' : '-'}${money(entry.amount)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800,
                color: color)),
            const SizedBox(height: 18),
            _DetailRow(label: 'Type', value: income ? 'Income' : 'Expense'),
            _DetailRow(label: 'Category', value: entry.category),
            _DetailRow(label: 'Date', value: shortDate(entry.date)),
            if (entry.note.trim().isNotEmpty)
              _DetailRow(label: 'Note', value: entry.note.trim()),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: () {
              Navigator.pop(sheetContext);
              openTransactionEditor(context, store, existing: entry);
            }, icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit transaction')),
            const SizedBox(height: 7),
            TextButton.icon(onPressed: () {
              Navigator.pop(sheetContext);
              _delete(context);
            }, icon: const Icon(Icons.delete_outline),
              label: const Text('Delete transaction')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final income = entry.type == EntryType.income;
    final color = income ? SpendColors.green : SpendColors.orange;
    return Card(child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _details(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        child: Row(children: [
          SpendIconBadge(icon: categoryIcon(entry.category), color: color),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${entry.category} · ${shortDate(entry.date)}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
            ],
          )),
          const SizedBox(width: 8),
          Flexible(child: Text('${income ? '+' : '-'}${money(entry.amount)}',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
              color: color))),
          if (editable)
            PopupMenuButton<String>(
              tooltip: 'Transaction actions',
              icon: const Icon(Icons.more_vert_rounded, size: 21),
              onSelected: (choice) {
                if (choice == 'edit') {
                  openTransactionEditor(context, store, existing: entry);
                } else if (choice == 'delete') {
                  _delete(context);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ]),
      ),
    ));
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90, child: Text(label,
        style: Theme.of(context).textTheme.bodySmall)),
      Expanded(child: Text(value, textAlign: TextAlign.right,
        style: const TextStyle(fontWeight: FontWeight.w700))),
    ]),
  );
}
