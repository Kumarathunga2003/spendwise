import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_store.dart';
import '../../import_export/csv_import.dart';
import '../../models/money_transaction.dart';
import '../../models/spendwise_features.dart';
import '../../notifications/expense_notifications.dart';
import '../../utils/formatters.dart';
import '../../widgets/spend_ui.dart';

/// The money tools now live in the Tools tab rather than Settings.
class SpendWiseFeaturesHub extends StatelessWidget {
  final AppStore store;
  final bool embedded;

  const SpendWiseFeaturesHub({
    super.key,
    required this.store,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final tools = <_MoneyTool>[
      _MoneyTool(
          'Wallets',
          'Cash, bank and balances',
          Icons.account_balance_wallet_outlined,
          const Color(0xFF0E8F79),
          () => _open(context, _WalletsPage(store: store))),
      _MoneyTool(
          'Savings goals',
          'Build a goal, see progress',
          Icons.savings_outlined,
          const Color(0xFF6774C9),
          () => _open(context, _GoalsPage(store: store))),
      _MoneyTool(
          'Recurring',
          'Manage repeat payments',
          Icons.event_repeat_outlined,
          const Color(0xFFCE884A),
          () => _open(context, _RecurringPage(store: store))),
      _MoneyTool(
          'Reminders',
          'Never miss a due date',
          Icons.notifications_active_outlined,
          const Color(0xFFB66F98),
          () => _open(context, _RemindersPage(store: store))),
      _MoneyTool(
          'CSV import',
          'Review and import records',
          Icons.file_upload_outlined,
          const Color(0xFF527FB1),
          () => _open(context, _CsvImportPage(store: store))),
    ];

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF076B63), Color(0xFF123E3B)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFC6F5E7), size: 26),
              const SizedBox(height: 9),
              const Text('Your money workspace',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              const Text(
                  'Everything you need to organize and plan your finances.',
                  style: TextStyle(color: Color(0xFFDBF2EB))),
              const SizedBox(height: 13),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _statPill('${store.features.wallets.length} wallets',
                    Icons.account_balance_wallet_outlined),
                _statPill('${store.features.goals.length} goals',
                    Icons.flag_outlined),
                _statPill('${store.features.recurring.length} recurring',
                    Icons.repeat_rounded),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 19),
        Text('Explore tools', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 5),
        Text('One place for wallets, goals, payments and imports',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 710 ? 3 : 2;
          // A fixed card height prevents the huge empty spaces seen on phones.
          final cardHeight = constraints.maxWidth < 350 ? 164.0 : 152.0;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tools.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: cardHeight,
            ),
            itemBuilder: (context, index) {
              final tool = tools[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 260 + index * 70),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 13 * (1 - value)),
                    child: child,
                  ),
                ),
                child: _ToolCard(tool: tool),
              );
            },
          );
        }),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lightbulb_outline_rounded),
            title: const Text('A little progress every day'),
            subtitle:
                const Text('Set a savings goal and build habits over time.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _open(context, _GoalsPage(store: store)),
          ),
        ),
      ],
    );

    return embedded
        ? AnimatedBuilder(animation: store, builder: (context, _) => content)
        : Scaffold(
            appBar: AppBar(title: const Text('Money tools')),
            body: AnimatedBuilder(
                animation: store, builder: (context, _) => content),
          );
  }

  static void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _statPill(String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

class _MoneyTool {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MoneyTool(
      this.title, this.subtitle, this.icon, this.color, this.onTap);
}

class _ToolCard extends StatelessWidget {
  final _MoneyTool tool;
  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tool.onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tool.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tool.icon, size: 21, color: tool.color),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_outward_rounded,
                      size: 17, color: foreground.withValues(alpha: 0.55)),
                ],
              ),
              const Spacer(),
              Text(
                tool.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 3),
              Text(
                tool.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _message(BuildContext context, String text) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

Future<String?> _textDialog(BuildContext context, String title,
    {String label = 'Name', String? initialValue, bool secure = false}) async {
  final controller = TextEditingController(text: initialValue);
  try {
    return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(title),
                content: TextField(
                    controller: controller,
                    autofocus: true,
                    obscureText: secure,
                    keyboardType:
                        secure ? TextInputType.number : TextInputType.text,
                    decoration: InputDecoration(labelText: label)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text.trim()),
                      child: const Text('Save'))
                ]));
  } finally {
    controller.dispose();
  }
}

