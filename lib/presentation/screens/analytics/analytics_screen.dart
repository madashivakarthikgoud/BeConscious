import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedPeriod = 1;

  @override
  Widget build(BuildContext context) {
    final allTxns = ref.watch(transactionProvider);
    final lifeIn = ref.watch(lifetimeIncomeProvider);
    final lifeEx = ref.watch(lifetimeExpenseProvider);

    double income, expense;
    String periodLabel;
    List<TransactionModel> periodTxns;

    switch (_selectedPeriod) {
      case 0:
        income = ref.watch(todayIncomeProvider);
        expense = ref.watch(todayExpenseProvider);
        periodLabel = 'Today';
        periodTxns = ref.watch(todayTransactionsProvider);
        break;
      case 1:
        income = ref.watch(monthIncomeProvider);
        expense = ref.watch(monthExpenseProvider);
        periodLabel = 'This Month';
        periodTxns = ref.watch(thisMonthTransactionsProvider);
        break;
      case 2:
        income = ref.watch(yearIncomeProvider);
        expense = ref.watch(yearExpenseProvider);
        periodLabel = 'This Year';
        periodTxns = ref.watch(thisYearTransactionsProvider);
        break;
      default:
        income = lifeIn;
        expense = lifeEx;
        periodLabel = 'Lifetime';
        periodTxns = allTxns;
    }

    final net = income - expense;

    final tagExpenses = <String, double>{};
    for (final t in periodTxns.where((t) => t.type == TransactionType.expense)) {
      for (final tag in t.tags) {
        tagExpenses[tag] = (tagExpenses[tag] ?? 0) + t.amount;
      }
      if (t.tags.isEmpty) {
        tagExpenses['Untagged'] = (tagExpenses['Untagged'] ?? 0) + t.amount;
      }
    }
    final sortedTags = tagExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final personExpenses = <String, double>{};
    for (final t in periodTxns.where((t) => t.type == TransactionType.expense)) {
      personExpenses[t.moneySourcePerson] =
          (personExpenses[t.moneySourcePerson] ?? 0) + t.amount;
    }
    final sortedPersons = personExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final now = DateTime.now();
    final weeklyData = <DateTime, double>{};
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      weeklyData[day] = 0;
    }
    for (final t in allTxns.where((t) => t.type == TransactionType.expense)) {
      final dayKey = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
      if (weeklyData.containsKey(dayKey)) {
        weeklyData[dayKey] = weeklyData[dayKey]! + t.amount;
      }
    }
    final weeklyEntries = weeklyData.entries.toList();

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.xl, AppTheme.lg, AppTheme.xl, 0),
              child: Text('Analytics', style: AppTheme.headlineMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.xl, AppTheme.lg, AppTheme.xl, 0),
              child: Row(
                children: ['Today', 'Month', 'Year', 'Lifetime']
                    .asMap()
                    .entries
                    .map((e) => Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPeriod = e.key),
                            child: Container(
                              margin: EdgeInsets.only(right: e.key < 3 ? AppTheme.sm : 0),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedPeriod == e.key
                                    ? AppTheme.accent1
                                    : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  e.value,
                                  style: AppTheme.labelSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _selectedPeriod == e.key
                                        ? AppTheme.backgroundDark
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.xl),
              child: Column(
                children: [
                  Row(
                    children: [
                      _SummaryTile(
                        label: 'Income',
                        amount: income,
                        color: AppTheme.incomeColor,
                        icon: Icons.arrow_downward_rounded,
                      ),
                      const SizedBox(width: AppTheme.md),
                      _SummaryTile(
                        label: 'Expense',
                        amount: expense,
                        color: AppTheme.expenseColor,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.md),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.xl),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: (net >= 0
                                    ? AppTheme.incomeColor
                                    : AppTheme.expenseColor)
                                .withOpacity(0.15),
                            child: Icon(
                              net >= 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: net >= 0
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor,
                            ),
                          ),
                          const SizedBox(width: AppTheme.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Net ($periodLabel)',
                                    style: AppTheme.labelSmall.copyWith(
                                        color: AppTheme.textSecondary)),
                                Text(
                                  AppConstants.formatCurrency(net),
                                  style: AppTheme.headlineMedium.copyWith(
                                    fontSize: 22,
                                    color: net >= 0
                                        ? AppTheme.incomeColor
                                        : AppTheme.expenseColor,
                                  ),
                                ),
                              ],
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
          if (sortedTags.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expense by Category ($periodLabel)', style: AppTheme.titleLarge),
                    const SizedBox(height: AppTheme.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.lg),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections: sortedTags
                                      .take(8)
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map((e) {
                                    final pct = expense > 0
                                        ? (e.value.value / expense * 100)
                                        : 0.0;
                                    return PieChartSectionData(
                                      color: chartColors[e.key % chartColors.length],
                                      value: e.value.value,
                                      title: '',
                                      radius: 45,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.lg),
                            ...sortedTags.take(8).toList().asMap().entries.map(
                              (e) {
                                final pct = expense > 0
                                    ? (e.value.value / expense * 100)
                                    : 0.0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AppTheme.xs),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: chartColors[e.key % chartColors.length],
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(e.value.key,
                                              style: AppTheme.bodyMedium.copyWith(fontSize: 13))),
                                      Text(
                                        '${pct.toStringAsFixed(1)}%',
                                        style: AppTheme.labelMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        AppConstants.formatCurrency(e.value.value),
                                        style: AppTheme.labelMedium.copyWith(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (sortedPersons.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spent From (Whose Money)', style: AppTheme.titleLarge),
                    const SizedBox(height: AppTheme.md),
                    ...sortedPersons.map((e) {
                      final pct = expense > 0 ? e.value / expense : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.sm),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key,
                                        style: AppTheme.titleMedium),
                                    Text(
                                      AppConstants.formatCurrency(e.value),
                                      style: AppTheme.labelLarge.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.expenseColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.sm),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor: Colors.white.withOpacity(0.06),
                                    color: AppTheme.accent1,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.xs),
                                Text(
                                  '${(pct * 100).toInt()}% of total',
                                  style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          if (weeklyEntries.any((e) => e.value > 0))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This Week\'s Expenses', style: AppTheme.titleLarge),
                    const SizedBox(height: AppTheme.md),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.lg),
                        child: SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              barGroups: weeklyEntries
                                  .asMap()
                                  .entries
                                  .map((e) => BarChartGroupData(
                                        x: e.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: e.value.value,
                                            color: AppTheme.accent1,
                                            width: 20,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                          ),
                                        ],
                                      ))
                                  .toList(),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 36,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= weeklyEntries.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final date = weeklyEntries[idx].key;
                                      final dayLabel = DateFormat('E').format(date);
                                      final dateLabel = '${date.day}/${date.month}';
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(dayLabel,
                                              style: AppTheme.labelSmall.copyWith(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textSecondary)),
                                          Text(dateLabel,
                                              style: AppTheme.labelSmall.copyWith(
                                                  fontSize: 9,
                                                  color: AppTheme.textMuted)),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final date = weeklyEntries[group.x].key;
                                    return BarTooltipItem(
                                      '${DateFormat('MMM d').format(date)}\n${AppConstants.formatCurrency(rod.toY)}',
                                      AppTheme.labelSmall.copyWith(
                                          color: Colors.white, fontWeight: FontWeight.w700),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All-Time Summary', style: AppTheme.titleLarge),
                  const SizedBox(height: AppTheme.md),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.lg),
                      child: Column(
                        children: [
                          _SummaryRow('Total Transactions', '${allTxns.length}'),
                          const Divider(height: 16),
                          _SummaryRow('Lifetime Income',
                              AppConstants.formatCurrency(lifeIn),
                              color: AppTheme.incomeColor),
                          const Divider(height: 16),
                          _SummaryRow('Lifetime Expenses',
                              AppConstants.formatCurrency(lifeEx),
                              color: AppTheme.expenseColor),
                          const Divider(height: 16),
                          _SummaryRow('Net Worth',
                              AppConstants.formatCurrency(lifeIn - lifeEx),
                              color: (lifeIn - lifeEx) >= 0
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(label, style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: AppTheme.sm),
              Text(
                AppConstants.formatCurrency(amount),
                style: AppTheme.amountMedium.copyWith(color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.labelMedium.copyWith(color: AppTheme.textSecondary)),
        Text(
          value,
          style: AppTheme.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
