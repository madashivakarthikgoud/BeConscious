import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/app_providers.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedPeriod = 1; // 0=today, 1=month, 2=year, 3=lifetime

  @override
  Widget build(BuildContext context) {
    final todayIn = ref.watch(todayIncomeProvider);
    final todayEx = ref.watch(todayExpenseProvider);
    final monthIn = ref.watch(monthIncomeProvider);
    final monthEx = ref.watch(monthExpenseProvider);
    final yearIn = ref.watch(yearIncomeProvider);
    final yearEx = ref.watch(yearExpenseProvider);
    final lifeIn = ref.watch(lifetimeIncomeProvider);
    final lifeEx = ref.watch(lifetimeExpenseProvider);
    final allTxns = ref.watch(transactionProvider);

    double income, expense;
    String periodLabel;
    List<TransactionModel> periodTxns;

    switch (_selectedPeriod) {
      case 0:
        income = todayIn;
        expense = todayEx;
        periodLabel = 'Today';
        periodTxns = ref.watch(todayTransactionsProvider);
        break;
      case 1:
        income = monthIn;
        expense = monthEx;
        periodLabel = 'This Month';
        periodTxns = ref.watch(thisMonthTransactionsProvider);
        break;
      case 2:
        income = yearIn;
        expense = yearEx;
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

    // Tag breakdown for expenses
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

    // Person breakdown
    final personExpenses = <String, double>{};
    for (final t in periodTxns.where((t) => t.type == TransactionType.expense)) {
      personExpenses[t.moneySourcePerson] =
          (personExpenses[t.moneySourcePerson] ?? 0) + t.amount;
    }
    final sortedPersons = personExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Daily trend for month view
    final dailyData = <int, double>{};
    if (_selectedPeriod == 1) {
      for (final t
          in periodTxns.where((t) => t.type == TransactionType.expense)) {
        final day = t.dateTime.day;
        dailyData[day] = (dailyData[day] ?? 0) + t.amount;
      }
    }

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Analytics',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Period selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: ['Today', 'Month', 'Year', 'Lifetime']
                    .asMap()
                    .entries
                    .map((e) => Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedPeriod = e.key),
                            child: Container(
                              margin: EdgeInsets.only(
                                  right: e.key < 3 ? 8 : 0),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedPeriod == e.key
                                    ? AppTheme.primaryColor
                                    : AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedPeriod == e.key
                                        ? Colors.white
                                        : Colors.white54,
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

          // Summary cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                      const SizedBox(width: 12),
                      _SummaryTile(
                        label: 'Expense',
                        amount: expense,
                        color: AppTheme.expenseColor,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Net ($periodLabel)',
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 12)),
                                Text(
                                  AppConstants.formatCurrency(net),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
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

          // Pie chart - expense by tag
          if (sortedTags.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expense by Category',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                                    final colors = [
                                      AppTheme.primaryColor,
                                      AppTheme.expenseColor,
                                      AppTheme.incomeColor,
                                      AppTheme.loanTakenColor,
                                      AppTheme.loanGivenColor,
                                      AppTheme.savingsColor,
                                      Colors.cyan,
                                      Colors.amber,
                                    ];
                                    return PieChartSectionData(
                                      color: colors[e.key % colors.length],
                                      value: e.value.value,
                                      title: expense > 0
                                          ? '${(e.value.value / expense * 100).toInt()}%'
                                          : '0%',
                                      radius: 45,
                                      titleStyle: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...sortedTags.take(8).toList().asMap().entries.map(
                              (e) {
                                final colors = [
                                  AppTheme.primaryColor,
                                  AppTheme.expenseColor,
                                  AppTheme.incomeColor,
                                  AppTheme.loanTakenColor,
                                  AppTheme.loanGivenColor,
                                  AppTheme.savingsColor,
                                  Colors.cyan,
                                  Colors.amber,
                                ];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color:
                                              colors[e.key % colors.length],
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(e.value.key,
                                              style: const TextStyle(
                                                  fontSize: 13))),
                                      Text(
                                        AppConstants.formatCurrency(
                                            e.value.value),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
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

          // Person breakdown
          if (sortedPersons.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spent From (Whose Money)',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...sortedPersons.map((e) {
                      final pct = expense > 0 ? e.value / expense : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                      AppConstants.formatCurrency(e.value),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.expenseColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor: Colors.white12,
                                    color: AppTheme.primaryColor,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(pct * 100).toInt()}% of total',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.white38),
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

          // Daily expense trend (month only)
          if (_selectedPeriod == 1 && dailyData.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Expense Trend',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              barGroups: List.generate(
                                DateTime.now().day,
                                (i) => BarChartGroupData(
                                  x: i + 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: dailyData[i + 1] ?? 0,
                                      color: AppTheme.primaryColor,
                                      width: 8,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() % 5 == 0 ||
                                          value.toInt() == 1) {
                                        return Text(
                                          '${value.toInt()}',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white38),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // All-time summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All-Time Summary',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _SummaryRow('Total Transactions',
                              '${allTxns.length}'),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.formatCurrency(amount),
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }
}

