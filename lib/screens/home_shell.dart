import 'package:material_ui/material_ui.dart';
import '../widgets/spendwise_brand_logo.dart';

import '../data/app_store.dart';
import '../widgets/transaction_form.dart';
import 'advanced/features_hub.dart';
import 'budgets_page.dart';
import 'dashboard_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';
import 'transactions_page.dart';

/// Five purposeful sections. Account preferences live behind the settings
/// icon, not in the finance-tool navigation.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});
  final AppStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selectedIndex = 0;

  static const _titles = <String>[
    'Overview',
    'Transactions',
    'Budgets',
    'Reports',
    'Money tools',
  ];

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.space_dashboard_outlined),
      selectedIcon: Icon(Icons.space_dashboard_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long_rounded),
      label: 'Activity',
    ),
    NavigationDestination(
      icon: Icon(Icons.savings_outlined),
      selectedIcon: Icon(Icons.savings_rounded),
      label: 'Budgets',
    ),
    NavigationDestination(
      icon: Icon(Icons.insert_chart_outlined_rounded),
      selectedIcon: Icon(Icons.insert_chart_rounded),
      label: 'Reports',
    ),
    NavigationDestination(
      icon: Icon(Icons.widgets_outlined),
      selectedIcon: Icon(Icons.widgets_rounded),
      label: 'Tools',
    ),
  ];

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(store: widget.store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 830;
    final pages = <Widget>[
      DashboardPage(
        store: widget.store,
        onViewAll: () => setState(() => selectedIndex = 1),
        onBudgets: () => setState(() => selectedIndex = 2),
      ),
      TransactionsPage(store: widget.store),
      BudgetsPage(store: widget.store),
      ReportsPage(store: widget.store),
      SpendWiseFeaturesHub(store: widget.store, embedded: true),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const SpendWiseBrandLogo(size: 34),
          const SizedBox(width: 10),
          const SpendWiseWordmark(width: 145),
          if (wide) ...[
            const SizedBox(width: 12),
            Text('/ ${_titles[selectedIndex]}',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ]),
        actions: [
          IconButton(
            tooltip: 'Add transaction',
            onPressed: () => openTransactionEditor(context, widget.store),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            tooltip: 'Settings and privacy',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 3),
        ],
      ),
      body: Row(children: [
        if (wide)
          SafeArea(
            child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => selectedIndex = index),
              extended: width >= 1150,
              labelType: width >= 1150
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard_rounded),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: Text('Activity'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.savings_outlined),
                  selectedIcon: Icon(Icons.savings_rounded),
                  label: Text('Budgets'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.insert_chart_outlined_rounded),
                  selectedIcon: Icon(Icons.insert_chart_rounded),
                  label: Text('Reports'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.widgets_outlined),
                  selectedIcon: Icon(Icons.widgets_rounded),
                  label: Text('Tools'),
                ),
              ],
            ),
          ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                reverseDuration: const Duration(milliseconds: 170),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.035, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey<int>(selectedIndex),
                  child: pages[selectedIndex],
                ),
              ),
            ),
          ),
        ),
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
              ),
            ),
    );
  }
}
