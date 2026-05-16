import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/loan_model.dart';
import '../../providers/app_providers.dart';

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
        body: const Center(child: Text('Loan not found')),
      );
    }

    final isTaken = loan.type == LoanType.taken;
    final color = isTaken ? AppTheme.loanTakenColor : AppTheme.loanGivenColor;
    final days = DateTime.now().difference(loan.startDate).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(loan.personName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () =>
                context.push('/add-loan', extra: {'loan': loan}),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: () => _confirmDelete(context, ref, loan),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Main summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
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
                        loan.personName[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTaken ? 'You Borrowed From' : 'You Lent To',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            loan.personName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  isTaken ? 'Total You Owe Now' : 'Total Owed To You',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.formatCurrency(loan.totalDueNow),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$days days since ${AppConstants.formatDate(loan.startDate)}',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Detailed Breakdown
          Text('Detailed Breakdown',
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
                  _DetailRow('Principal Amount',
                      AppConstants.formatCurrency(loan.principalAmount)),
                  const Divider(height: 20),
                  _DetailRow('Interest Rate',
                      '${loan.interestRate}% per annum'),
                  const Divider(height: 20),
                  _DetailRow(
                      'Interest Type',
                      loan.interestType == InterestType.simple
                          ? 'Simple Interest'
                          : 'Compound Interest'),
                  if (loan.interestType == InterestType.compound) ...[
                    const Divider(height: 20),
                    _DetailRow('Compounding',
                        '${loan.interestPeriod.name[0].toUpperCase()}${loan.interestPeriod.name.substring(1)}'),
                  ],
                  const Divider(height: 20),
                  _DetailRow('Start Date',
                      AppConstants.formatDate(loan.startDate)),
                  if (loan.expectedEndDate != null) ...[
                    const Divider(height: 20),
                    _DetailRow('Expected End',
                        AppConstants.formatDate(loan.expectedEndDate!)),
                  ],
                  const Divider(height: 20),
                  _DetailRow('Days Elapsed', '$days days',
                      valueColor: Colors.white),
                  const Divider(height: 20),
                  _DetailRow(
                    'Interest Accrued',
                    AppConstants.formatCurrency(loan.currentInterest),
                    valueColor: AppTheme.loanTakenColor,
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    'Total (Principal + Interest)',
                    AppConstants.formatCurrency(
                        loan.principalAmount + loan.currentInterest),
                    valueColor: Colors.white,
                    isBold: true,
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    'Total Paid',
                    AppConstants.formatCurrency(loan.totalPaid),
                    valueColor: AppTheme.incomeColor,
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    isTaken ? 'Remaining to Pay' : 'Remaining to Collect',
                    AppConstants.formatCurrency(loan.totalDueNow),
                    valueColor: color,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (loan.expectedEndDate != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expected Total at End Date',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.formatCurrency(loan.expectedTotalReturn),
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Payment History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment History',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _addPayment(context, ref, loan),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Payment'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (loan.payments.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.payment_rounded,
                          size: 48, color: Colors.white12),
                      const SizedBox(height: 12),
                      Text('No payments yet',
                          style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                ),
              ),
            )
          else
            ...loan.payments.reversed.map((p) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.incomeColor.withOpacity(0.15),
                      child: const Icon(Icons.check_rounded,
                          color: AppTheme.incomeColor, size: 20),
                    ),
                    title: Text(
                      AppConstants.formatCurrency(p.amount),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.incomeColor),
                    ),
                    subtitle: Text(
                      AppConstants.formatDate(p.date),
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white38),
                    ),
                    trailing: p.notes != null
                        ? Tooltip(
                            message: p.notes!,
                            child: const Icon(Icons.info_outline_rounded,
                                size: 18, color: Colors.white24),
                          )
                        : null,
                  ),
                )),

          if (loan.notes != null && loan.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Notes',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(loan.notes!,
                    style: const TextStyle(color: Colors.white60)),
              ),
            ),
          ],

          // Mark as completed
          if (loan.status == LoanStatus.active) ...[
            const SizedBox(height: 24),
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
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Record Payment',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Due: ${AppConstants.formatCurrency(loan.totalDueNow)}',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}')),
                ],
                autofocus: true,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(hintText: 'Notes (optional)'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: payDate,
                    firstDate: loan.startDate,
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setModalState(() => payDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text('${payDate.day}/${payDate.month}/${payDate.year}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
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
                  child: const Text('Record Payment'),
                ),
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
        content: Text(
            'Are you sure you want to delete this loan with ${loan.personName}?'),
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
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.expenseColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _DetailRow(this.label, this.value,
      {this.valueColor, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white70,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

