import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/app_providers.dart';

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
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Shiva Karthik',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.settings_rounded),
                  ),
                ],
              ),
            ),
          ),

          // Today's Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Overview",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppConstants.formatDateShort(DateTime.now()),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppConstants.formatCurrency(todayIncome - todayExpense),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Net Balance Today',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _MiniStat(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Income',
                          value: AppConstants.formatCurrency(todayIncome),
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 20),
                        _MiniStat(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Expense',
                          value: AppConstants.formatCurrency(todayExpense),
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Monthly Overview
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Month',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        title: 'Income',
                        value: AppConstants.formatCurrencyShort(monthIncome),
                        icon: Icons.trending_up_rounded,
                        color: AppTheme.incomeColor,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        title: 'Expense',
                        value: AppConstants.formatCurrencyShort(monthExpense),
                        icon: Icons.trending_down_rounded,
                        color: AppTheme.expenseColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        title: 'Loans Due',
                        value: AppConstants.formatCurrencyShort(loansTakenDue),
                        icon: Icons.warning_rounded,
                        color: AppTheme.loanTakenColor,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        title: 'To Collect',
                        value: AppConstants.formatCurrencyShort(loansGivenDue),
                        icon: Icons.call_received_rounded,
                        color: AppTheme.loanGivenColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.savingsColor.withOpacity(0.2),
                        child: Icon(Icons.savings_rounded,
                            color: AppTheme.savingsColor),
                      ),
                      title: const Text('Total Saved'),
                      trailing: Text(
                        AppConstants.formatCurrency(totalSaved),
                        style: TextStyle(
                          color: AppTheme.savingsColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent Transactions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go('/transactions'),
                    child: const Text('See All'),
                  ),
                ],
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
                          size: 64, color: Colors.white24),
                      const SizedBox(height: 12),
                      Text(
                        'No transactions yet',
                        style: TextStyle(color: Colors.white38),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to add your first transaction',
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final txn = recent[index];
                  return _TransactionTile(txn: txn);
                },
                childCount: recent.length,
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

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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

class _TransactionTile extends StatelessWidget {
  final TransactionModel txn;
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isExpense = txn.type == TransactionType.expense;
    final color = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;
    final sign = isExpense ? '-' : '+';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(
              isExpense
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            txn.description,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${txn.tags.isNotEmpty ? txn.tags.first : ''} • ${txn.moneySourcePerson} • ${AppConstants.formatDateShort(txn.dateTime)}',
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
          trailing: Text(
            '$sign${AppConstants.formatCurrency(txn.amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

