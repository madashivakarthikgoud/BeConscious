import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/savings_model.dart';
import '../../providers/app_providers.dart';

class AddSavingsScreen extends ConsumerStatefulWidget {
  final SavingsGoalModel? editGoal;
  const AddSavingsScreen({super.key, this.editGoal});

  @override
  ConsumerState<AddSavingsScreen> createState() => _AddSavingsScreenState();
}

class _AddSavingsScreenState extends ConsumerState<AddSavingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 90));
  int _selectedColorIndex = 0;
  bool _isSaving = false;

  final _colors = [
    0xFF4CAF50, 0xFF2196F3, 0xFF9C27B0, 0xFFFF9800,
    0xFFE91E63, 0xFF00BCD4, 0xFFFF5722, 0xFF607D8B,
  ];

  bool get _isEditing => widget.editGoal != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final g = widget.editGoal!;
      _nameCtrl.text = g.name;
      _targetCtrl.text = g.targetAmount.toStringAsFixed(2);
      _deadline = g.deadline;
      final colorIdx = _colors.indexOf(g.colorValue);
      _selectedColorIndex = colorIdx >= 0 ? colorIdx : 0;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Goal' : 'New Savings Goal'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            Text('Goal Name', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  hintText: 'e.g. Emergency Fund, Vacation'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: 20),

            Text('Target Amount', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _targetCtrl,
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

            Text('Deadline', style: _labelStyle),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _deadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _deadline = d);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(
                        '${_deadline.day}/${_deadline.month}/${_deadline.year}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('Color', style: _labelStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_colors.length, (i) {
                final c = Color(_colors[i]);
                final selected = _selectedColorIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = i),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Update Goal' : 'Create Goal'),
              ),
            ),
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

    final goal = SavingsGoalModel(
      id: _isEditing ? widget.editGoal!.id : const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      targetAmount: double.parse(_targetCtrl.text),
      deadline: _deadline,
      contributions: _isEditing ? widget.editGoal!.contributions : [],
      colorValue: _colors[_selectedColorIndex],
    );

    if (_isEditing) {
      ref.read(savingsProvider.notifier).update(goal);
    } else {
      ref.read(savingsProvider.notifier).add(goal);
    }

    final msg = _isEditing ? 'Goal updated!' : 'Goal created!';
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }
}

