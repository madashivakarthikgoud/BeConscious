import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/backup_service.dart';
import '../../providers/app_providers.dart';
import '../../../data/datasources/local/local_database.dart';
import '../../widgets/glass_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = BackupService.getDataSummary();
    final userName = ref.watch(userNameProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Profile with editable name
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.accent1.withOpacity(0.2),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                        color: AppTheme.accent1,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const Text('BeConscious User',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _editName(context, ref, userName),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent1.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: AppTheme.accent1, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Data Summary
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Data',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                _DataRow(Icons.receipt_long_rounded, 'Transactions',
                    '${summary['transactions']}', AppTheme.accent1),
                _DataRow(Icons.handshake_rounded, 'Loans',
                    '${summary['loans']}', AppTheme.loanTakenColor),
                _DataRow(Icons.savings_rounded, 'Savings Goals',
                    '${summary['savings']}', AppTheme.savingsColor),
                _DataRow(Icons.psychology_rounded, 'Mind Items',
                    '${summary['mindItems'] ?? 0}', AppTheme.accent2),
                _DataRow(Icons.label_rounded, 'Tags',
                    '${summary['tags']}', AppTheme.loanGivenColor),
                _DataRow(Icons.people_rounded, 'Persons',
                    '${summary['persons']}', AppTheme.expenseColor),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Backup & Restore
          Text('Backup & Restore',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Export your data to keep it safe. Import on a new phone to restore everything.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),

          _SettingsTile(
            icon: Icons.upload_rounded,
            title: 'Export Full Backup (JSON)',
            subtitle: 'Save all data — share via Drive, WhatsApp, Email',
            color: AppTheme.incomeColor,
            onTap: () async {
              final error = await BackupService.exportData();
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error)));
              }
            },
          ),

          _SettingsTile(
            icon: Icons.download_rounded,
            title: 'Import Backup (JSON)',
            subtitle: 'Restore data from a backup file',
            color: AppTheme.loanGivenColor,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Import Backup?'),
                  content: const Text(
                      'This will merge the backup data with your existing data. No data will be lost.\n\nSelect your BeConscious backup JSON file.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Choose File')),
                  ],
                ),
              );

              if (confirmed != true) return;

              final result = await BackupService.importData();
              if (!context.mounted) return;

              if (result == null || result == 'No file selected') {
                return;
              } else if (result.startsWith('SUCCESS:')) {
                final count = result.split(':')[1];
                ref.read(transactionProvider.notifier).loadAll();
                ref.read(loanProvider.notifier).loadAll();
                ref.read(savingsProvider.notifier).loadAll();
                ref.read(tagProvider.notifier).loadAll();
                ref.read(personProvider.notifier).loadAll();
                ref.read(mindSpaceProvider.notifier).loadAll();

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('✅ Successfully imported $count items!'),
                  backgroundColor: AppTheme.incomeColor,
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('❌ $result'),
                  backgroundColor: AppTheme.expenseColor,
                ));
              }
            },
          ),

          _SettingsTile(
            icon: Icons.table_chart_rounded,
            title: 'Export Transactions (CSV)',
            subtitle: 'Open in Excel / Google Sheets',
            color: AppTheme.savingsColor,
            onTap: () async {
              final error =
                  await BackupService.exportTransactionsCsv();
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error)));
              }
            },
          ),
          const SizedBox(height: 20),

          // Manage
          Text('Manage',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          _SettingsTile(
            icon: Icons.label_rounded,
            title: 'Manage Tags',
            subtitle: 'Add or remove custom tags',
            color: AppTheme.accent1,
            onTap: () => _manageTags(context, ref),
          ),

          _SettingsTile(
            icon: Icons.people_rounded,
            title: 'Manage Persons',
            subtitle: 'Add or remove persons',
            color: AppTheme.loanTakenColor,
            onTap: () => _managePersons(context, ref),
          ),
          const SizedBox(height: 20),

          // Data Storage
          Text('Data Storage',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.phone_android_rounded,
                        color: AppTheme.incomeColor, size: 20),
                    const SizedBox(width: 10),
                    const Text('Stored locally on this phone',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• All data is saved on your phone only\n'
                  '• No internet or account needed\n'
                  '• 100% private — nobody else can see it\n'
                  '• Use Export to backup before changing phones\n'
                  '• Use Import on new phone to restore everything',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About App
          Text('About',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.accent1, AppTheme.accent2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      size: 36, color: AppTheme.backgroundDark),
                ),
                const SizedBox(height: 16),
                const Text('BeConscious',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('v1.0.0',
                      style: TextStyle(
                          color: AppTheme.accent1,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Built to bring clarity to your financial life. '
                  'Every rupee tracked, every loan calculated, every goal visualized. '
                  'Because being conscious about money is the first step to freedom.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: const Column(
                    children: [
                      Text('Crafted with ❤️ by',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11)),
                      SizedBox(height: 4),
                      Text('Shiva Karthik',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent1)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _openGitHub(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.code_rounded,
                            color: AppTheme.accent2, size: 18),
                        SizedBox(width: 10),
                        Text('View on GitHub',
                            style: TextStyle(
                                color: AppTheme.accent2,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        SizedBox(width: 6),
                        Icon(Icons.open_in_new_rounded,
                            color: AppTheme.accent2, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Report bugs • Contribute • Star ⭐',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Danger zone
          GlassCard(
            padding: EdgeInsets.zero,
            borderColor: AppTheme.expenseColor.withOpacity(0.2),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.delete_forever_rounded,
                  color: AppTheme.expenseColor),
              title: const Text('Delete All Data',
                  style: TextStyle(color: AppTheme.expenseColor)),
              subtitle: const Text('This cannot be undone',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              onTap: () => _confirmDeleteAll(context, ref),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static void _openGitHub() async {
    final uri =
        Uri.parse('https://github.com/madashivakarthikgoud');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  void _editName(BuildContext context, WidgetRef ref, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(userNameProvider.notifier).setName(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _manageTags(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Consumer(
          builder: (context, ref, _) {
            final tags = ref.watch(tagProvider);
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Manage Tags',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: () {
                          final ctrl = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('New Tag'),
                              content: TextField(
                                controller: ctrl,
                                autofocus: true,
                                textCapitalization: TextCapitalization.words,
                                decoration:
                                    const InputDecoration(hintText: 'Tag name'),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(c),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    if (ctrl.text.trim().isNotEmpty) {
                                      ref
                                          .read(tagProvider.notifier)
                                          .add(ctrl.text.trim());
                                      Navigator.pop(c);
                                    }
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: tags.isEmpty
                      ? const Center(
                          child: Text('No tags yet',
                              style: TextStyle(color: AppTheme.textMuted)))
                      : ListView.builder(
                          controller: scrollCtrl,
                          itemCount: tags.length,
                          itemBuilder: (_, i) => ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppTheme.accent1.withOpacity(0.15),
                              child: const Icon(Icons.label_rounded,
                                  size: 16, color: AppTheme.accent1),
                            ),
                            title: Text(tags[i]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 20, color: AppTheme.textMuted),
                              onPressed: () =>
                                  ref.read(tagProvider.notifier).remove(tags[i]),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _managePersons(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        builder: (_, scrollCtrl) => Consumer(
          builder: (context, ref, _) {
            final persons = ref.watch(personProvider);
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Manage Persons',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: () {
                          final ctrl = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('New Person'),
                              content: TextField(
                                controller: ctrl,
                                autofocus: true,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                    hintText: 'Person name'),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(c),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    if (ctrl.text.trim().isNotEmpty) {
                                      ref
                                          .read(personProvider.notifier)
                                          .add(ctrl.text.trim());
                                      Navigator.pop(c);
                                    }
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: persons.isEmpty
                      ? const Center(
                          child: Text('No persons yet',
                              style: TextStyle(color: AppTheme.textMuted)))
                      : ListView.builder(
                          controller: scrollCtrl,
                          itemCount: persons.length,
                          itemBuilder: (_, i) => ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppTheme.loanTakenColor.withOpacity(0.15),
                              child: Text(
                                persons[i].isNotEmpty
                                    ? persons[i][0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: AppTheme.loanTakenColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14),
                              ),
                            ),
                            title: Text(persons[i]),
                            trailing: persons[i] == 'Self'
                                ? null
                                : IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: AppTheme.textMuted),
                                    onPressed: () => ref
                                        .read(personProvider.notifier)
                                        .remove(persons[i]),
                                  ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Delete All Data?'),
        content: const Text(
            'This will permanently delete ALL your transactions, loans, savings goals, and mind space items.\n\nThis action CANNOT be undone.\n\nPlease export a backup first!'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await LocalDatabase.clearEverything();
              ref.read(transactionProvider.notifier).loadAll();
              ref.read(loanProvider.notifier).loadAll();
              ref.read(savingsProvider.notifier).loadAll();
              ref.read(mindSpaceProvider.notifier).loadAll();
              ref.read(tagProvider.notifier).loadAll();
              ref.read(personProvider.notifier).loadAll();

              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.expenseColor),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(subtitle,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          trailing:
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;

  const _DataRow(this.icon, this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(count,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
