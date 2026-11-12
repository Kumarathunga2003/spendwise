import 'package:material_ui/material_ui.dart';

import '../data/app_store.dart';
import '../widgets/transaction_form.dart';
import 'budgets_page.dart';
import 'dashboard_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';
import 'transactions_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});
  final AppStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selectedIndex = 0;
  static const _titles = [
    'Overview',
    'Activity',
    'Budgets',
    'Analytics',
    'Settings'
  ];
  static const _destinations = <NavigationDestination>[
    NavigationDestination(
        icon: Icon(Icons.space_dashboard_outlined),
        selectedIcon: Icon(Icons.space_dashboard_rounded),
        label: 'Home'),
    NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long_rounded),
        label: 'History'),
    NavigationDestination(
        icon: Icon(Icons.savings_outlined),
        selectedIcon: Icon(Icons.savings_rounded),
        label: 'Budgets'),
    NavigationDestination(
        icon: Icon(Icons.insert_chart_outlined_rounded),
        selectedIcon: Icon(Icons.insert_chart_rounded),
        label: 'Reports'),
    NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings_rounded),
        label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 820;
    final pages = <Widget>[
      DashboardPage(
          store: widget.store,
          onViewAll: () => setState(() => selectedIndex = 1),
          onBudgets: () => setState(() => selectedIndex = 2)),
      TransactionsPage(store: widget.store),
      BudgetsPage(store: widget.store),
      ReportsPage(store: widget.store),
      SettingsPage(store: widget.store),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10)),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset('assets/branding/spendwise_launcher.png',
                    fit: BoxFit.cover)),
          ),
          const SizedBox(width: 10),
          const Text('SpendWise'),
          if (wide) ...[
            const SizedBox(width: 14),
            Text('/  ${_titles[selectedIndex]}',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ]),
        actions: [
          if (selectedIndex != 4)
            IconButton(
              tooltip: 'Add transaction',
              onPressed: () => openTransactionEditor(context, widget.store),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(children: [
        if (wide)
          SafeArea(
              child: NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => selectedIndex = index),
            extended: MediaQuery.sizeOf(context).width >= 1150,
            labelType: MediaQuery.sizeOf(context).width >= 1150
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard_rounded),
                  label: Text('Home')),
              NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: Text('History')),
              NavigationRailDestination(
                  icon: Icon(Icons.savings_outlined),
                  selectedIcon: Icon(Icons.savings_rounded),
                  label: Text('Budgets')),
              NavigationRailDestination(
                  icon: Icon(Icons.insert_chart_outlined_rounded),
                  selectedIcon: Icon(Icons.insert_chart_rounded),
                  label: Text('Reports')),
              NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: Text('Settings')),
            ],
          )),
        Expanded(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: IndexedStack(index: selectedIndex, children: pages),
        ))),
      ]),
      bottomNavigationBar: wide
          ? null
          : SafeArea(
              top: false,
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => selectedIndex = index),
                destinations: _destinations,
              )),
    );
  }
}
