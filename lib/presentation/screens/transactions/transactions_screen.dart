import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/glass_widgets.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _filterTag = 'All';
  String _filterType = 'All';
  String _filterPerson = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTxns = ref.watch(transactionProvider);
    final tags = ref.watch(tagProvider);
    final persons = ref.watch(personProvider);

    List<TransactionModel> filtered = allTxns.where((t) {
      if (_filterType == 'Income' && t.type != TransactionType.income) return false;
      if (_filterType == 'Expense' && t.type != TransactionType.expense) return false;
      if (_filterTag != 'All' && !t.tags.contains(_filterTag)) return false;
      if (_filterPerson != 'All' &&
          t.moneySourcePerson != _filterPerson &&
          t.beneficiaryPerson != _filterPerson) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        // FIX: Search across description, notes, tags, and persons
        final matchDesc = t.description.toLowerCase().contains(q);
        final matchNotes = (t.notes ?? '').toLowerCase().contains(q);
        final matchTags = t.tags.any((tag) => tag.toLowerCase().contains(q));
        final matchSource = t.moneySourcePerson.toLowerCase().contains(q);
        final matchBeneficiary = t.beneficiaryPerson.toLowerCase().contains(q);
        if (!matchDesc && !matchNotes && !matchTags && !matchSource && !matchBeneficiary) {
          return false;
        }
      }
      return true;
    }).toList();

    final grouped = <String, List<TransactionModel>>{};
    for (final t in filtered) {
      final key = AppConstants.formatDateShort(t.dateTime);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text(
                  'Transactions',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  '${filtered.length} items',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search transactions, tags, notes...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
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

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 80, color: Colors.white.withOpacity(0.06)),
                        const SizedBox(height: 16),
                        const Text('No transactions found',
                            style: TextStyle(color: AppTheme.textMuted)),
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
                        return sum + (t.type == TransactionType.income ? t.amount : -t.amount);
                      });

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dateKey,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    )),
                                Text(
                                  AppConstants.formatCurrency(dayTotal),
                                  style: TextStyle(
                                    color: dayTotal >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...items.map((txn) => _TxnItem(
                                txn: txn,
                                onEdit: () => context.push('/add-transaction',
                                    extra: {'transaction': txn}),
                                onDelete: () {
                                  ref.read(transactionProvider.notifier).delete(txn.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Transaction deleted')),
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
    final isActive = label != 'All' && label != 'Tag' && label != 'Person';
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF152A1C),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((o) => ListTile(
                    title: Text(o),
                    trailing: o == label
                        ? const Icon(Icons.check_rounded, color: AppTheme.accent1)
                        : null,
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
          color: isActive ? AppTheme.accent1.withOpacity(0.12) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.accent1.withOpacity(0.4) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppTheme.accent1 : AppTheme.textSecondary,
                )),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: isActive ? AppTheme.accent1 : AppTheme.textMuted),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: AppTheme.accent1,
              foregroundColor: AppTheme.backgroundDark,
              icon: Icons.edit_rounded,
              label: 'Edit',
              borderRadius: BorderRadius.circular(20),
            ),
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppTheme.expenseColor,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Delete',
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: AppTheme.cornerRadiusSmall,
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isExpense ? Icons.north_east_rounded : Icons.south_west_rounded,
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
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (txn.tags.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.accent1.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              txn.tags.first,
                              style: const TextStyle(fontSize: 10, color: AppTheme.accent1),
                            ),
                          ),
                        if (txn.notes != null && txn.notes!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.accent2.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.note_rounded, size: 10, color: AppTheme.accent2),
                                const SizedBox(width: 2),
                                Text(
                                  txn.notes!.length > 20 ? '${txn.notes!.substring(0, 20)}...' : txn.notes!,
                                  style: const TextStyle(fontSize: 10, color: AppTheme.accent2),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: Text(
                            '${txn.moneySourcePerson} → ${txn.beneficiaryPerson}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          AppConstants.formatTime(txn.dateTime),
                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
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
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

