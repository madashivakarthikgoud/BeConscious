import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/loan_model.dart';
import '../../providers/app_providers.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loans = ref.watch(loanProvider);
    final taken = loans.where((l) => l.type == LoanType.taken).toList();
    final given = loans.where((l) => l.type == LoanType.given).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text(
                  'Loans',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => context.push('/add-loan'),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Summary cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _SummaryCard(
                  label: 'You Owe',
                  amount: taken
                      .where((l) => l.status == LoanStatus.active)
                      .fold(0.0, (sum, l) => sum + l.totalDueNow),
                  color: AppTheme.loanTakenColor,
                  icon: Icons.arrow_upward_rounded,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'You\'re Owed',
                  amount: given
                      .where((l) => l.status == LoanStatus.active)
                      .fold(0.0, (sum, l) => sum + l.totalDueNow),
                  color: AppTheme.loanGivenColor,
                  icon: Icons.arrow_downward_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Borrowed (${taken.length})'),
                Tab(text: 'Lent (${given.length})'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _LoanList(loans: taken),
                _LoanList(loans: given),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanList extends StatelessWidget {
  final List<LoanModel> loans;
  const _LoanList({required this.loans});

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_rounded, size: 64, color: Colors.white12),
            const SizedBox(height: 16),
            Text('No loans yet', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        final isTaken = loan.type == LoanType.taken;
        final color = isTaken ? AppTheme.loanTakenColor : AppTheme.loanGivenColor;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            child: InkWell(
              onTap: () => context.push('/loan-detail/${loan.id}'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: color.withOpacity(0.15),
                          child: Text(
                            loan.personName[0].toUpperCase(),
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan.personName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              Text(
                                '${loan.interestRate}% ${loan.interestType == InterestType.simple ? "Simple" : "Compound"} • ${loan.interestPeriod.name}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white38),
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: loan.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _LoanStat(
                          label: 'Principal',
                          value: AppConstants.formatCurrencyShort(
                              loan.principalAmount),
                        ),
                        _LoanStat(
                          label: 'Interest',
                          value: AppConstants.formatCurrencyShort(
                              loan.currentInterest),
                        ),
                        _LoanStat(
                          label: 'Due Now',
                          value: AppConstants.formatCurrencyShort(
                              loan.totalDueNow),
                          valueColor: color,
                        ),
                        _LoanStat(
                          label: 'Paid',
                          value: AppConstants.formatCurrencyShort(
                              loan.totalPaid),
                          valueColor: AppTheme.incomeColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    if (loan.principalAmount + loan.currentInterest > 0)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (loan.totalPaid /
                                  (loan.principalAmount + loan.currentInterest))
                              .clamp(0.0, 1.0),
                          backgroundColor: Colors.white12,
                          color: color,
                          minHeight: 4,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoanStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _LoanStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LoanStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case LoanStatus.active:
        color = AppTheme.loanTakenColor;
        label = 'Active';
        break;
      case LoanStatus.completed:
        color = AppTheme.incomeColor;
        label = 'Completed';
        break;
      case LoanStatus.overdue:
        color = AppTheme.expenseColor;
        label = 'Overdue';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

