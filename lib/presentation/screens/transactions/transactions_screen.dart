import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/app_providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _filterTag = 'All';
  String _filterType = 'All'; // All, Income, Expense
  String _filterPerson = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allTxns = ref.watch(transactionProvider);
    final tags = ref.watch(tagProvider);
    final persons = ref.watch(personProvider);

    List<TransactionModel> filtered = allTxns.where((t) {
      if (_filterType == 'Income' && t.type != TransactionType.income)
        return false;
      if (_filterType == 'Expense' && t.type != TransactionType.expense)
        return false;
      if (_filterTag != 'All' && !t.tags.contains(_filterTag)) return false;
      if (_filterPerson != 'All' &&
          t.moneySourcePerson != _filterPerson &&
          t.beneficiaryPerson != _filterPerson) return false;
      if (_searchQuery.isNotEmpty &&
          !t.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    // Group by date
    final grouped = <String, List<TransactionModel>>{};
    for (final t in filtered) {
      final key = AppConstants.formatDateShort(t.dateTime);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text(
                  'Transactions',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${filtered.length} items',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),

          // Filters
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: _filterType,
                  options: ['All', 'Income', 'Expense'],
                  onSelected: (v) => setState(() => _filterType = v),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _filterTag == 'All' ? 'Tag' : _filterTag,
                  options: ['All', ...tags],
                  onSelected: (v) => setState(() => _filterTag = v),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _filterPerson == 'All' ? 'Person' : _filterPerson,
                  options: ['All', ...persons],
                  onSelected: (v) => setState(() => _filterPerson = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 80, color: Colors.white12),
                        const SizedBox(height: 16),
                        Text('No transactions found',
                            style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final dateKey = grouped.keys.elementAt(index);
                      final items = grouped[dateKey]!;
                      final dayTotal = items.fold(0.0, (sum, t) {
                        return sum +
                            (t.type == TransactionType.income
                                ? t.amount
                                : -t.amount);
                      });

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateKey,
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  AppConstants.formatCurrency(dayTotal),
                                  style: TextStyle(
                                    color: dayTotal >= 0
                                        ? AppTheme.incomeColor
                                        : AppTheme.expenseColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...items.map((txn) => _TxnItem(
                                txn: txn,
                                onEdit: () {
                                  context.push('/add-transaction',
                                      extra: {'transaction': txn});
                                },
                                onDelete: () {
                                  ref
                                      .read(transactionProvider.notifier)
                                      .delete(txn.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Transaction deleted')),
                                  );
                                },
                              )),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final List<String> options;
  final ValueChanged<String> onSelected;

  const _FilterChip({
    required this.label,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppTheme.surfaceDark,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((o) => ListTile(
                    title: Text(o),
                    trailing:
                        o == label ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      onSelected(o);
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: label != 'All' && label != 'Tag' && label != 'Person'
              ? AppTheme.primaryColor.withOpacity(0.2)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: label != 'All' && label != 'Tag' && label != 'Person'
                ? AppTheme.primaryColor
                : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _TxnItem extends StatelessWidget {
  final TransactionModel txn;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TxnItem({
    required this.txn,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = txn.type == TransactionType.expense;
    final color = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: 'Edit',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppTheme.expenseColor,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Delete',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(
                    isExpense
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: color,
                    size: 20,
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
                            fontWeight: FontWeight.w500, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (txn.tags.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                txn.tags.first,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryColor),
                              ),
                            ),
                          Text(
                            '${txn.moneySourcePerson} → ${txn.beneficiaryPerson}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white38),
                          ),
                          const Spacer(),
                          Text(
                            AppConstants.formatTime(txn.dateTime),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white24),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${isExpense ? "-" : "+"}${AppConstants.formatCurrency(txn.amount)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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

