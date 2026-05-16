import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/backup_service.dart';
import '../../providers/app_providers.dart';
import '../../../data/datasources/local/local_database.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = BackupService.getDataSummary();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Profile
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    child: const Text('SK',
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shiva Karthik',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('BeConscious User',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Data Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Data',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _DataRow(Icons.receipt_long_rounded, 'Transactions',
                      '${summary['transactions']}', AppTheme.primaryColor),
                  _DataRow(Icons.handshake_rounded, 'Loans',
                      '${summary['loans']}', AppTheme.loanTakenColor),
                  _DataRow(Icons.savings_rounded, 'Savings Goals',
                      '${summary['savings']}', AppTheme.savingsColor),
                  _DataRow(Icons.label_rounded, 'Tags',
                      '${summary['tags']}', AppTheme.loanGivenColor),
                  _DataRow(Icons.people_rounded, 'Persons',
                      '${summary['persons']}', AppTheme.expenseColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Backup & Restore
          Text('Backup & Restore',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Export your data to keep it safe. Import on a new phone to restore everything.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 12),

          _SettingsTile(
            icon: Icons.upload_rounded,
            title: 'Export Full Backup (JSON)',
            subtitle: 'Save all data — share via Drive, WhatsApp, Email',
            color: AppTheme.incomeColor,
            onTap: () async {
              final error = await BackupService.exportData(context);
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
                // Reload all providers
                ref.read(transactionProvider.notifier).loadAll();
                ref.read(loanProvider.notifier).loadAll();
                ref.read(savingsProvider.notifier).loadAll();
                ref.read(tagProvider.notifier).loadAll();
                ref.read(personProvider.notifier).loadAll();

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
                  await BackupService.exportTransactionsCsv(context);
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
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _SettingsTile(
            icon: Icons.label_rounded,
            title: 'Manage Tags',
            subtitle: 'Add or remove custom tags',
            color: AppTheme.primaryColor,
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

          // How Data is Stored
          Text('Data Storage',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
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
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // About
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.psychology_rounded,
                      size: 48, color: AppTheme.primaryColor),
                  const SizedBox(height: 12),
                  const Text('BeConscious',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text('v1.0.0',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 8),
                  const Text(
                    'Your complete personal finance tracker.\nTrack spending, loans, savings & more.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Text('Built for Shiva Karthik ❤️',
                      style:
                          TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Danger zone
          Card(
            color: AppTheme.expenseColor.withOpacity(0.1),
            child: ListTile(
              leading: const Icon(Icons.delete_forever_rounded,
                  color: AppTheme.expenseColor),
              title: const Text('Delete All Data',
                  style: TextStyle(color: AppTheme.expenseColor)),
              subtitle: const Text('This cannot be undone',
                  style: TextStyle(fontSize: 11, color: Colors.white38)),
              onTap: () => _confirmDeleteAll(context, ref),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _manageTags(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Manage Tags',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
                                      ref.read(tagProvider.notifier)
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
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: tags.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                        child: const Icon(Icons.label_rounded,
                            size: 16, color: AppTheme.primaryColor),
                      ),
                      title: Text(tags[i]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: Colors.white38),
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
      backgroundColor: AppTheme.surfaceDark,
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Manage Persons',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
                                      ref.read(personProvider.notifier)
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
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: persons.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppTheme.loanTakenColor.withOpacity(0.15),
                        child: Text(
                          persons[i][0].toUpperCase(),
                          style: const TextStyle(
                              color: AppTheme.loanTakenColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                      title: Text(persons[i]),
                      trailing: persons[i] == 'Self'
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 20, color: Colors.white38),
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
            'This will permanently delete ALL your transactions, loans, and savings goals.\n\nThis action CANNOT be undone.\n\nPlease export a backup first!'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final transactions = LocalDatabase.getAllTransactions();
              for (final t in transactions) {
                await LocalDatabase.deleteTransaction(t.id);
              }
              final loans = LocalDatabase.getAllLoans();
              for (final l in loans) {
                await LocalDatabase.deleteLoan(l.id);
              }
              final savings = LocalDatabase.getAllSavingsGoals();
              for (final s in savings) {
                await LocalDatabase.deleteSavingsGoal(s.id);
              }
              ref.read(transactionProvider.notifier).loadAll();
              ref.read(loanProvider.notifier).loadAll();
              ref.read(savingsProvider.notifier).loadAll();

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
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.white38)),
          trailing:
              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
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
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