class _WalletsPage extends StatelessWidget {
  final AppStore store;
  const _WalletsPage({required this.store});
  Future<void> _add(BuildContext context) async {
    final name = await _textDialog(context, 'New wallet', label: 'Wallet name');
    if (name == null || name.isEmpty || !context.mounted) return;
    final amount = await _textDialog(context, 'Opening balance',
        label: 'Amount (LKR)', initialValue: '0');
    if (amount == null || !context.mounted) return;
    try {
      final opening = double.parse(amount);
      final cents =
          amountInCents(opening.abs()) * (opening.isNegative ? -1 : 1);
      final wallet = Wallet(
          id: 'wallet-${freshFeatureId()}', name: name, openingCents: cents);
      await store.updateFeatures(store.features
          .copyWith(wallets: [...store.features.wallets, wallet]));
    } catch (e) {
      if (context.mounted) {
        _message(context, 'Could not add wallet: $e');
      }
    }
  }

  Future<void> _delete(BuildContext context, Wallet wallet) async {
    if (wallet.id == defaultWalletId) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text('Remove ${wallet.name}?'),
                content: const Text(
                    'You can only delete a wallet without transactions or recurring rules.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Remove'))
                ]));
    if (confirmed != true || !context.mounted) return;
    if (store.entries.any((e) => e.walletId == wallet.id) ||
        store.features.recurring.any((r) => r.walletId == wallet.id)) {
      _message(context,
          'This wallet has transactions or rules. Move or remove them first.');
      return;
    }
    try {
      await store.updateFeatures(store.features.copyWith(
          wallets:
              store.features.wallets.where((w) => w.id != wallet.id).toList()));
    } catch (e) {
      if (context.mounted) {
        _message(context, '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: store,
      builder: (ctx, _) => Scaffold(
            appBar: AppBar(title: const Text('My wallets')),
            floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _add(ctx),
                icon: const Icon(Icons.add),
                label: const Text('New wallet')),
            body: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                itemCount: store.features.wallets.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(3, 4, 3, 15),
                      child: Text(
                          'Organize your money by wallet. Your Cash wallet is ready to use.'),
                    );
                  }
                  final w = store.features.wallets[i - 1];
                  final balance =
                      store.features.walletBalanceCents(w.id, store.entries) /
                          100;
                  return Card(
                      child: ListTile(
                          leading:
                              const Icon(Icons.account_balance_wallet_outlined),
                          title: Text(w.name),
                          subtitle: Text(
                              '${money(balance)} • ${store.entries.where((e) => e.walletId == w.id).length} transactions'),
                          trailing: w.id == defaultWalletId
                              ? null
                              : IconButton(
                                  tooltip: 'Delete wallet',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(ctx, w))));
                }),
          ));
}

class _GoalsPage extends StatelessWidget {
  final AppStore store;
  const _GoalsPage({required this.store});
  Future<void> _add(BuildContext context) async {
    final title =
        await _textDialog(context, 'New savings goal', label: 'Goal name');
    if (title == null || title.isEmpty || !context.mounted) return;
    final value =
        await _textDialog(context, 'Target amount', label: 'Amount (LKR)');
    if (value == null || !context.mounted) return;
    try {
      final cents = amountInCents(double.parse(value));
      if (cents == 0) throw const FormatException('Target must be positive.');
      final goal = SavingsGoal(
          id: freshFeatureId(),
          title: title,
          targetCents: cents,
          savedCents: 0);
      await store.updateFeatures(
          store.features.copyWith(goals: [...store.features.goals, goal]));
    } catch (e) {
      if (context.mounted) {
        _message(context, '$e');
      }
    }
  }

