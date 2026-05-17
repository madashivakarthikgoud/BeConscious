import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/pop_calculator.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayIncome = ref.watch(todayIncomeProvider);
    final todayExpense = ref.watch(todayExpenseProvider);
    final monthIncome = ref.watch(monthIncomeProvider);
    final monthExpense = ref.watch(monthExpenseProvider);
    final loansTakenDue = ref.watch(totalLoansTakenDueProvider);
    final loansGivenDue = ref.watch(totalLoansGivenDueProvider);
    final totalSaved = ref.watch(totalSavedProvider);
    final recentTxns = ref.watch(transactionProvider);
    final recent = recentTxns.take(5).toList();
    final pendingMind = ref.watch(pendingMindItemsProvider);
    final userName = ref.watch(userNameProvider);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Greeting
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => PopCalculator.show(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent2.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.accent2.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.calculate_rounded,
                          color: AppTheme.accent2, size: 20),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: const Icon(Icons.settings_rounded,
                          color: AppTheme.textSecondary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── BENTO GRID: Hero card (Template A) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: HeroAccentCard(
                color: AppTheme.accent1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Overview",
                          style: TextStyle(
                            color: AppTheme.backgroundDark.withOpacity(0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundDark.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppConstants.formatDateShort(DateTime.now()),
                            style: TextStyle(
                              color: AppTheme.backgroundDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppConstants.formatCurrency(todayIncome - todayExpense),
                      style: TextStyle(
                        color: AppTheme.backgroundDark,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Net Balance Today',
                      style: TextStyle(
                        color: AppTheme.backgroundDark.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _HeroMiniStat(
                          icon: Icons.south_west_rounded,
                          label: 'Income',
                          value: AppConstants.formatCurrencyShort(todayIncome),
                        ),
                        const SizedBox(width: 24),
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
            ),
          ),

          // ── Template B: Twin metric cards ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.incomeColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.trending_up_rounded,
                                    color: AppTheme.incomeColor, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text('Income',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppConstants.formatCurrencyShort(monthIncome),
                            style: const TextStyle(
                              color: AppTheme.incomeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text('This Month',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.expenseColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.trending_down_rounded,
                                    color: AppTheme.expenseColor, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text('Expense',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppConstants.formatCurrencyShort(monthExpense),
                            style: const TextStyle(
                              color: AppTheme.expenseColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text('This Month',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Template B: Loans & Savings twin ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.loanTakenColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.warning_amber_rounded,
                                    color: AppTheme.loanTakenColor, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('Loans Due',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary, fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppConstants.formatCurrencyShort(loansTakenDue),
                            style: const TextStyle(
                              color: AppTheme.loanTakenColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.loanGivenColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.call_received_rounded,
                                    color: AppTheme.loanGivenColor, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('To Collect',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary, fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppConstants.formatCurrencyShort(loansGivenDue),
                            style: const TextStyle(
                              color: AppTheme.loanGivenColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Template D: Savings promo banner ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GradientBanner(
                onTap: () => context.go('/savings'),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Saved',
                            style: TextStyle(
                              color: AppTheme.backgroundDark.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppConstants.formatCurrency(totalSaved),
                            style: TextStyle(
                              color: AppTheme.backgroundDark,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
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
                      child: Icon(Icons.savings_rounded,
                          color: AppTheme.backgroundDark, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Mind Space preview ──
          if (pendingMind.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: SectionHeader(
                  title: 'Mind Space',
                  actionText: 'View All',
                  onAction: () => context.go('/mindspace'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: pendingMind.take(5).length,
                  itemBuilder: (context, i) {
                    final item = pendingMind[i];
                    final colors = {
                      'low': AppTheme.incomeColor,
                      'medium': AppTheme.loanTakenColor,
                      'high': AppTheme.expenseColor,
                    };
                    final color = colors[item.priority.name] ?? AppTheme.accent2;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (item.description != null)
                            Text(item.description!,
                                style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // ── Template C: Recent transactions ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: SectionHeader(
                title: 'Recent Transactions',
                actionText: 'See All',
                onAction: () => context.go('/transactions'),
              ),
            ),
          ),

          if (recent.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 64, color: Colors.white.withOpacity(0.08)),
                      const SizedBox(height: 12),
                      const Text('No transactions yet',
                          style: TextStyle(color: AppTheme.textMuted)),
                      const SizedBox(height: 4),
                      const Text('Tap + to add your first transaction',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: recent.map((txn) {
                      final isExpense = txn.type == TransactionType.expense;
                      final color = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;
                      final sign = isExpense ? '-' : '+';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
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
                                  Text(
                                    txn.description,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${txn.tags.isNotEmpty ? txn.tags.first : ''} • ${AppConstants.formatDateShort(txn.dateTime)}',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$sign${AppConstants.formatCurrency(txn.amount)}',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    if (hour < 21) return 'Good Evening 🌇';
    return 'Good Night 🌙';
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.backgroundDark, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: AppTheme.backgroundDark.withOpacity(0.5),
                      fontSize: 11)),
              Text(value,
                  style: TextStyle(
                      color: AppTheme.backgroundDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

