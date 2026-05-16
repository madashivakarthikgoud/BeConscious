import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/savings_model.dart';
import '../../providers/app_providers.dart';

class SavingsDetailScreen extends ConsumerWidget {
  final String goalId;
  const SavingsDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsProvider);
    final goal = goals.where((g) => g.id == goalId).firstOrNull;

    if (goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal Details')),
        body: const Center(child: Text('Goal not found')),
      );
    }

    final color = Color(goal.colorValue);
    final percent = goal.progressPercent;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () =>
                context.push('/add-savings', extra: {'goal': goal}),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Goal?'),
                  content: const Text('This will delete the savings goal and all contributions.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(savingsProvider.notifier).delete(goal.id);
                        Navigator.pop(ctx);
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.expenseColor),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addContribution(context, ref, goal),
        icon: const Icon(Icons.add),
        label: const Text('Add Money'),
        backgroundColor: color,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Progress card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircularPercentIndicator(
                    radius: 70,
                    lineWidth: 10,
                    percent: percent,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(percent * 100).toInt()}%',
                          style: TextStyle(
                            color: color,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('saved',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                    progressColor: color,
                    backgroundColor: color.withOpacity(0.15),
                    circularStrokeCap: CircularStrokeCap.round,
                    animation: true,
                    animationDuration: 800,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppConstants.formatCurrency(goal.totalSaved),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'of ${AppConstants.formatCurrency(goal.targetAmount)}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              _Stat(
                label: 'Remaining',
                value: AppConstants.formatCurrencyShort(goal.remainingAmount),
                icon: Icons.flag_rounded,
                color: color,
              ),
              const SizedBox(width: 12),
              _Stat(
                label: 'Days Left',
                value: '${goal.daysRemaining}',
                icon: Icons.timer_rounded,
                color: AppTheme.loanTakenColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(
                label: 'Need/Day',
                value: AppConstants.formatCurrencyShort(goal.requiredPerDay),
                icon: Icons.today_rounded,
                color: AppTheme.loanGivenColor,
              ),
              const SizedBox(width: 12),
              _Stat(
                label: 'Need/Month',
                value: AppConstants.formatCurrencyShort(goal.requiredPerMonth),
                icon: Icons.calendar_month_rounded,
                color: AppTheme.savingsColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.1),
                child: const Icon(Icons.event_rounded, size: 20),
              ),
              title: const Text('Deadline',
                  style: TextStyle(fontSize: 13, color: Colors.white54)),
              trailing: Text(
                AppConstants.formatDate(goal.deadline),
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Contributions
          Text('Contributions (${goal.contributions.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (goal.contributions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.savings_rounded,
                          size: 48, color: Colors.white12),
                      const SizedBox(height: 12),
                      const Text('No contributions yet',
                          style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                ),
              ),
            )
          else
            ...goal.contributions.reversed.map((c) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child:
                          Icon(Icons.add_rounded, color: color, size: 20),
                    ),
                    title: Text(
                      AppConstants.formatCurrency(c.amount),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: color),
                    ),
                    subtitle: Text(
                      AppConstants.formatDate(c.date),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white38),
                    ),
                    trailing: c.notes != null
                        ? Text(c.notes!,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white24))
                        : null,
                  ),
                )),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _addContribution(
      BuildContext context, WidgetRef ref, SavingsGoalModel goal) {
    final ctrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Add Money to "${goal.name}"',
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Remaining: ${AppConstants.formatCurrency(goal.remainingAmount)}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              autofocus: true,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                prefixStyle:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(hintText: 'Notes (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(ctrl.text);
                  if (amount == null || amount <= 0) return;

                  ref.read(savingsProvider.notifier).addContribution(
                        goal.id,
                        SavingsContribution(
                          id: const Uuid().v4(),
                          amount: amount,
                          date: DateTime.now(),
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        ),
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${AppConstants.formatCurrency(amount)} added to ${goal.name}!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(goal.colorValue),
                ),
                child: const Text('Add Contribution'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white38)),
                    Text(value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

