import 'package:material_ui/material_ui.dart';

import '../data/app_store.dart';
import '../models/money_transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/spend_ui.dart';
import '../widgets/transaction_form.dart';
import '../widgets/transaction_tile.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage(
      {super.key,
      required this.store,
      required this.onViewAll,
      required this.onBudgets});
  final AppStore store;
  final VoidCallback onViewAll;
  final VoidCallback onBudgets;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final income = store.incomeForMonth(now);
    final expenses = store.expensesForMonth(now);
    final net = income - expenses;
    final recent = store.entries.take(4).toList();
    final currentBudget =
        store.budgets.fold<double>(0, (sum, b) => sum + b.amount);
    final coveredSpend = store.budgets.fold<double>(
        0, (sum, b) => sum + store.spendingForCategory(b.category, now));
    final alerts = SpendCategories.expense.where((category) {
      final limit = store.budgetFor(category);
      return limit != null && store.spendingForCategory(category, now) > limit;
    }).toList();
    final categories = <({String name, double amount})>[
      for (final name in SpendCategories.expense)
        (name: name, amount: store.spendingForCategory(name, now)),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    final topCategory = categories.isNotEmpty && categories.first.amount > 0
        ? categories.first
        : null;
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 30),
      children: [
        Row(children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 3),
              Text('Here is your financial overview for ${monthLabel(now)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          )),
          const SpendIconBadge(
              icon: Icons.auto_graph_rounded,
              color: SpendColors.teal,
              size: 48),
        ]),
        const SizedBox(height: 14),
        _HeroBalance(
            balance: store.balance,
            income: store.totalIncome,
            expense: store.totalExpense),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => openTransactionEditor(context, store),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add transaction'),
          ),
        ),
        const SizedBox(height: 20),
        SpendSectionHeader(
          title: 'Monthly snapshot',
          subtitle: 'Your income and spending this month',
          action: SpendPill(
              label: monthNames[now.month - 1].substring(0, 3).toUpperCase(),
              icon: Icons.calendar_today_outlined),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _MetricCard(
                  title: 'Income',
                  amount: income,
                  color: SpendColors.green,
                  icon: Icons.south_west_rounded)),
          const SizedBox(width: 10),
          Expanded(
              child: _MetricCard(
                  title: 'Expenses',
                  amount: expenses,
                  color: SpendColors.orange,
                  icon: Icons.north_east_rounded)),
        ]),
        const SizedBox(height: 11),
        Card(
            child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(children: [
            SpendIconBadge(
                icon: Icons.savings_rounded,
                color: net >= 0 ? SpendColors.teal : SpendColors.red),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This month\'s net cash flow',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(money(net),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: net >= 0
                                ? SpendColors.green
                                : SpendColors.red))),
              ],
            )),
            if (income > 0)
              SpendPill(
                  color: net >= 0 ? SpendColors.green : SpendColors.red,
                  label: '${(net / income * 100).toStringAsFixed(0)}% saved'),
          ]),
        )),
        SpendSectionHeader(
            title: 'Budget health',
            subtitle: currentBudget > 0
                ? 'Your active category limits this month'
                : 'Create a spending plan that works for you',
            action:
                TextButton(onPressed: onBudgets, child: const Text('Manage'))),
        const SizedBox(height: 11),
        Card(
            child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentBudget == 0) ...[
                Row(children: [
                  const SpendIconBadge(
                      icon: Icons.track_changes_rounded,
                      color: SpendColors.teal,
                      size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'Set monthly category limits to see your budget health here.',
                          style: Theme.of(context).textTheme.bodyMedium)),
                ]),
              ] else ...[
                Row(children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spent within budgeted categories',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 5),
                      Text(money(coveredSpend),
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  )),
                  SpendPill(
                    label: alerts.isEmpty
                        ? 'On track'
                        : '${alerts.length} alert${alerts.length == 1 ? '' : 's'}',
                    icon: alerts.isEmpty
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    color:
                        alerts.isEmpty ? SpendColors.green : SpendColors.orange,
                  ),
                ]),
                const SizedBox(height: 14),
                SpendProgress(
                    value: coveredSpend / currentBudget,
                    color:
                        alerts.isEmpty ? SpendColors.teal : SpendColors.orange,
                    label: 'Budgeted category spending progress'),
                const SizedBox(height: 9),
                Text('Of ${money(currentBudget)} in category limits',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        )),
        const SizedBox(height: 20),
        SpendSectionHeader(
            title: 'Smart snapshot',
            subtitle: 'Insights based on this month\'s entries'),
        const SizedBox(height: 12),
        Card(
            child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(children: [
            SpendIconBadge(
                icon: alerts.isNotEmpty
                    ? Icons.warning_amber_rounded
                    : topCategory == null
                        ? Icons.lightbulb_outline_rounded
                        : categoryIcon(topCategory.name),
                color:
                    alerts.isNotEmpty ? SpendColors.orange : SpendColors.teal),
            const SizedBox(width: 13),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    alerts.isNotEmpty
                        ? 'Budget attention needed'
                        : topCategory == null
                            ? 'Start building insights'
                            : 'Your largest spending category',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(
                    alerts.isNotEmpty
                        ? 'Over limit: ${alerts.join(', ')}.'
                        : topCategory == null
                            ? 'Add some expenses to discover where your money goes.'
                            : '${topCategory.name} accounts for ${expenses == 0 ? '0' : (topCategory.amount / expenses * 100).toStringAsFixed(0)}% of your expenses (${money(topCategory.amount)}).',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            )),
          ]),
        )),
        const SizedBox(height: 20),
        SpendSectionHeader(
            title: 'Recent activity',
            subtitle: 'Your latest money movements',
            action: TextButton.icon(
                onPressed: onViewAll,
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text('View all'))),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          SpendEmptyState(
              title: 'No transactions yet',
              message: 'Add your first income or expense to get started.',
              action: FilledButton.icon(
                  onPressed: () => openTransactionEditor(context, store),
                  icon: const Icon(Icons.add),
                  label: const Text('Add transaction')))
        else
          ...recent.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: TransactionTile(entry: entry, store: store),
              )),
      ],
    );
  }
}

