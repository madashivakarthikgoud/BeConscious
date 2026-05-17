import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/mind_space_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/shared_widgets.dart';

class MindSpaceScreen extends ConsumerStatefulWidget {
  const MindSpaceScreen({super.key});

  @override
  ConsumerState<MindSpaceScreen> createState() => _MindSpaceScreenState();
}

class _MindSpaceScreenState extends ConsumerState<MindSpaceScreen> {
  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingMindItemsProvider);
    final completed = ref.watch(completedMindItemsProvider);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _MindSpaceHeader(onAdd: () => _showMindSheet(context))),
          SliverToBoxAdapter(child: _QuickAddBanner(onTap: () => _showMindSheet(context))),
          if (pending.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppTheme.xl, 0, AppTheme.xl, AppTheme.md),
                child: SectionHeader(title: 'To Remember (${pending.length})'),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = pending[index];
                  return _MindItemCard(
                    item: item,
                    onToggle: () => ref.read(mindSpaceProvider.notifier).toggleComplete(item.id),
                    onEdit: () => _showMindSheet(context, editItem: item),
                    onDelete: () => ref.read(mindSpaceProvider.notifier).delete(item.id),
                  );
                },
                childCount: pending.length,
              ),
            ),
          ],
          if (completed.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppTheme.xl, AppTheme.xl, AppTheme.xl, AppTheme.md),
                child: SectionHeader(title: 'Completed (${completed.length})'),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = completed[index];
                  return _CompletedMindCard(
                    item: item,
                    onTap: () {
                      ref.read(mindSpaceProvider.notifier).delete(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item cleared!')),
                      );
                    },
                  );
                },
                childCount: completed.length,
              ),
            ),
          ],
          if (pending.isEmpty && completed.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                icon: Icons.psychology_rounded,
                title: 'Your mind is clear!',
                subtitle: 'Tap + to save something important',
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  /// Unified add/edit sheet — eliminates the massive DRY violation
  void _showMindSheet(BuildContext context, {MindSpaceItem? editItem}) {
    final isEditing = editItem != null;
    final titleCtrl = TextEditingController(text: editItem?.title ?? '');
    final descCtrl = TextEditingController(text: editItem?.description ?? '');
    MindItemPriority priority = editItem?.priority ?? MindItemPriority.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cornerRadius)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              AppTheme.xxl, AppTheme.lg, AppTheme.xxl,
              MediaQuery.of(ctx).viewInsets.bottom + AppTheme.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BottomSheetHandle(),
              const SizedBox(height: AppTheme.xl),
              Text(isEditing ? 'Edit Item' : 'Save to Mind Space',
                  style: AppTheme.titleLarge),
              const SizedBox(height: AppTheme.xl),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                style: AppTheme.titleMedium,
                decoration: const InputDecoration(
                    hintText: 'What do you want to remember?'),
              ),
              const SizedBox(height: AppTheme.md),
              TextField(
                controller: descCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Details (optional)'),
              ),
              const SizedBox(height: AppTheme.lg),
              Text('Priority', style: AppTheme.labelMedium),
              const SizedBox(height: AppTheme.sm),
              _PrioritySelector(
                selected: priority,
                onChanged: (p) => setModalState(() => priority = p),
              ),
              const SizedBox(height: AppTheme.xxl),
              FullWidthButton(
                label: isEditing ? 'Update' : 'Save',
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  if (isEditing) {
                    ref.read(mindSpaceProvider.notifier).update(editItem.copyWith(
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                      priority: priority,
                    ));
                  } else {
                    ref.read(mindSpaceProvider.notifier).add(MindSpaceItem(
                      id: const Uuid().v4(),
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                      priority: priority,
                    ));
                  }
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ──

class _MindSpaceHeader extends StatelessWidget {
  final VoidCallback onAdd;
  const _MindSpaceHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.xl, AppTheme.xl, AppTheme.xl, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mind Space 🧠', style: AppTheme.headlineLarge.copyWith(fontSize: 26)),
                const SizedBox(height: AppTheme.xs),
                Text("Things you don't want to forget",
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accent1,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add_rounded, color: AppTheme.backgroundDark, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Add Banner ──

class _QuickAddBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickAddBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.xl),
      child: GradientBanner(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Capture a thought',
                      style: AppTheme.titleLarge.copyWith(
                        color: AppTheme.backgroundDark,
                        fontSize: 18,
                      )),
                  const SizedBox(height: AppTheme.xs),
                  Text('Save it before you forget!',
                      style: AppTheme.labelMedium.copyWith(
                        color: AppTheme.backgroundDark.withOpacity(0.7),
                      )),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppTheme.backgroundDark, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Priority Selector (extracted from duplicated code) ──

class _PrioritySelector extends StatelessWidget {
  final MindItemPriority selected;
  final ValueChanged<MindItemPriority> onChanged;

  const _PrioritySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MindItemPriority.values.map((p) {
        final isSelected = selected == p;
        final color = priorityColorMap[p.name] ?? AppTheme.accent2;
        final label = p.name[0].toUpperCase() + p.name.substring(1);

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: Container(
              margin: EdgeInsets.only(right: p != MindItemPriority.high ? AppTheme.sm : 0),
              padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? color : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Center(
                child: Text(label,
                    style: AppTheme.labelMedium.copyWith(
                      color: isSelected ? color : AppTheme.textSecondary,
                    )),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Mind Item Card ──

class _MindItemCard extends StatelessWidget {
  final MindSpaceItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MindItemCard({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = priorityColorMap[item.priority.name] ?? AppTheme.accent2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl, vertical: AppTheme.xs),
      child: GlassCard(
        padding: AppTheme.cardPaddingCompact,
        borderColor: color.withOpacity(0.2),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppTheme.titleMedium.copyWith(fontSize: 15)),
                  if (item.description != null) ...[
                    const SizedBox(height: AppTheme.xs),
                    Text(item.description!,
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            StatusBadge(
              label: item.priority.name[0].toUpperCase() + item.priority.name.substring(1),
              color: color,
            ),
            const SizedBox(width: AppTheme.sm),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 20),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Completed Card ──

class _CompletedMindCard extends StatelessWidget {
  final MindSpaceItem item;
  final VoidCallback onTap;

  const _CompletedMindCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl, vertical: AppTheme.xs),
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: AppTheme.cardPaddingCompact,
          opacity: 0.04,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent1.withOpacity(0.2),
                ),
                child: const Icon(Icons.check_rounded, size: 16, color: AppTheme.accent1),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: AppTheme.xs),
              Text('Tap to clear', style: AppTheme.labelSmall.copyWith(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

