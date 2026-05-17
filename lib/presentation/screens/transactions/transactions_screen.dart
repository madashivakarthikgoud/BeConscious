import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/shared_widgets.dart';

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

  List<TransactionModel> _applyFilters(List<TransactionModel> allTxns) {
    return allTxns.where((t) {
      if (_filterType == 'Income' && t.type != TransactionType.income) return false;
      if (_filterType == 'Expense' && t.type != TransactionType.expense) return false;
      if (_filterTag != 'All' && !t.tags.contains(_filterTag)) return false;
      if (_filterPerson != 'All' &&
          t.moneySourcePerson != _filterPerson &&
          t.beneficiaryPerson != _filterPerson) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchDesc = t.description.toLowerCase().contains(q);
        final matchNotes = (t.notes ?? '').toLowerCase().contains(q);
        final matchTags = t.tags.any((tag) => tag.toLowerCase().contains(q));
        final matchSource = t.moneySourcePerson.toLowerCase().contains(q);
        final matchBeneficiary = t.beneficiaryPerson.toLowerCase().contains(q);
        final matchAmount = t.amount.toStringAsFixed(2).contains(q);
        final matchPayMode = t.paymentMode.name.toLowerCase().contains(q);
        if (!matchDesc && !matchNotes && !matchTags && !matchSource &&
            !matchBeneficiary && !matchAmount && !matchPayMode) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<String, List<TransactionModel>> _groupByDate(List<TransactionModel> txns) {
    final grouped = <String, List<TransactionModel>>{};
    for (final t in txns) {
      final key = AppConstants.formatDateShort(t.dateTime);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final allTxns = ref.watch(transactionProvider);
    final managedTags = ref.watch(tagProvider);
    final managedPersons = ref.watch(personProvider);

    final allUsedTags = <String>{};
    final allUsedPersons = <String>{};
    for (final t in allTxns) {
      allUsedTags.addAll(t.tags);
      if (t.moneySourcePerson.isNotEmpty) allUsedPersons.add(t.moneySourcePerson);
      if (t.beneficiaryPerson.isNotEmpty) allUsedPersons.add(t.beneficiaryPerson);
    }
    allUsedTags.addAll(managedTags);
    allUsedPersons.addAll(managedPersons);

    final tags = allUsedTags.toList()..sort();
    final persons = allUsedPersons.toList()..sort();

    final filtered = _applyFilters(allTxns);
    final grouped = _groupByDate(filtered);

    return SafeArea(
      child: Column(
        children: [
          _TransactionsHeader(itemCount: filtered.length),
          _SearchBar(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          _FilterRow(
            filterType: _filterType,
            filterTag: _filterTag,
            filterPerson: _filterPerson,
            tags: tags,
            persons: persons,
            onTypeChanged: (v) => setState(() => _filterType = v),
            onTagChanged: (v) => setState(() => _filterTag = v),
            onPersonChanged: (v) => setState(() => _filterPerson = v),
          ),
          const SizedBox(height: AppTheme.sm),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.receipt_long_rounded,
                    title: 'No transactions found',
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final dateKey = grouped.keys.elementAt(index);
                      final items = grouped[dateKey]!;
                      return _DateGroup(
                        dateKey: dateKey,
                        items: items,
                        onEdit: (txn) => context.push('/add-transaction',
                            extra: {'transaction': txn}),
                        onDelete: (txn) {
                          ref.read(transactionProvider.notifier).delete(txn.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaction deleted')),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Header ──

class _TransactionsHeader extends StatelessWidget {
  final int itemCount;
  const _TransactionsHeader({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.xl, AppTheme.lg, AppTheme.xl, 0),
      child: Row(
        children: [
          Text('Transactions', style: AppTheme.headlineMedium),
          const Spacer(),
          Text('$itemCount items', style: AppTheme.labelSmall),
        ],
      ),
    );
  }
}

// ── Search Bar ──

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.xl, AppTheme.md, AppTheme.xl, AppTheme.sm),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search transactions, tags, notes...',
            prefixIcon: const Icon(Icons.search_rounded,
                size: 20, color: AppTheme.textMuted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: AppTheme.md),
            isDense: true,
          ),
        ),
      ),
    );
  }
}

// ── Filter Row ──

class _FilterRow extends StatelessWidget {
  final String filterType;
  final String filterTag;
  final String filterPerson;
  final List<String> tags;
  final List<String> persons;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onTagChanged;
  final ValueChanged<String> onPersonChanged;

  const _FilterRow({
    required this.filterType,
    required this.filterTag,
    required this.filterPerson,
    required this.tags,
    required this.persons,
    required this.onTypeChanged,
    required this.onTagChanged,
    required this.onPersonChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
        children: [
          _FilterChip(
            label: filterType,
            options: const ['All', 'Income', 'Expense'],
            onSelected: onTypeChanged,
          ),
          const SizedBox(width: AppTheme.sm),
          _FilterChip(
            label: filterTag == 'All' ? 'Tag' : filterTag,
            options: ['All', ...tags],
            onSelected: onTagChanged,
          ),
          const SizedBox(width: AppTheme.sm),
          _FilterChip(
            label: filterPerson == 'All' ? 'Person' : filterPerson,
            options: ['All', ...persons],
            onSelected: onPersonChanged,
          ),
        ],
      ),
    );
  }
}

// ── Date Group ──

class _DateGroup extends StatelessWidget {
  final String dateKey;
  final List<TransactionModel> items;
  final ValueChanged<TransactionModel> onEdit;
  final ValueChanged<TransactionModel> onDelete;

  const _DateGroup({
    required this.dateKey,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dayTotal = items.fold(0.0, (sum, t) {
      return sum + (t.type == TransactionType.income ? t.amount : -t.amount);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.xl, AppTheme.lg, AppTheme.xl, AppTheme.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateKey, style: AppTheme.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              )),
              Text(
                AppConstants.formatCurrency(dayTotal),
                style: AppTheme.labelMedium.copyWith(
                  color: dayTotal >= 0
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ...items.map((txn) => _TxnItem(
              txn: txn,
              onEdit: () => onEdit(txn),
              onDelete: () => onDelete(txn),
            )),
      ],
    );
  }
}

// ── Filter Chip ──

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
          backgroundColor: AppTheme.cardDark,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cornerRadius)),
          ),
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppTheme.md),
              const BottomSheetHandle(),
              const SizedBox(height: AppTheme.lg),
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
              const SizedBox(height: AppTheme.lg),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppTheme.sm),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accent1.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
          border: Border.all(
            color: isActive
                ? AppTheme.accent1.withOpacity(0.4)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppTheme.labelMedium.copyWith(
                  color: isActive ? AppTheme.accent1 : AppTheme.textSecondary,
                )),
            const SizedBox(width: AppTheme.xs),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isActive ? AppTheme.accent1 : AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Transaction Item ──

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
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.lg, vertical: 3),
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
              borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
            ),
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppTheme.expenseColor,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Delete',
              borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
            ),
          ],
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: AppTheme.cornerRadiusSmall,
          child: Row(
            children: [
              _TxnIcon(isExpense: isExpense, color: color),
              const SizedBox(width: 14),
              Expanded(child: _TxnDetails(txn: txn)),
              const SizedBox(width: 10),
              Text(
                '${isExpense ? "-" : "+"}${AppConstants.formatCurrency(txn.amount)}',
                style: AppTheme.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxnIcon extends StatelessWidget {
  final bool isExpense;
  final Color color;
  const _TxnIcon({required this.isExpense, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _TxnDetails extends StatelessWidget {
  final TransactionModel txn;
  const _TxnDetails({required this.txn});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(txn.description,
            style: AppTheme.titleMedium.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: AppTheme.xs),
        Row(
          children: [
            if (txn.tags.isNotEmpty)
              _SmallBadge(
                text: txn.tags.first,
                color: AppTheme.accent1,
              ),
            if (txn.notes != null && txn.notes!.isNotEmpty)
              _SmallBadge(
                text: txn.notes!.length > 20
                    ? '${txn.notes!.substring(0, 20)}...'
                    : txn.notes!,
                color: AppTheme.accent2,
                icon: Icons.note_rounded,
              ),
            Expanded(
              child: Text(
                '${txn.moneySourcePerson} → ${txn.beneficiaryPerson}',
                style: AppTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(AppConstants.formatTime(txn.dateTime),
                style: AppTheme.labelSmall.copyWith(fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _SmallBadge({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ... [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 2),
          ],
          Text(text,
              style: AppTheme.labelSmall.copyWith(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}