  Future<void> _contribute(BuildContext ctx, SavingsGoal goal) async {
    final value = await _textDialog(ctx, 'Add money to ${goal.title}',
        label: 'Amount (LKR)');
    if (value == null || !ctx.mounted) return;
    try {
      final cents = amountInCents(double.parse(value));
      if (cents == 0) throw const FormatException('Amount must be positive.');
      final goals = store.features.goals
          .map((g) => g.id == goal.id
              ? g.copyWith(savedCents: g.savedCents + cents)
              : g)
          .toList();
      await store.updateFeatures(store.features.copyWith(goals: goals));
      if (ctx.mounted) {
        _message(
            ctx, 'Progress updated. This does not create a bank transfer.');
      }
    } catch (e) {
      if (ctx.mounted) {
        _message(ctx, '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: store,
      builder: (ctx, _) => Scaffold(
            appBar: AppBar(title: const Text('Savings goals')),
            floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _add(ctx),
                icon: const Icon(Icons.add),
                label: const Text('New goal')),
            body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 94),
                children: [
                  const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'Goal progress is a separate tracker, not money moved between wallets.')),
                  if (store.features.goals.isEmpty)
                    SpendEmptyState(
                      icon: Icons.flag_outlined,
                      title: 'Set your first savings goal',
                      message:
                          'Give your goal a name and a target amount. Track progress without changing your wallet balance.',
                      action: FilledButton.icon(
                        onPressed: () => _add(ctx),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create a goal'),
                      ),
                    ),
                  for (final g in store.features.goals)
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(g.title,
                                            style: Theme.of(ctx)
                                                .textTheme
                                                .titleMedium)),
                                    IconButton(
                                        tooltip: 'Delete goal',
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () async {
                                          await store.updateFeatures(
                                              store.features.copyWith(
                                                  goals: store.features.goals
                                                      .where(
                                                          (x) => x.id != g.id)
                                                      .toList()));
                                        })
                                  ]),
                                  Text(
                                      '${money(g.savedCents / 100)} of ${money(g.targetCents / 100)}'),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(value: g.progress),
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                          onPressed: () => _contribute(ctx, g),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Record saving'))),
                                ]))),
                ]),
          ));
}

