import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/money_transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/spend_ui.dart';
import '../widgets/transaction_form.dart';
import '../widgets/transaction_tile.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key, required this.store});
  final AppStore store;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  EntryType? _type;
  bool _currentMonthOnly = false;
  bool _newestFirst = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final entries = widget.store.entries.where((entry) {
      if (_type != null && entry.type != _type) return false;
      if (_currentMonthOnly && !sameMonth(entry.date, now)) return false;
      final query = _query.trim().toLowerCase();
      return query.isEmpty || entry.title.toLowerCase().contains(query)
          || entry.category.toLowerCase().contains(query)
          || entry.note.toLowerCase().contains(query);
    }).toList();
    entries.sort((a, b) {
      final order = a.date.compareTo(b.date);
      return _newestFirst ? -order : order;
    });
    final visibleIncome = entries.where((e) => e.type == EntryType.income)
      .fold<double>(0, (sum, e) => sum + e.amount);
    final visibleExpenses = entries.where((e) => e.type == EntryType.expense)
      .fold<double>(0, (sum, e) => sum + e.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 32),
      children: [
        SpendSectionHeader(title: 'Transaction history',
          subtitle: 'Search, review and manage your entries'),
        const SizedBox(height: 17),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () => openTransactionEditor(context, widget.store),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New transaction'),
        )),
        const SizedBox(height: 17),
        TextField(
          controller: _searchController,
          onChanged: (text) => setState(() => _query = text),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search by title, category or note',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty ? null : IconButton(
              tooltip: 'Clear search', icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(() {
                _query = '';
                _searchController.clear();
              }),
            ),
          ),
        ),
        const SizedBox(height: 13),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ChoiceChip(label: const Text('All'), selected: _type == null,
            onSelected: (_) => setState(() => _type = null)),
          ChoiceChip(label: const Text('Income'),
            selected: _type == EntryType.income,
            onSelected: (_) => setState(() => _type = EntryType.income)),
          ChoiceChip(label: const Text('Expenses'),
            selected: _type == EntryType.expense,
            onSelected: (_) => setState(() => _type = EntryType.expense)),
          FilterChip(label: const Text('This month'),
            selected: _currentMonthOnly,
            onSelected: (value) => setState(() => _currentMonthOnly = value)),
        ]),
        const SizedBox(height: 17),
        Card(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(children: [
            Expanded(child: _FilterTotal(title: 'Income', amount: visibleIncome,
              color: SpendColors.green)),
            Container(width: 1, height: 48,
              color: Theme.of(context).dividerColor),
            Expanded(child: _FilterTotal(title: 'Expenses', amount: visibleExpenses,
              color: SpendColors.orange)),
          ]),
        )),
        const SizedBox(height: 24),
        SpendSectionHeader(
          title: 'Activity',
          subtitle: '${entries.length} result${entries.length == 1 ? '' : 's'}',
          action: TextButton.icon(
            onPressed: () => setState(() => _newestFirst = !_newestFirst),
            icon: Icon(_newestFirst ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded, size: 16),
            label: Text(_newestFirst ? 'Newest' : 'Oldest'),
          ),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const SpendEmptyState(
            title: 'No matching transactions',
            message: 'Try a different search or remove a filter.',
            icon: Icons.manage_search_rounded,
          )
        else
          ...entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: TransactionTile(entry: entry, store: widget.store,
              editable: true),
          )),
      ],
    );
  }
}

class _FilterTotal extends StatelessWidget {
  const _FilterTotal({required this.title, required this.amount, required this.color});
  final String title;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 9),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 5),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text(money(amount), style: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w800, color: color))),
    ]),
  );
}
