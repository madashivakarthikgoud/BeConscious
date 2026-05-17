import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/shared_widgets.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? editTransaction;
  final String? initialType;
  const AddTransactionScreen({super.key, this.editTransaction, this.initialType});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  TransactionType _type = TransactionType.expense;
  PaymentMode _paymentMode = PaymentMode.cash;
  String _moneySource = 'Self';
  String _beneficiary = 'Self';
  List<String> _selectedTags = [];
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  bool get _isEditing => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.editTransaction!;
      _amountCtrl.text = t.amount.toStringAsFixed(2);
      _descCtrl.text = t.description;
      _notesCtrl.text = t.notes ?? '';
      _type = t.type;
      _paymentMode = t.paymentMode;
      _moneySource = t.moneySourcePerson;
      _beneficiary = t.beneficiaryPerson;
      _selectedTags = List.from(t.tags);
      _selectedDate = t.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(t.dateTime);
    } else if (widget.initialType == 'income') {
      _type = TransactionType.income;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagProvider);
    final persons = ref.watch(personProvider);
    final typeColor = _type == TransactionType.expense
        ? AppTheme.expenseColor
        : AppTheme.incomeColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.xl),
          children: [
            // Type toggle
            GlassCard(
              padding: const EdgeInsets.all(AppTheme.xs),
              borderRadius: 16,
              child: Row(
                children: [
                  TypeToggleTab(
                    label: 'Expense',
                    icon: Icons.north_east_rounded,
                    color: AppTheme.expenseColor,
                    isSelected: _type == TransactionType.expense,
                    onTap: () => setState(() => _type = TransactionType.expense),
                  ),
                  TypeToggleTab(
                    label: 'Income',
                    icon: Icons.south_west_rounded,
                    color: AppTheme.incomeColor,
                    isSelected: _type == TransactionType.income,
                    onTap: () => setState(() => _type = TransactionType.income),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.xxl),

            Text('Amount', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: AppTheme.amountLarge.copyWith(color: typeColor, fontSize: 28),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: AppTheme.amountLarge.copyWith(color: typeColor, fontSize: 28),
                hintText: '0.00',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: AppTheme.xl),

            Text('Description', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'What was this for?'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter description' : null,
            ),
            const SizedBox(height: AppTheme.xl),

            Text('Date & Time', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            Row(
              children: [
                Expanded(
                  child: GlassDatePickerButton(
                    icon: Icons.calendar_today_rounded,
                    text: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.md),
                Expanded(
                  child: GlassDatePickerButton(
                    icon: Icons.access_time_rounded,
                    text: _selectedTime.format(context),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) setState(() => _selectedTime = time);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.xl),

            Text('Whose Money?', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            _PersonSelector(
              persons: persons,
              selected: _moneySource,
              onSelected: (v) => setState(() => _moneySource = v),
              onAddNew: () => showAddItemDialog(
                context: context,
                title: 'New Person',
                hint: 'Person name',
                onAdd: (name) => ref.read(personProvider.notifier).add(name),
              ),
            ),
            const SizedBox(height: AppTheme.xl),

            Text('For Whom?', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            _PersonSelector(
              persons: persons,
              selected: _beneficiary,
              onSelected: (v) => setState(() => _beneficiary = v),
              onAddNew: () => showAddItemDialog(
                context: context,
                title: 'New Person',
                hint: 'Person name',
                onAdd: (name) => ref.read(personProvider.notifier).add(name),
              ),
            ),
            const SizedBox(height: AppTheme.xl),

            Row(
              children: [
                Text('Tags', style: formLabelStyle),
                const Spacer(),
                GestureDetector(
                  onTap: () => showAddItemDialog(
                    context: context,
                    title: 'New Tag',
                    hint: 'Tag name',
                    onAdd: (name) => ref.read(tagProvider.notifier).add(name),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 16, color: AppTheme.accent1),
                      const SizedBox(width: AppTheme.xs),
                      Text('New Tag',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.accent1,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.sm),
            Wrap(
              spacing: AppTheme.sm,
              runSpacing: AppTheme.sm,
              children: tags.map((tag) {
                final selected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: AppTheme.accent1.withOpacity(0.2),
                  checkmarkColor: AppTheme.accent1,
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.xl),

            Text('Payment Mode', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            Wrap(
              spacing: AppTheme.sm,
              runSpacing: AppTheme.sm,
              children: PaymentMode.values.map((mode) {
                final selected = _paymentMode == mode;
                return ChoiceChip(
                  label: Text(_paymentModeLabel(mode)),
                  selected: selected,
                  onSelected: (v) {
                    if (v) setState(() => _paymentMode = mode);
                  },
                  selectedColor: AppTheme.accent1.withOpacity(0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.xl),

            Text('Notes (optional)', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Any additional notes...'),
            ),
            const SizedBox(height: AppTheme.xxxl),

            FullWidthButton(
              label: _isEditing ? 'Update' : 'Save Transaction',
              onPressed: _isSaving ? null : _save,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _paymentModeLabel(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash: return 'Cash';
      case PaymentMode.upi: return 'UPI';
      case PaymentMode.creditCard: return 'Credit Card';
      case PaymentMode.debitCard: return 'Debit Card';
      case PaymentMode.bankTransfer: return 'Bank Transfer';
      case PaymentMode.other: return 'Other';
    }
  }

  void _save() {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute,
      );

      final txn = TransactionModel(
        id: _isEditing ? widget.editTransaction!.id : const Uuid().v4(),
        amount: double.parse(_amountCtrl.text),
        type: _type,
        dateTime: dateTime,
        description: _descCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        moneySourcePerson: _moneySource,
        beneficiaryPerson: _beneficiary,
        tags: _selectedTags,
        paymentMode: _paymentMode,
      );

      if (_isEditing) {
        ref.read(transactionProvider.notifier).update(txn);
      } else {
        ref.read(transactionProvider.notifier).add(txn);
      }

      final msg = _isEditing ? 'Transaction updated!' : 'Transaction saved!';
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }
  }
}

class _PersonSelector extends StatelessWidget {
  final List<String> persons;
  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onAddNew;

  const _PersonSelector({
    required this.persons,
    required this.selected,
    required this.onSelected,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.sm,
      runSpacing: AppTheme.sm,
      children: [
        ...persons.map((p) {
          final isSelected = selected == p;
          return ChoiceChip(
            label: Text(p),
            selected: isSelected,
            onSelected: (v) { if (v) onSelected(p); },
            selectedColor: AppTheme.accent1.withOpacity(0.2),
          );
        }),
        ActionChip(
          label: const Text('+ Add'),
          onPressed: onAddNew,
        ),
      ],
    );
  }
}
