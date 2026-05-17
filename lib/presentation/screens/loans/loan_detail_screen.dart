import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/loan_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';

class LoanDetailScreen extends ConsumerWidget {
  final String loanId;
  const LoanDetailScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(loanProvider);
    final loan = loans.where((l) => l.id == loanId).firstOrNull;

    if (loan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loan Details')),
        body: const EmptyStateWidget(
          icon: Icons.error_outline_rounded,
          title: 'Loan not found',
          subtitle: 'This loan may have been deleted.',
        ),
      );
    }

    final isTaken = loan.type == LoanType.taken;
    final color = isTaken ? AppTheme.loanTakenColor : AppTheme.loanGivenColor;
    final days = DateTime.now().difference(loan.startDate).inDays.clamp(0, 999999);

    return Scaffold(
      appBar: AppBar(
        title: Text(loan.personName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/add-loan', extra: {'loan': loan}),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: () => _confirmDelete(context, ref, loan),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.xl),
        children: [
          _LoanSummaryCard(loan: loan, color: color, isTaken: isTaken, days: days),
          const SizedBox(height: AppTheme.xl),
          _LoanBreakdownCard(loan: loan, color: color, isTaken: isTaken, days: days),
          const SizedBox(height: AppTheme.xl),
          if (loan.expectedEndDate != null) ...[
            _ExpectedTotalCard(loan: loan, color: color),
            const SizedBox(height: AppTheme.xl),
          ],
          _PaymentHistorySection(loan: loan, onAddPayment: () => _addPayment(context, ref, loan)),
          if (loan.notes != null && loan.notes!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.xl),
            Text('Notes', style: AppTheme.titleLarge),
            const SizedBox(height: AppTheme.sm),
            Card(
              child: Padding(
                padding: AppTheme.cardPaddingCompact,
                child: Text(loan.notes!, style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
              ),
            ),
          ],
          if (loan.status == LoanStatus.active) ...[
            const SizedBox(height: AppTheme.xxl),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(loanProvider.notifier).update(
                      loan.copyWith(status: LoanStatus.completed),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loan marked as completed!')),
                );
              },
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Mark as Completed'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.incomeColor,
                side: const BorderSide(color: AppTheme.incomeColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _addPayment(BuildContext context, WidgetRef ref, LoanModel loan) {
    final ctrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime payDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cornerRadiusSmall)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              AppTheme.xl, AppTheme.xl, AppTheme.xl, MediaQuery.of(ctx).viewInsets.bottom + AppTheme.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BottomSheetHandle(),
              const SizedBox(height: AppTheme.xl),
              Text('Record Payment', style: AppTheme.titleLarge),
              const SizedBox(height: AppTheme.sm),
              Text(
                'Due: ${AppConstants.formatCurrency(loan.totalDueNow)}',
                style: AppTheme.labelMedium,
              ),
              const SizedBox(height: AppTheme.xl),
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                autofocus: true,
                style: AppTheme.amountLarge.copyWith(fontSize: 24),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: AppTheme.amountLarge.copyWith(fontSize: 24),
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: AppTheme.md),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(hintText: 'Notes (optional)'),
              ),
              const SizedBox(height: AppTheme.md),
              GlassDatePickerButton(
                icon: Icons.calendar_today_rounded,
                text: '${payDate.day}/${payDate.month}/${payDate.year}',
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: payDate,
                    firstDate: loan.startDate,
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setModalState(() => payDate = d);
                },
              ),
              const SizedBox(height: AppTheme.xl),
              FullWidthButton(
                label: 'Record Payment',
                onPressed: () {
                  final amount = double.tryParse(ctrl.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount')),
                    );
                    return;
                  }
                  ref.read(loanProvider.notifier).addPayment(
                        loan.id,
                        LoanPayment(
                          id: const Uuid().v4(),
                          amount: amount,
                          date: payDate,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        ),
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment recorded!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, LoanModel loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Loan?'),
        content: Text('Are you sure you want to delete this loan with ${loan.personName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(loanProvider.notifier).delete(loan.id);
              Navigator.pop(ctx);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Extracted Sub-Widgets ──

class _LoanSummaryCard extends StatelessWidget {
  final LoanModel loan;
  final Color color;
  final bool isTaken;
  final int days;

  const _LoanSummaryCard({
    required this.loan,
    required this.color,
    required this.isTaken,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  loan.personName.isNotEmpty ? loan.personName[0].toUpperCase() : '?',
                  style: AppTheme.titleLarge.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isTaken ? 'You Borrowed From' : 'You Lent To',
                        style: AppTheme.labelSmall.copyWith(color: Colors.white70)),
                    Text(loan.personName,
                        style: AppTheme.titleLarge.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.xl),
          Text(isTaken ? 'Total You Owe Now' : 'Total Owed To You',
              style: AppTheme.labelMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: AppTheme.xs),
          Text(
            AppConstants.formatCurrency(loan.totalDueNow),
            style: AppTheme.amountLarge.copyWith(color: Colors.white, fontSize: 36),
          ),
          const SizedBox(height: 6),
          Text(
            '$days days since ${AppConstants.formatDate(loan.startDate)}',
            style: AppTheme.labelSmall.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _LoanBreakdownCard extends StatelessWidget {
  final LoanModel loan;
  final Color color;
  final bool isTaken;
  final int days;

  const _LoanBreakdownCard({
    required this.loan,
    required this.color,
    required this.isTaken,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detailed Breakdown', style: AppTheme.titleLarge),
        const SizedBox(height: AppTheme.md),
        Card(
          child: Padding(
            padding: AppTheme.cardPaddingCompact,
            child: Column(
              children: [
                DetailRow('Principal Amount', AppConstants.formatCurrency(loan.principalAmount)),
                const Divider(height: 20),
                DetailRow('Interest Rate', '${loan.interestRate}% per annum'),
                const Divider(height: 20),
                DetailRow('Interest Type',
                    loan.interestType == InterestType.simple ? 'Simple Interest' : 'Compound Interest'),
                if (loan.interestType == InterestType.compound) ...[
                  const Divider(height: 20),
                  DetailRow('Compounding',
                      '${loan.interestPeriod.name[0].toUpperCase()}${loan.interestPeriod.name.substring(1)}'),
                ],
                const Divider(height: 20),
                DetailRow('Start Date', AppConstants.formatDate(loan.startDate)),
                if (loan.expectedEndDate != null) ...[
                  const Divider(height: 20),
                  DetailRow('Expected End', AppConstants.formatDate(loan.expectedEndDate!)),
                ],
                const Divider(height: 20),
                DetailRow('Days Elapsed', '$days days', valueColor: Colors.white),
                const Divider(height: 20),
                DetailRow('Interest Accrued', AppConstants.formatCurrency(loan.currentInterest),
                    valueColor: AppTheme.loanTakenColor),
                const Divider(height: 20),
                DetailRow('Total (Principal + Interest)',
                    AppConstants.formatCurrency(loan.principalAmount + loan.currentInterest),
                    valueColor: Colors.white, isBold: true),
                const Divider(height: 20),
                DetailRow('Total Paid', AppConstants.formatCurrency(loan.totalPaid),
                    valueColor: AppTheme.incomeColor),
                const Divider(height: 20),
                DetailRow(
                    isTaken ? 'Remaining to Pay' : 'Remaining to Collect',
                    AppConstants.formatCurrency(loan.totalDueNow),
                    valueColor: color, isBold: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpectedTotalCard extends StatelessWidget {
  final LoanModel loan;
  final Color color;
  const _ExpectedTotalCard({required this.loan, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppTheme.cardPaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expected Total at End Date', style: AppTheme.labelSmall.copyWith(fontSize: 12)),
            const SizedBox(height: AppTheme.xs),
            Text(
              AppConstants.formatCurrency(loan.expectedTotalReturn),
              style: AppTheme.headlineMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentHistorySection extends StatelessWidget {
  final LoanModel loan;
  final VoidCallback onAddPayment;
  const _PaymentHistorySection({required this.loan, required this.onAddPayment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Payment History', style: AppTheme.titleLarge),
            ElevatedButton.icon(
              onPressed: onAddPayment,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Payment'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: 10),
                textStyle: AppTheme.labelMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.md),
        if (loan.payments.isEmpty)
          const EmptyStateWidget(
            icon: Icons.payment_rounded,
            title: 'No payments yet',
            iconSize: 48,
          )
        else
          ...loan.payments.reversed.map((p) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.incomeColor.withOpacity(0.15),
                    child: const Icon(Icons.check_rounded, color: AppTheme.incomeColor, size: 20),
                  ),
                  title: Text(
                    AppConstants.formatCurrency(p.amount),
                    style: AppTheme.labelLarge.copyWith(color: AppTheme.incomeColor, fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(AppConstants.formatDate(p.date), style: AppTheme.labelSmall),
                  trailing: p.notes != null
                      ? Tooltip(
                          message: p.notes!,
                          child: const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.textMuted),
                        )
                      : null,
                ),
              )),
      ],
    );
  }
}

