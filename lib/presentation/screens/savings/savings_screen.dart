import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/savings_model.dart';
import '../../providers/app_providers.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsProvider);
    final totalSaved = ref.watch(totalSavedProvider);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Savings Goals',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.push('/add-savings'),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
          ),

          // Total saved summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.savingsColor,
                      AppTheme.savingsColor.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Saved',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            AppConstants.formatCurrency(totalSaved),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${goals.length} active goals',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.savings_rounded,
                          color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (goals.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.savings_rounded,
                        size: 80, color: Colors.white.withOpacity(0.06)),
                    const SizedBox(height: 16),
                    Text('No savings goals yet',
                        style: TextStyle(color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => context.push('/add-savings'),
                      child: const Text('Create Goal'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final goal = goals[index];
                  return _GoalCard(goal: goal);
                },
                childCount: goals.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final color = Color(goal.colorValue);
    final percent = goal.progressPercent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/savings-detail/${goal.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircularPercentIndicator(
                  radius: 34,
                  lineWidth: 5,
                  percent: percent,
                  center: Text(
                    '${(percent * 100).toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  progressColor: color,
                  backgroundColor: color.withOpacity(0.15),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppConstants.formatCurrency(goal.totalSaved)} / ${AppConstants.formatCurrency(goal.targetAmount)}',
                        style: TextStyle(color: color, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${goal.daysRemaining} days left',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.trending_up_rounded,
                              size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${AppConstants.formatCurrency(goal.requiredPerDay)}/day',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