class _RecurringPage extends StatelessWidget {
  final AppStore store;
  const _RecurringPage({required this.store});
  Future<void> _create(BuildContext context) async {
    final title = TextEditingController();
    final amount = TextEditingController();
    var interval = RepeatInterval.monthly;
    var type = EntryType.expense;
    var walletId = defaultWalletId;
    var category = SpendCategories.expense.first;
    var date = DateTime.now();
    try {
      final created = await showDialog<RecurringRule>(
          context: context,
          builder: (ctx) => StatefulBuilder(
              builder: (ctx, setDialogState) => AlertDialog(
                    title: const Text('New recurring transaction'),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: title,
                          decoration:
                              const InputDecoration(labelText: 'Title')),
                      TextField(
                          controller: amount,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Amount (LKR)')),
                      DropdownButtonFormField<EntryType>(
                          initialValue: type,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: EntryType.values
                              .map((e) => DropdownMenuItem(
                                  value: e, child: Text(e.name)))
                              .toList(),
                          onChanged: (v) => setDialogState(() {
                                type = v ?? type;
                                category = type == EntryType.income
                                    ? SpendCategories.income.first
                                    : SpendCategories.expense.first;
                              })),
                      DropdownButtonFormField<String>(
                          key: ValueKey(type),
                          initialValue: category,
                          decoration:
                              const InputDecoration(labelText: 'Category'),
                          items: (type == EntryType.income
                                  ? SpendCategories.income
                                  : SpendCategories.expense)
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => category = v ?? category)),
                      DropdownButtonFormField<String>(
                          initialValue: walletId,
                          decoration:
                              const InputDecoration(labelText: 'Wallet'),
                          items: store.features.wallets
                              .map((e) => DropdownMenuItem(
                                  value: e.id, child: Text(e.name)))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => walletId = v ?? walletId)),
                      DropdownButtonFormField<RepeatInterval>(
                          initialValue: interval,
                          decoration:
                              const InputDecoration(labelText: 'Repeat'),
                          items: RepeatInterval.values
                              .map((e) => DropdownMenuItem(
                                  value: e, child: Text(e.name)))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => interval = v ?? interval)),
                      TextButton.icon(
                          icon: const Icon(Icons.calendar_month),
                          label: Text('First date: ${shortDate(date)}'),
                          onPressed: () async {
                            final d = await showDatePicker(
                                context: ctx,
                                initialDate: date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100));
                            if (d != null) setDialogState(() => date = d);
                          }),
                    ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () {
                            try {
                              final cents = amountInCents(
                                  double.parse(amount.text.trim()));
                              if (title.text.trim().isEmpty || cents == 0) {
                                throw const FormatException(
                                    'Enter title and amount.');
                              }
                              Navigator.pop(
                                  ctx,
                                  RecurringRule(
                                      id: freshFeatureId(),
                                      title: title.text.trim(),
                                      amountCents: cents,
                                      type: type,
                                      category: category,
                                      walletId: walletId,
                                      interval: interval,
                                      nextDate: date));
                            } catch (e) {
                              _message(ctx, 'Invalid rule: $e');
                            }
                          },
                          child: const Text('Create'))
                    ],
                  )));
      if (created == null || !context.mounted) return;
      await store.updateFeatures(store.features
          .copyWith(recurring: [...store.features.recurring, created]));
      await store.processRecurringNow();
    } catch (e) {
      if (context.mounted) {
        _message(context, '$e');
      }
    } finally {
      title.dispose();
      amount.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: store,
      builder: (ctx, _) => Scaffold(
            appBar: AppBar(title: const Text('Recurring transactions')),
            floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _create(ctx),
                icon: const Icon(Icons.add),
                label: const Text('New rule')),
            body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 94),
                children: [
                  const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'Due items are generated when the app opens or you tap Sync. Maximum 36 missed periods per rule per sync.')),
                  TextButton.icon(
                      onPressed: () async {
                        await store.processRecurringNow();
                        if (ctx.mounted) {
                          _message(ctx, 'Due entries synchronized');
                        }
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync due entries')),
                  if (store.features.recurring.isEmpty)
                    SpendEmptyState(
                      icon: Icons.repeat_rounded,
                      title: 'No recurring entries yet',
                      message:
                          'Set up regular income or expenses. Due entries are generated when you open SpendWise or sync.',
                      action: FilledButton.icon(
                        onPressed: () => _create(ctx),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create a recurring rule'),
                      ),
                    ),
                  for (final r in store.features.recurring)
                    Card(
                        child: ListTile(
                      title: Text(r.title),
                      subtitle: Text(
                          '${money(r.amountCents / 100)} • ${r.interval.name} • next ${shortDate(r.nextDate)}'),
                      trailing: IconButton(
                          tooltip: 'Delete rule',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await store.updateFeatures(store.features.copyWith(
                                recurring: store.features.recurring
                                    .where((x) => x.id != r.id)
                                    .toList()));
                          }),
                    )),
                ]),
          ));
}

