import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/app_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? editTransaction;
  const AddTransactionScreen({super.key, this.editTransaction});

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

    return Scaffold(
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
          padding: const EdgeInsets.all(20),
          children: [
            // Type toggle
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _TypeTab(
                    label: 'Expense',
                    icon: Icons.arrow_upward_rounded,
                    color: AppTheme.expenseColor,
                    isSelected: _type == TransactionType.expense,
                    onTap: () =>
                        setState(() => _type = TransactionType.expense),
                  ),
                  _TypeTab(
                    label: 'Income',
                    icon: Icons.arrow_downward_rounded,
                    color: AppTheme.incomeColor,
                    isSelected: _type == TransactionType.income,
                    onTap: () =>
                        setState(() => _type = TransactionType.income),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount
            Text('Amount', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _type == TransactionType.expense
                    ? AppTheme.expenseColor
                    : AppTheme.incomeColor,
              ),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _type == TransactionType.expense
                      ? AppTheme.expenseColor
                      : AppTheme.incomeColor,
                ),
                hintText: '0.00',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Description
            Text('Description', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'What was this for?'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter description' : null,
            ),
            const SizedBox(height: 20),

            // Date & Time
            Text('Date & Time', style: _labelStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) setState(() => _selectedTime = time);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 18),
                          const SizedBox(width: 10),
                          Text(_selectedTime.format(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Money Source
            Text('Whose Money?', style: _labelStyle),
            const SizedBox(height: 8),
            _PersonSelector(
              persons: persons,
              selected: _moneySource,
              onSelected: (v) => setState(() => _moneySource = v),
              onAddNew: () => _addNewPerson(context, ref),
            ),
            const SizedBox(height: 20),

            // Beneficiary
            Text('For Whom?', style: _labelStyle),
            const SizedBox(height: 8),
            _PersonSelector(
              persons: persons,
              selected: _beneficiary,
              onSelected: (v) => setState(() => _beneficiary = v),
              onAddNew: () => _addNewPerson(context, ref),
            ),
            const SizedBox(height: 20),

            // Tags
            Row(
              children: [
                Text('Tags', style: _labelStyle),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addNewTag(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Tag', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                  selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Payment Mode
            Text('Payment Mode', style: _labelStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMode.values.map((mode) {
                final selected = _paymentMode == mode;
                return ChoiceChip(
                  label: Text(_paymentModeLabel(mode)),
                  selected: selected,
                  onSelected: (v) {
                    if (v) setState(() => _paymentMode = mode);
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Notes
            Text('Notes (optional)', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(hintText: 'Any additional notes...'),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Update' : 'Save Transaction'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  TextStyle get _labelStyle => const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.white70,
      );

  String _paymentModeLabel(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.creditCard:
        return 'Credit Card';
      case PaymentMode.debitCard:
        return 'Debit Card';
      case PaymentMode.bankTransfer:
        return 'Bank Transfer';
      case PaymentMode.other:
        return 'Other';
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
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

    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Transaction updated!' : 'Transaction saved!'),
      ),
    );
  }

  void _addNewTag(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Tag'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Tag name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(tagProvider.notifier).add(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addNewPerson(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Person'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Person name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(personProvider.notifier).add(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : Colors.white38, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.white38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      spacing: 8,
      runSpacing: 8,
      children: [
        ...persons.map((p) {
          final isSelected = selected == p;
          return ChoiceChip(
            label: Text(p),
            selected: isSelected,
            onSelected: (v) {
              if (v) onSelected(p);
            },
            selectedColor: AppTheme.primaryColor.withOpacity(0.3),
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

