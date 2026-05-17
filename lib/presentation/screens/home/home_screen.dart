import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/shared_widgets.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _GreetingHeader()),
          SliverToBoxAdapter(child: _TodayHeroCard()),
          SliverToBoxAdapter(child: _MonthlyMetricsRow()),
          SliverToBoxAdapter(child: _LoansMetricsRow()),
          SliverToBoxAdapter(child: _SavingsBanner()),
          _MindSpacePreview(),
          _RecentTransactionsSection(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── Greeting Header ──

class _GreetingHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.xl, AppTheme.xl, AppTheme.xl, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textSecondary)),
                const SizedBox(height: AppTheme.xs),
                Text(userName, style: AppTheme.headlineMedium),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.settings_rounded,
            color: AppTheme.textSecondary,
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    if (hour < 21) return 'Good Evening 🌇';
    return 'Good Night 🌙';
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ── Today's Hero Card ──

class _TodayHeroCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayIncome = ref.watch(todayIncomeProvider);
    final todayExpense = ref.watch(todayExpenseProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.xl, AppTheme.xxl, AppTheme.xl, 0),
      child: HeroAccentCard(
        color: AppTheme.accent1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Overview",
                    style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.backgroundDark.withOpacity(0.6),
                    )),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: AppTheme.xs),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.xl),
                  ),
                  child: Text(
                    AppConstants.formatDateShort(DateTime.now()),
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.backgroundDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              AppConstants.formatCurrency(todayIncome - todayExpense),
              style: AppTheme.amountLarge
                  .copyWith(color: AppTheme.backgroundDark),
            ),
            Text('Net Balance Today',
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.backgroundDark.withOpacity(0.5),
                )),
            const SizedBox(height: AppTheme.xl),
            Row(
              children: [
                _HeroMiniStat(
                  icon: Icons.south_west_rounded,
                  label: 'Income',
                  value: AppConstants.formatCurrencyShort(todayIncome),
                ),
                const SizedBox(width: AppTheme.xxl),
                _HeroMiniStat(
                  icon: Icons.north_east_rounded,
                  label: 'Expense',
                  value: AppConstants.formatCurrencyShort(todayExpense),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.sm),
            ),
            child: Icon(icon, color: AppTheme.backgroundDark, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.backgroundDark.withOpacity(0.5),
                  )),
              Text(value,
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.backgroundDark,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Monthly Metrics Row ──

class _MonthlyMetricsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthIncome = ref.watch(monthIncomeProvider);
    final monthExpense = ref.watch(monthExpenseProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.xl, AppTheme.lg, AppTheme.xl, 0),
      child: Row(
        children: [
          MetricCard(
            label: 'This Month Income',
            value: AppConstants.formatCurrencyShort(monthIncome),
            icon: Icons.trending_up_rounded,
            color: AppTheme.incomeColor,
          ),
          const SizedBox(width: AppTheme.md),
          MetricCard(
            label: 'This Month Expense',
            value: AppConstants.formatCurrencyShort(monthExpense),
            icon: Icons.trending_down_rounded,
            color: AppTheme.expenseColor,
          ),
        ],
      ),
    );
  }
}

// ── Loans Metrics Row ──

class _LoansMetricsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansTakenDue = ref.watch(totalLoansTakenDueProvider);
    final loansGivenDue = ref.watch(totalLoansGivenDueProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.xl, AppTheme.md, AppTheme.xl, 0),
      child: Row(
        children: [
          MetricCard(
            label: 'Loans Due',
            value: AppConstants.formatCurrencyShort(loansTakenDue),
            icon: Icons.warning_amber_rounded,
            color: AppTheme.loanTakenColor,
          ),
          const SizedBox(width: AppTheme.md),
          MetricCard(
            label: 'To Collect',
            value: AppConstants.formatCurrencyShort(loansGivenDue),
            icon: Icons.call_received_rounded,
            color: AppTheme.loanGivenColor,
          ),
        ],
      ),
    );
  }
}

// ── Savings Banner ──

class _SavingsBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSaved = ref.watch(totalSavedProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.xl, AppTheme.md, AppTheme.xl, 0),
      child: GradientBanner(
        onTap: () => context.go('/savings'),
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Saved',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.backgroundDark.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: AppTheme.xs),
                  Text(
                    AppConstants.formatCurrency(totalSaved),
                    style: AppTheme.headlineMedium.copyWith(
                      color: AppTheme.backgroundDark,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.savings_rounded,
                  color: AppTheme.backgroundDark, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mind Space Preview ──

class _MindSpacePreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingMind = ref.watch(pendingMindItemsProvider);

    if (pendingMind.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.xl, AppTheme.xxl, AppTheme.xl, AppTheme.md),
            child: SectionHeader(
              title: 'Mind Space',
              actionText: 'View All',
              onAction: () => context.go('/mindspace'),
            ),
          ),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.lg),
              itemCount: pendingMind.take(5).length,
              itemBuilder: (context, i) {
                final item = pendingMind[i];
                final color = priorityColorMap[item.priority.name] ??
                    AppTheme.accent2;
                return _MindPreviewChip(
                  title: item.title,
                  description: item.description,
                  color: color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MindPreviewChip extends StatelessWidget {
  final String title;
  final String? description;
  final Color color;

  const _MindPreviewChip({
    required this.title,
    this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.lg, vertical: AppTheme.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: AppTheme.labelMedium
                  .copyWith(fontWeight: FontWeight.w600, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (description != null)
            Text(description!,
                style: AppTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Recent Transactions ──

class _RecentTransactionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTxns = ref.watch(transactionProvider);
    final recent = recentTxns.take(5).toList();

    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.xl, AppTheme.xxl, AppTheme.xl, AppTheme.md),
            child: SectionHeader(
              title: 'Recent Transactions',
              actionText: 'See All',
              onAction: () => context.go('/transactions'),
            ),
          ),
          if (recent.isEmpty)
            const EmptyStateWidget(
              icon: Icons.receipt_long_rounded,
              title: 'No transactions yet',
              subtitle: 'Tap + to add your first transaction',
              iconSize: 64,
            )
          else
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.xl),
              child: GlassCard(
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.sm),
                child: Column(
                  children:
                      recent.map((txn) => _RecentTxnTile(txn: txn)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentTxnTile extends StatelessWidget {
  final TransactionModel txn;
  const _RecentTxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isExpense = txn.type == TransactionType.expense;
    final color = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;
    final sign = isExpense ? '-' : '+';

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.lg, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.md),
            ),
            child: Icon(
              isExpense
                  ? Icons.north_east_rounded
                  : Icons.south_west_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.description,
                    style: AppTheme.titleMedium.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${txn.tags.isNotEmpty ? txn.tags.first : ''} • ${AppConstants.formatDateShort(txn.dateTime)}',
                  style: AppTheme.labelSmall,
                ),
              ],
            ),
          ),
          Text(
            '$sign${AppConstants.formatCurrency(txn.amount)}',
            style: AppTheme.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

