import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/loan_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/shared_widgets.dart';

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
          ScreenHeader(
            title: 'Loans',
            trailing: IconButton(
              onPressed: () => context.push('/add-loan'),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: AppTheme.sm),

          // Summary cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
            child: Row(
              children: [
                MetricCard(
                  label: 'You Owe',
                  value: AppConstants.formatCurrencyShort(taken
                      .where((l) => l.status == LoanStatus.active)
                      .fold(0.0, (sum, l) => sum + l.totalDueNow)),
                  icon: Icons.arrow_upward_rounded,
                  color: AppTheme.loanTakenColor,
                ),
                const SizedBox(width: AppTheme.md),
                MetricCard(
                  label: "You're Owed",
                  value: AppConstants.formatCurrencyShort(given
                      .where((l) => l.status == LoanStatus.active)
                      .fold(0.0, (sum, l) => sum + l.totalDueNow)),
                  icon: Icons.arrow_downward_rounded,
                  color: AppTheme.loanGivenColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.lg),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppTheme.lg),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: AppTheme.accent1,
                borderRadius: BorderRadius.circular(AppTheme.lg),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppTheme.backgroundDark,
              unselectedLabelColor: AppTheme.textSecondary,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Borrowed (${taken.length})'),
                Tab(text: 'Lent (${given.length})'),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.md),

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


class _LoanList extends StatelessWidget {
  final List<LoanModel> loans;
  const _LoanList({required this.loans});

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.handshake_rounded,
        title: 'No loans yet',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: loans.length,
      itemBuilder: (context, index) => _LoanCard(loan: loans[index]),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanModel loan;
  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final isTaken = loan.type == LoanType.taken;
    final color = isTaken ? AppTheme.loanTakenColor : AppTheme.loanGivenColor;

    String statusLabel;
    Color statusColor;
    switch (loan.status) {
      case LoanStatus.active:
        statusColor = AppTheme.loanTakenColor;
        statusLabel = 'Active';
        break;
      case LoanStatus.completed:
        statusColor = AppTheme.incomeColor;
        statusLabel = 'Completed';
        break;
      case LoanStatus.overdue:
        statusColor = AppTheme.expenseColor;
        statusLabel = 'Overdue';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.lg, vertical: AppTheme.xs),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/loan-detail/${loan.id}'),
          borderRadius: BorderRadius.circular(AppTheme.lg),
          child: Padding(
            padding: AppTheme.cardPaddingCompact,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LoanCardHeader(loan: loan, color: color, statusLabel: statusLabel, statusColor: statusColor),
                const SizedBox(height: 14),
                _LoanCardStats(loan: loan, color: color),
                const SizedBox(height: AppTheme.sm),
                if (loan.principalAmount + loan.currentInterest > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.xs),
                    child: LinearProgressIndicator(
                      value: (loan.totalPaid /
                              (loan.principalAmount + loan.currentInterest))
                          .clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withOpacity(0.06),
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
  }
}

class _LoanCardHeader extends StatelessWidget {
  final LoanModel loan;
  final Color color;
  final String statusLabel;
  final Color statusColor;

  const _LoanCardHeader({
    required this.loan,
    required this.color,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.15),
          child: Text(
            loan.personName.isNotEmpty
                ? loan.personName[0].toUpperCase()
                : '?',
            style: AppTheme.amountMedium.copyWith(color: color),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loan.personName, style: AppTheme.titleMedium,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                '${loan.interestRate}% ${loan.interestType == InterestType.simple ? "SI" : "CI"} • ${loan.interestPeriod.name}',
                style: AppTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        StatusBadge(label: statusLabel, color: statusColor),
      ],
    );
  }
}

class _LoanCardStats extends StatelessWidget {
  final LoanModel loan;
  final Color color;
  const _LoanCardStats({required this.loan, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LoanStat(label: 'Principal', value: AppConstants.formatCurrencyShort(loan.principalAmount)),
        _LoanStat(label: 'Interest', value: AppConstants.formatCurrencyShort(loan.currentInterest)),
        _LoanStat(label: 'Due Now', value: AppConstants.formatCurrencyShort(loan.totalDueNow), valueColor: color),
        _LoanStat(label: 'Paid', value: AppConstants.formatCurrencyShort(loan.totalPaid), valueColor: AppTheme.incomeColor),
      ],
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
          Text(label, style: AppTheme.labelSmall.copyWith(fontSize: 10),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.labelMedium.copyWith(
              color: valueColor ?? Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