class _RemindersPage extends StatelessWidget {
  final AppStore store;
  const _RemindersPage({required this.store});
  Future<void> _add(BuildContext ctx) async {
    final title = await _textDialog(ctx, 'New expense reminder',
        label: 'Bill or reminder name');
    if (title == null || title.isEmpty || !ctx.mounted) return;
    final d = await showDatePicker(
        context: ctx,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100));
    if (d == null || !ctx.mounted) return;
    final time = await showTimePicker(
        context: ctx, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (time == null || !ctx.mounted) return;
    final when = DateTime(d.year, d.month, d.day, time.hour, time.minute);
    if (!when.isAfter(DateTime.now())) {
      _message(ctx, 'Choose a future time.');
      return;
    }
    try {
      final permission = await ExpenseNotifications.requestPermission();
      if (!permission) {
        if (ctx.mounted) {
          _message(
              ctx, 'Notifications disabled. Allow them in Android Settings.');
        }
        return;
      }
      final next = store.features.copyWith(reminders: [
        ...store.features.reminders,
        ExpenseReminder(id: freshFeatureId(), title: title, when: when)
      ]);
      await store.updateFeatures(next);
      await ExpenseNotifications.sync(next.reminders);
      if (ctx.mounted) {
        _message(
            ctx, 'Reminder scheduled. Android may delay it to save battery.');
      }
    } catch (e) {
      if (ctx.mounted) {
        _message(ctx, 'Could not schedule reminder: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: store,
      builder: (ctx, _) => Scaffold(
            appBar: AppBar(title: const Text('Expense reminders')),
            floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _add(ctx),
                icon: const Icon(Icons.add_alert),
                label: const Text('New reminder')),
            body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 94),
                children: [
                  const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'Local Android notifications need permission. Phone battery settings may delay reminders.')),
                  if (store.features.reminders.isEmpty)
                    SpendEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'Stay ahead of upcoming bills',
                      message:
                          'Schedule a local reminder for your next payment. Notification permission is required.',
                      action: FilledButton.icon(
                        onPressed: () => _add(ctx),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Set a reminder'),
                      ),
                    ),
                  for (final r in store.features.reminders)
                    Card(
                        child: ListTile(
                      title: Text(r.title),
                      subtitle: Text(
                          '${shortDate(r.when)}  ${TimeOfDay.fromDateTime(r.when).format(ctx)}'),
                      trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete reminder',
                          onPressed: () async {
                            final next = store.features.copyWith(
                                reminders: store.features.reminders
                                    .where((e) => e.id != r.id)
                                    .toList());
                            await ExpenseNotifications.cancelAll([r]);
                            await store.updateFeatures(next);
                          }),
                    )),
                ]),
          ));
}

class _CsvImportPage extends StatefulWidget {
  final AppStore store;
  const _CsvImportPage({required this.store});
  @override
  State<_CsvImportPage> createState() => _CsvImportPageState();
}

class _CsvImportPageState extends State<_CsvImportPage> {
  CsvPreview? preview;
  bool busy = false;
  Future<void> _pick() async {
    setState(() {
      busy = true;
      preview = null;
    });
    try {
      final file = await FilePicker.pickFile(type: FileType.any);
      if (file == null) return;
      final len = file.lengthSync() ?? await file.length();
      if (len != null && len > 6 * 1024 * 1024) {
        throw const FormatException('CSV exceeds 6MB');
      }
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => preview = previewSpendWiseCsv(bytes));
    } catch (e) {
      if (mounted) _message(context, 'CSV could not be read: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _import() async {
    if (preview == null || preview!.problems.isNotEmpty) return;
    setState(() => busy = true);
    try {
      final before = widget.store.entries.length;
      await widget.store.importTransactions(preview!.entries);
      if (mounted) {
        _message(context,
            '${widget.store.entries.length - before} new transactions imported.');
        setState(() => preview = null);
      }
    } catch (e) {
      if (mounted) {
        _message(context, 'Import stopped without replacing records: $e');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Import CSV')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text(
              'Import SpendWise CSV exports. Each row is checked before any records are added. Existing matching transactions are skipped. Imported records are placed in the Cash wallet.'),
          const SizedBox(height: 20),
          FilledButton.icon(
              onPressed: busy ? null : _pick,
              icon: const Icon(Icons.file_open),
              label: const Text('Choose CSV file')),
          if (preview != null) ...[
            const SizedBox(height: 16),
            Text(
                '${preview!.entries.length} valid rows • ${preview!.problems.length} errors'),
            for (final p in preview!.problems.take(10))
              Text(p,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (preview!.problems.isEmpty && preview!.entries.isNotEmpty) ...[
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: busy ? null : _import,
                  child: const Text('Import valid records')),
            ],
          ],
        ]),
      );
}
