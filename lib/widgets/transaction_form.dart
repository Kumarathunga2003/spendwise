import 'package:material_ui/material_ui.dart';

import '../data/app_store.dart';
import '../models/money_transaction.dart';
import '../utils/formatters.dart';

Future<void> openTransactionEditor(
  BuildContext context,
  AppStore store, {
  MoneyTransaction? existing,
}) async {
  final result = await showModalBottomSheet<MoneyTransaction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => TransactionForm(existing: existing, store: store),
  );
  if (result == null || !context.mounted) return;
  try {
    await store.saveEntry(result);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(existing == null
                ? 'Transaction added'
                : 'Transaction updated')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not save transaction. Please retry.')),
      );
    }
  }
}

class TransactionForm extends StatefulWidget {
  final MoneyTransaction? existing;
  final AppStore store;
  const TransactionForm({super.key, this.existing, required this.store});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late EntryType _type;
  late String _category;
  late DateTime _date;
  late String _walletId;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _title = TextEditingController(text: item?.title ?? '');
    _amount = TextEditingController(
      text: item == null ? '' : item.amount.toStringAsFixed(2),
    );
    _note = TextEditingController(text: item?.note ?? '');
    _type = item?.type ?? EntryType.expense;
    _category = item?.category ?? SpendCategories.expense.first;
    _date = item?.date ?? DateTime.now();
    _walletId = item?.walletId ?? widget.store.features.wallets.first.id;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      MoneyTransaction(
        id: widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        amount: double.parse(_amount.text.trim()),
        type: _type,
        category: _category,
        date: _date,
        note: _note.text.trim(),
        walletId: _walletId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _type == EntryType.income;
    final categories =
        isIncome ? SpendCategories.income : SpendCategories.expense;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomPadding + 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.existing == null
                      ? 'Add transaction'
                      : 'Edit transaction',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 14),
                SegmentedButton<EntryType>(
                  segments: const [
                    ButtonSegment(
                        value: EntryType.expense, label: Text('Expense')),
                    ButtonSegment(
                        value: EntryType.income, label: Text('Income')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _type = selection.first;
                      _category = _type == EntryType.income
                          ? SpendCategories.income.first
                          : SpendCategories.expense.first;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _title,
                  maxLength: 70,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a title'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (LKR)',
                    prefixText: 'Rs. ',
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    return amount == null || !amount.isFinite || amount <= 0
                        ? 'Enter an amount greater than zero'
                        : null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: categories.contains(_category)
                      ? _category
                      : categories.first,
                  key: ValueKey(_type),
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: widget.store.features.wallets
                          .any((w) => w.id == _walletId)
                      ? _walletId
                      : widget.store.features.wallets.first.id,
                  decoration: const InputDecoration(labelText: 'Wallet'),
                  items: widget.store.features.wallets
                      .map((w) =>
                          DropdownMenuItem(value: w.id, child: Text(w.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _walletId = v);
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _chooseDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Date: ${shortDate(_date)}'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _note,
                  maxLines: 2,
                  maxLength: 250,
                  decoration:
                      const InputDecoration(labelText: 'Note (optional)'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save transaction'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
