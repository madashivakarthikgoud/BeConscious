import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/savings_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';

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
              padding: const EdgeInsets.fromLTRB(AppTheme.xl, AppTheme.lg, AppTheme.xl, 0),
              child: Row(
                children: [
                  Text(
                    'Savings Goals',
                    style: AppTheme.headlineMedium,
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
              padding: const EdgeInsets.all(AppTheme.xl),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.savingsColor,
                      AppTheme.savingsColor.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Saved',
                              style: AppTheme.labelSmall.copyWith(
                                  color: Colors.white70)),
                          const SizedBox(height: AppTheme.xs),
                          Text(
                            AppConstants.formatCurrency(totalSaved),
                            style: AppTheme.amountLarge.copyWith(
                              color: Colors.white,
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: AppTheme.xs),
                          Text(
                            '${goals.length} active goals',
                            style: AppTheme.labelSmall.copyWith(
                                color: Colors.white70),
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
              child: EmptyStateWidget(
                icon: Icons.savings_rounded,
                title: 'No savings goals yet',
                action: ElevatedButton(
                  onPressed: () => context.push('/add-savings'),
                  child: const Text('Create Goal'),
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
    final color = goal.colorValue != 0 ? Color(goal.colorValue) : AppTheme.savingsColor;
    final percent = goal.progressPercent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: AppTheme.xs),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/savings-detail/${goal.id}'),
          borderRadius: BorderRadius.circular(AppTheme.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.lg),
            child: Row(
              children: [
                CircularPercentIndicator(
                  radius: 34,
                  lineWidth: 5,
                  percent: percent,
                  center: Text(
                    '${(percent * 100).toInt()}%',
                    style: AppTheme.labelSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  progressColor: color,
                  backgroundColor: color.withOpacity(0.15),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(width: AppTheme.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name, style: AppTheme.titleMedium,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppTheme.xs),
                      Text(
                        '${AppConstants.formatCurrency(goal.totalSaved)} / ${AppConstants.formatCurrency(goal.targetAmount)}',
                        style: AppTheme.labelMedium.copyWith(color: color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.xs),
                      Wrap(
                        spacing: AppTheme.md,
                        runSpacing: AppTheme.xs,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined,
                                  size: 12, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${goal.daysRemaining} days left',
                                style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_up_rounded,
                                  size: 12, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${AppConstants.formatCurrency(goal.requiredPerDay)}/day',
                                style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

