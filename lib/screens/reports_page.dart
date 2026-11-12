import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';

import '../data/app_store.dart';
import '../models/money_transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/spend_ui.dart';
import '../widgets/spend_donut.dart';

class ReportsPage extends StatefulWidget {
  final AppStore store;
  const ReportsPage({super.key, required this.store});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _changeMonth(int offset) => setState(() {
        _month = DateTime(_month.year, _month.month + offset);
      });

  @override
  Widget build(BuildContext context) {
    final income = widget.store.incomeForMonth(_month);
    final expenses = widget.store.expensesForMonth(_month);
    // Read the categories actually saved in the selected month, including
    // any future custom categories. This keeps chart totals accurate.
    final totalsByCategory = <String, double>{};
    for (final entry in widget.store.entriesInMonth(_month)) {
      if (entry.type != EntryType.expense) continue;
      totalsByCategory.update(entry.category, (old) => old + entry.amount,
          ifAbsent: () => entry.amount);
    }
    final categorySpends = <({String name, double amount})>[
      for (final pair in totalsByCategory.entries)
        (name: pair.key, amount: pair.value),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    final history = [
      for (int i = 5; i >= 0; i--)
        (
          date: DateTime(_month.year, _month.month - i),
          income: widget.store
              .incomeForMonth(DateTime(_month.year, _month.month - i)),
          expense: widget.store
              .expensesForMonth(DateTime(_month.year, _month.month - i)),
        ),
    ];
    final maxAmount = history.fold<double>(1.0,
        (maxValue, e) => math.max(maxValue, math.max(e.income, e.expense)));
    final previousExpenses =
        widget.store.expensesForMonth(DateTime(_month.year, _month.month - 1));
    final positiveCategories =
        categorySpends.where((e) => e.amount > 0).toList();
    const breakdownColors = <Color>[
      SpendColors.teal,
      SpendColors.orange,
      SpendColors.green,
      Color(0xFF6990CF),
      Color(0xFF8A6BC9),
      Color(0xFFC56E9C),
      Color(0xFFD3A24A),
      Color(0xFF5F9F9A),
      Color(0xFFB16F5D),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        SpendMonthSelector(
          label: monthLabel(_month),
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        const SizedBox(height: 17),
        SpendSectionHeader(
          title: 'Monthly overview',
          subtitle: 'Your income and spending snapshot',
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _ReportStat(
            title: 'Income',
            amount: income,
            icon: Icons.south_west_rounded,
            color: SpendColors.green,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _ReportStat(
            title: 'Expenses',
            amount: expenses,
            icon: Icons.north_east_rounded,
            color: SpendColors.orange,
          )),
        ]),
        const SizedBox(height: 10),
        Card(
            child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            SpendIconBadge(
                icon: Icons.balance_rounded, color: SpendColors.teal, size: 43),
            const SizedBox(width: 12),
            Expanded(
                child: Text('Net cash flow',
                    style: Theme.of(context).textTheme.titleSmall)),
            Flexible(
                child: FittedBox(
              alignment: Alignment.centerRight,
              child: Text(money(income - expenses),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
            )),
          ]),
        )),
        if (income > 0 || previousExpenses > 0) ...[
          const SizedBox(height: 12),
          Card(
              child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(children: [
              const SpendIconBadge(
                  icon: Icons.auto_graph_rounded,
                  color: SpendColors.teal,
                  size: 42),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      income > 0
                          ? 'Monthly savings rate'
                          : 'Expense comparison',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      income > 0
                          ? '${((income - expenses) / income * 100).toStringAsFixed(1)}% of monthly income remains'
                          : 'Last month: ${money(previousExpenses)} in expenses',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              )),
            ]),
          )),
        ],
        const SizedBox(height: 24),
        const SpendSectionHeader(
          title: 'Spending breakdown',
          subtitle: 'Real data grouped by expense category',
        ),
        const SizedBox(height: 12),
        if (expenses == 0)
          const SpendEmptyState(
            title: 'No expenses this month',
            message:
                'Expense categories will appear here after you add records.',
            icon: Icons.pie_chart_outline,
          )
        else ...[
          Card(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 21, horizontal: 14),
            child: Column(children: [
              SpendDonut(
                total: expenses,
                values: positiveCategories.map((e) => e.amount).toList(),
                colors: [
                  for (var i = 0; i < positiveCategories.length; i++)
                    breakdownColors[i % breakdownColors.length]
                ],
              ),
              const SizedBox(height: 12),
              Text(
                  '${positiveCategories.length} spending categor${positiveCategories.length == 1 ? 'y' : 'ies'}',
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          )),
          const SizedBox(height: 12),
          ...positiveCategories.map((item) {
            final share = item.amount / expenses;
            final categoryIndex = positiveCategories.indexOf(item);
            final itemColor =
                breakdownColors[categoryIndex % breakdownColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Card(
                  child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [
                    SpendIconBadge(
                        icon: categoryIcon(item.name),
                        color: itemColor,
                        size: 37),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700))),
                    Text(money(item.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: share.clamp(0.0, 1.0).toDouble(),
                    color: itemColor,
                    backgroundColor: itemColor.withValues(alpha: 0.12),
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 7),
                  Align(
                      alignment: Alignment.centerRight,
                      child: Text('${(share * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall)),
                ]),
              )),
            );
          }),
        ],
        const SizedBox(height: 25),
        const SpendSectionHeader(
          title: 'Last 6 months',
          subtitle: 'How income compares with expenses',
        ),
        const SizedBox(height: 12),
        Card(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 18),
          child: Column(children: [
            Wrap(alignment: WrapAlignment.end, spacing: 20, children: const [
              _Legend(color: SpendColors.green, label: 'Income'),
              _Legend(color: SpendColors.orange, label: 'Expenses'),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              height: 182,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: history
                    .map((item) => Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                  child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                      child: _bar(item.income, maxAmount,
                                          SpendColors.green)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                      child: _bar(item.expense, maxAmount,
                                          SpendColors.orange)),
                                ],
                              )),
                              const SizedBox(height: 10),
                              Text(
                                  monthNames[item.date.month - 1]
                                      .substring(0, 3),
                                  style:
                                      Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ]),
        )),
      ],
    );
  }

  Widget _bar(double value, double maxValue, Color color) {
    return FractionallySizedBox(
      alignment: Alignment.bottomCenter,
      heightFactor:
          value == 0 ? 0.012 : (value / maxValue).clamp(0.012, 1.0).toDouble(),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 28),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  const _ReportStat(
      {required this.title,
      required this.amount,
      required this.color,
      required this.icon});
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
          child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SpendIconBadge(icon: icon, color: color, size: 38),
          const SizedBox(height: 9),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(money(amount),
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                )),
          ),
        ]),
      ));
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
}
