import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/loan_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';

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
          padding: const EdgeInsets.all(AppTheme.xl),
          children: [
            // Type toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(AppTheme.lg),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  TypeToggleTab(
                    label: 'I Borrowed',
                    icon: Icons.arrow_downward_rounded,
                    color: AppTheme.loanTakenColor,
                    isSelected: _type == LoanType.taken,
                    onTap: () => setState(() => _type = LoanType.taken),
                  ),
                  TypeToggleTab(
                    label: 'I Lent',
                    icon: Icons.arrow_upward_rounded,
                    color: AppTheme.loanGivenColor,
                    isSelected: _type == LoanType.given,
                    onTap: () => setState(() => _type = LoanType.given),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.xxl),

            Text('Person Name', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
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
            const SizedBox(height: AppTheme.lg),

            Text('Contact (optional)', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            TextFormField(
              controller: _personContactCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Phone number'),
            ),
            const SizedBox(height: AppTheme.xl),

            Text('Principal Amount', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            TextFormField(
              controller: _principalCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: AppTheme.amountLarge.copyWith(fontSize: 24),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: AppTheme.amountLarge.copyWith(fontSize: 24),
                hintText: '0.00',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                if (double.tryParse(v) == null || double.parse(v) <= 0)
                  return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: AppTheme.xl),

            Text('Interest Rate (% per annum)', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            TextFormField(
              controller: _rateCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(suffixText: '%', hintText: '0.00'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter rate';
                if (double.tryParse(v) == null) return 'Invalid rate';
                return null;
              },
            ),
            const SizedBox(height: AppTheme.xl),

            Text('Interest Type', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            Row(
              children: InterestType.values.map((t) {
                final selected = _interestType == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _interestType = t),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: t == InterestType.simple ? AppTheme.sm : 0,
                          left: t == InterestType.compound ? AppTheme.sm : 0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.accent1.withOpacity(0.15)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(AppTheme.md),
                        border: Border.all(
                          color: selected ? AppTheme.accent1 : Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          t == InterestType.simple ? 'Simple' : 'Compound',
                          style: AppTheme.titleMedium.copyWith(
                            color: selected ? AppTheme.accent1 : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.xl),

            if (_interestType == InterestType.compound) ...[
              Text('Compounding Period', style: formLabelStyle),
              const SizedBox(height: AppTheme.sm),
              Wrap(
                spacing: AppTheme.sm,
                children: InterestPeriod.values.map((p) {
                  final selected = _interestPeriod == p;
                  return ChoiceChip(
                    label: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                    selected: selected,
                    onSelected: (v) {
                      if (v) setState(() => _interestPeriod = p);
                    },
                    selectedColor: AppTheme.accent1.withOpacity(0.3),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.xl),
            ],

            Text('Start Date', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            GlassDatePickerButton(
              icon: Icons.calendar_today_rounded,
              text: '${_startDate.day}/${_startDate.month}/${_startDate.year}',
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            const SizedBox(height: AppTheme.xl),

            Text('Expected End Date (optional)', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            GlassDatePickerButton(
              icon: Icons.calendar_today_rounded,
              text: _endDate != null
                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                  : 'Select end date',
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
            ),
            const SizedBox(height: AppTheme.xl),

            Text('Notes (optional)', style: formLabelStyle),
            const SizedBox(height: AppTheme.sm),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Any notes...'),
            ),
            const SizedBox(height: AppTheme.xxxl),

            FullWidthButton(
              label: _isEditing ? 'Update Loan' : 'Save Loan',
              onPressed: _isSaving ? null : _save,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
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
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }
  }
}
