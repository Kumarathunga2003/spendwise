import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/money_transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/spend_ui.dart';

class BudgetsPage extends StatefulWidget {
  final AppStore store;
  const BudgetsPage({super.key, required this.store});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _changeMonth(int offset) => setState(() {
    _month = DateTime(_month.year, _month.month + offset);
  });

  Future<void> _editBudget(String category) async {
    final result = await showDialog<_BudgetResult>(
      context: context,
      builder: (_) => _BudgetEditor(
        category: category,
        initialAmount: widget.store.budgetFor(category),
      ),
    );
    if (result == null || !mounted) return;
    try {
      if (result.remove) {
        await widget.store.removeBudget(category);
      } else {
        await widget.store.setBudget(category, result.amount!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget updated')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save budget. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = widget.store.budgets.fold<double>(
      0, (total, b) => total + b.amount,
    );
    final totalSpent = widget.store.expensesForMonth(_month);
    final budgetedSpent = widget.store.budgets.fold<double>(
      0, (total, budget) => total + widget.store.spendingForCategory(budget.category, _month),
    );
    final remaining = totalBudget - budgetedSpent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        SpendMonthSelector(
          label: monthLabel(_month),
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [SpendColors.deep, SpendColors.teal]),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Padding(
            padding: const EdgeInsets.all(23),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Spent this month',
                  style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 7),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  child: Text(money(totalSpent), style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800,
                    fontSize: 28,
                  )),
                ),
                const SizedBox(height: 13),
                Text('Category budget limits: ${money(totalBudget)}',
                  style: const TextStyle(color: Colors.white70)),
                if (totalBudget > 0)
                  Text(remaining >= 0
                      ? 'Left in budgeted categories: ${money(remaining)}'
                      : 'Above budgeted limits by: ${money(-remaining)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 23),
        const SpendSectionHeader(
          title: 'Category budgets',
          subtitle: 'Limits repeat every month; spending uses the selected month',
        ),
        const SizedBox(height: 13),
        ...SpendCategories.expense.map((category) {
          final budget = widget.store.budgetFor(category);
          final spent = widget.store.spendingForCategory(category, _month);
          final ratio = budget == null || budget == 0 ? 0.0 : spent / budget;
          final over = budget != null && spent > budget;
          final color = over ? SpendColors.orange : SpendColors.teal;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    SpendIconBadge(icon: categoryIcon(category), color: color,
                      size: 42),
                    const SizedBox(width: 10),
                    Expanded(child: Text(category,
                      style: const TextStyle(fontWeight: FontWeight.w800))),
                    TextButton(
                      onPressed: () => _editBudget(category),
                      child: Text(budget == null ? 'Set limit' : 'Edit'),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: Text(money(spent),
                      style: const TextStyle(fontWeight: FontWeight.w700))),
                    Flexible(child: Text(
                      budget == null ? 'No limit set' : 'of ${money(budget)}',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall,
                    )),
                  ]),
                  const SizedBox(height: 11),
                  SpendProgress(
                    value: ratio,
                    color: color,
                    label: '$category monthly budget use',
                  ),
                  const SizedBox(height: 7),
                  if (budget == null)
                    Text('Set a monthly limit to track this category.',
                      style: Theme.of(context).textTheme.bodySmall)
                  else if (over)
                    Text('Over budget by ${money(spent - budget)}',
                      style: const TextStyle(color: SpendColors.orange,
                        fontWeight: FontWeight.w700))
                  else
                    Text('${(ratio * 100).toStringAsFixed(0)}% used  •  '
                      '${money(budget - spent)} left',
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _BudgetResult {
  final bool remove;
  final double? amount;
  const _BudgetResult({this.remove = false, this.amount});
}

class _BudgetEditor extends StatefulWidget {
  final String category;
  final double? initialAmount;
  const _BudgetEditor({required this.category, required this.initialAmount});

  @override
  State<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<_BudgetEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.category} budget'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Monthly limit (LKR)'),
        validator: (value) {
          final amount = double.tryParse(value?.trim() ?? '');
          return amount == null || !amount.isFinite || amount <= 0
              ? 'Enter a positive amount' : null;
        },
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context),
        child: const Text('Cancel')),
      if (widget.initialAmount != null)
        TextButton(
          onPressed: () => Navigator.pop(context,
            const _BudgetResult(remove: true)),
          child: const Text('Remove'),
        ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(context, _BudgetResult(
            amount: double.parse(_controller.text.trim()),
          ));
        },
        child: const Text('Save'),
      ),
    ],
  );
}
