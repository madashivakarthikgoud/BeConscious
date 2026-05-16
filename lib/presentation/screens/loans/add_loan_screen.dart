import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/loan_model.dart';
import '../../providers/app_providers.dart';

class AddLoanScreen extends ConsumerStatefulWidget {
  final LoanModel? editLoan;
  const AddLoanScreen({super.key, this.editLoan});

  @override
  ConsumerState<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends ConsumerState<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _principalCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _personNameCtrl = TextEditingController();
  final _personContactCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  LoanType _type = LoanType.taken;
  InterestType _interestType = InterestType.simple;
  InterestPeriod _interestPeriod = InterestPeriod.yearly;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isSaving = false;

  bool get _isEditing => widget.editLoan != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final l = widget.editLoan!;
      _principalCtrl.text = l.principalAmount.toStringAsFixed(2);
      _rateCtrl.text = l.interestRate.toStringAsFixed(2);
      _personNameCtrl.text = l.personName;
      _personContactCtrl.text = l.personContact ?? '';
      _notesCtrl.text = l.notes ?? '';
      _type = l.type;
      _interestType = l.interestType;
      _interestPeriod = l.interestPeriod;
      _startDate = l.startDate;
      _endDate = l.expectedEndDate;
    }
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _personNameCtrl.dispose();
    _personContactCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Loan' : 'Add Loan'),
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
                    label: 'I Borrowed',
                    icon: Icons.arrow_downward_rounded,
                    color: AppTheme.loanTakenColor,
                    isSelected: _type == LoanType.taken,
                    onTap: () => setState(() => _type = LoanType.taken),
                  ),
                  _TypeTab(
                    label: 'I Lent',
                    icon: Icons.arrow_upward_rounded,
                    color: AppTheme.loanGivenColor,
                    isSelected: _type == LoanType.given,
                    onTap: () => setState(() => _type = LoanType.given),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Person name
            Text('Person Name', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _personNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: _type == LoanType.taken
                    ? 'Who did you borrow from?'
                    : 'Who did you lend to?',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: 16),

            // Contact (optional)
            Text('Contact (optional)', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _personContactCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Phone number'),
            ),
            const SizedBox(height: 20),

            // Principal Amount
            Text('Principal Amount', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _principalCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                prefixStyle:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                hintText: '0.00',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                if (double.tryParse(v) == null || double.parse(v) <= 0)
                  return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Interest Rate
            Text('Interest Rate (% per annum)', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _rateCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                suffixText: '%',
                hintText: '0.00',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter rate';
                if (double.tryParse(v) == null) return 'Invalid rate';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Interest Type
            Text('Interest Type', style: _labelStyle),
            const SizedBox(height: 8),
            Row(
              children: InterestType.values.map((t) {
                final selected = _interestType == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _interestType = t),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: t == InterestType.simple ? 8 : 0,
                          left: t == InterestType.compound ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryColor.withOpacity(0.15)
                            : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primaryColor
                              : Colors.white12,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          t == InterestType.simple ? 'Simple' : 'Compound',
                          style: TextStyle(
                            color: selected
                                ? AppTheme.primaryColor
                                : Colors.white54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Compounding Period
            if (_interestType == InterestType.compound) ...[
              Text('Compounding Period', style: _labelStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: InterestPeriod.values.map((p) {
                  final selected = _interestPeriod == p;
                  return ChoiceChip(
                    label: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                    selected: selected,
                    onSelected: (v) {
                      if (v) setState(() => _interestPeriod = p);
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Start Date
            Text('Start Date', style: _labelStyle),
            const SizedBox(height: 8),
            _DatePicker(
              date: _startDate,
              onPick: (d) => setState(() => _startDate = d),
            ),
            const SizedBox(height: 20),

            // Expected End Date
            Text('Expected End Date (optional)', style: _labelStyle),
            const SizedBox(height: 8),
            _DatePicker(
              date: _endDate,
              hint: 'Select end date',
              onPick: (d) => setState(() => _endDate = d),
            ),
            const SizedBox(height: 20),

            // Notes
            Text('Notes (optional)', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Any notes...'),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Update Loan' : 'Save Loan'),
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

  void _save() {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final loan = LoanModel(
      id: _isEditing ? widget.editLoan!.id : const Uuid().v4(),
      type: _type,
      personName: _personNameCtrl.text.trim(),
      personContact: _personContactCtrl.text.trim().isEmpty
          ? null
          : _personContactCtrl.text.trim(),
      principalAmount: double.parse(_principalCtrl.text),
      interestRate: double.parse(_rateCtrl.text),
      interestType: _interestType,
      interestPeriod: _interestPeriod,
      startDate: _startDate,
      expectedEndDate: _endDate,
      payments: _isEditing ? widget.editLoan!.payments : [],
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (_isEditing) {
      ref.read(loanProvider.notifier).update(loan);
    } else {
      ref.read(loanProvider.notifier).add(loan);
    }

    final msg = _isEditing ? 'Loan updated!' : 'Loan saved!';
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
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

class _DatePicker extends StatelessWidget {
  final DateTime? date;
  final String? hint;
  final ValueChanged<DateTime> onPick;

  const _DatePicker({this.date, this.hint, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        width: double.infinity,
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
              date != null
                  ? '${date!.day}/${date!.month}/${date!.year}'
                  : (hint ?? 'Select date'),
              style: TextStyle(
                color: date != null ? Colors.white : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