class _HeroBalance extends StatelessWidget {
  const _HeroBalance(
      {required this.balance, required this.income, required this.expense});
  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SpendColors.deep, SpendColors.teal]),
          boxShadow: [
            BoxShadow(
                color: SpendColors.teal.withValues(alpha: 0.19),
                blurRadius: 22,
                offset: const Offset(0, 9)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned(
              right: -45,
              top: -75,
              child: Container(
                width: 185,
                height: 185,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 30)),
              )),
          Positioned(
              right: 6,
              bottom: -66,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.045)),
              )),
          Padding(
              padding: const EdgeInsets.all(19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        color: SpendColors.mint.withValues(alpha: 0.95),
                        size: 20),
                    const SizedBox(width: 8),
                    const Text('TOTAL BALANCE',
                        style: TextStyle(
                            color: SpendColors.mint,
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(money(balance),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              letterSpacing: -0.8,
                              fontWeight: FontWeight.w800))),
                  const SizedBox(height: 5),
                  const Text('Your all-time financial position',
                      style: TextStyle(fontSize: 13, color: Color(0xFFD3F0E9))),
                  const SizedBox(height: 15),
                  Container(
                      height: 1, color: Colors.white.withValues(alpha: 0.17)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _HeroTotal(
                            label: 'Total income',
                            amount: income,
                            icon: Icons.arrow_downward_rounded)),
                    Container(
                        height: 35,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.18)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _HeroTotal(
                            label: 'Total expenses',
                            amount: expense,
                            icon: Icons.arrow_upward_rounded)),
                  ]),
                ],
              )),
        ]),
      );
}

class _HeroTotal extends StatelessWidget {
  const _HeroTotal(
      {required this.label, required this.amount, required this.icon});
  final String label;
  final double amount;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: SpendColors.mint, size: 15),
            const SizedBox(width: 4),
            Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFFD3F0E9), fontSize: 11))),
          ]),
          const SizedBox(height: 5),
          FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(money(amount),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800))),
        ],
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.title,
      required this.amount,
      required this.icon,
      required this.color});
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
          child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SpendIconBadge(icon: icon, color: color, size: 38),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 5),
          FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(money(amount),
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: color))),
        ]),
      ));
}
