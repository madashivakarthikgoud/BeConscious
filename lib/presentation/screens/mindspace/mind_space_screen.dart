import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/mind_space_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/glass_widgets.dart';

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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mind Space 🧠',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Things you don\'t want to forget',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _AddButton(onTap: () => _showAddSheet(context)),
                ],
              ),
            ),
          ),

          // Quick add banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GradientBanner(
                onTap: () => _showAddSheet(context),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Capture a thought',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.backgroundDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Save it before you forget!',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.backgroundDark.withOpacity(0.7),
                            ),
                          ),
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
                      child: Icon(Icons.add_rounded,
                          color: AppTheme.backgroundDark, size: 28),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pending items
          if (pending.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SectionHeader(
                  title: 'To Remember (${pending.length})',
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = pending[index];
                  return _MindItemCard(
                    item: item,
                    onToggle: () => ref.read(mindSpaceProvider.notifier).toggleComplete(item.id),
                    onEdit: () => _showEditSheet(context, item),
                    onDelete: () => ref.read(mindSpaceProvider.notifier).delete(item.id),
                  );
                },
                childCount: pending.length,
              ),
            ),
          ],

          // Completed items — tapping deletes
          if (completed.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: SectionHeader(
                  title: 'Completed (${completed.length})',
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = completed[index];
                  return _CompletedMindCard(
                    item: item,
                    onTap: () {
                      // Tapping completed item deletes it
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
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.psychology_rounded,
                        size: 80, color: AppTheme.accent2.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text('Your mind is clear!',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Tap + to save something important',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    MindItemPriority priority = MindItemPriority.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF152A1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Save to Mind Space',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(hintText: 'What do you want to remember?'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Details (optional)'),
              ),
              const SizedBox(height: 16),
              const Text('Priority', style: TextStyle(
                color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: MindItemPriority.values.map((p) {
                  final selected = priority == p;
                  final colors = {
                    MindItemPriority.low: AppTheme.incomeColor,
                    MindItemPriority.medium: AppTheme.loanTakenColor,
                    MindItemPriority.high: AppTheme.expenseColor,
                  };
                  final labels = {
                    MindItemPriority.low: 'Low',
                    MindItemPriority.medium: 'Medium',
                    MindItemPriority.high: 'High',
                  };
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => priority = p),
                      child: Container(
                        margin: EdgeInsets.only(right: p != MindItemPriority.high ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? colors[p]!.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? colors[p]! : Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Center(
                          child: Text(labels[p]!,
                              style: TextStyle(
                                color: selected ? colors[p] : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    ref.read(mindSpaceProvider.notifier).add(MindSpaceItem(
                      id: const Uuid().v4(),
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      priority: priority,
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, MindSpaceItem item) {
    final titleCtrl = TextEditingController(text: item.title);
    final descCtrl = TextEditingController(text: item.description ?? '');
    MindItemPriority priority = item.priority;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF152A1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Edit Item',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Details (optional)'),
              ),
              const SizedBox(height: 16),
              const Text('Priority', style: TextStyle(
                color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: MindItemPriority.values.map((p) {
                  final selected = priority == p;
                  final colors = {
                    MindItemPriority.low: AppTheme.incomeColor,
                    MindItemPriority.medium: AppTheme.loanTakenColor,
                    MindItemPriority.high: AppTheme.expenseColor,
                  };
                  final labels = {
                    MindItemPriority.low: 'Low',
                    MindItemPriority.medium: 'Medium',
                    MindItemPriority.high: 'High',
                  };
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => priority = p),
                      child: Container(
                        margin: EdgeInsets.only(right: p != MindItemPriority.high ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? colors[p]!.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? colors[p]! : Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Center(
                          child: Text(labels[p]!,
                              style: TextStyle(
                                color: selected ? colors[p] : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    ref.read(mindSpaceProvider.notifier).update(item.copyWith(
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      priority: priority,
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppTheme.accent1,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.add_rounded, color: AppTheme.backgroundDark, size: 24),
      ),
    );
  }
}

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
    final priorityColors = {
      MindItemPriority.low: AppTheme.incomeColor,
      MindItemPriority.medium: AppTheme.loanTakenColor,
      MindItemPriority.high: AppTheme.expenseColor,
    };
    final color = priorityColors[item.priority]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: color.withOpacity(0.2),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                  color: Colors.transparent,
                ),
                child: const SizedBox(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.priority.name[0].toUpperCase() + item.priority.name.substring(1),
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 20),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedMindCard extends StatelessWidget {
  final MindSpaceItem item;
  final VoidCallback onTap;

  const _CompletedMindCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          opacity: 0.04,
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
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
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text('Tap to clear',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

