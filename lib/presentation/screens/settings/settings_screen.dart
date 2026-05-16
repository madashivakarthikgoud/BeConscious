import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/local/local_database.dart';
import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Profile section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    child: const Text(
                      'SK',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shiva Karthik',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'BeConscious User',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Data Management
          Text('Data Management',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _SettingsTile(
            icon: Icons.upload_rounded,
            title: 'Export Data (JSON)',
            subtitle: 'Export all data as a backup file',
            color: AppTheme.incomeColor,
            onTap: () => _exportData(context),
          ),

          _SettingsTile(
            icon: Icons.download_rounded,
            title: 'Import Data (JSON)',
            subtitle: 'Restore from a backup file',
            color: AppTheme.loanGivenColor,
            onTap: () => _showImportInfo(context),
          ),

          _SettingsTile(
            icon: Icons.table_chart_rounded,
            title: 'Export as CSV',
            subtitle: 'Export transactions to spreadsheet',
            color: AppTheme.savingsColor,
            onTap: () => _exportCsv(context),
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

          // About
          Text('About',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.psychology_rounded,
                      size: 48, color: AppTheme.primaryColor),
                  const SizedBox(height: 12),
                  const Text(
                    'BeConscious',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text('v1.0.0',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 8),
                  const Text(
                    'Your complete personal finance tracker.\nTrack spending, loans, savings & more.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Built for Shiva Karthik ❤️',
                    style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                  ),
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

  Future<void> _exportData(BuildContext context) async {
    try {
      final data = LocalDatabase.exportAllData();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/beconscious_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'BeConscious Backup',
        text: 'My BeConscious financial data backup',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      final txns = LocalDatabase.getAllTransactions();
      final buffer = StringBuffer();
      buffer.writeln(
          'Date,Time,Type,Amount,Description,Tags,Money Source,For Whom,Payment Mode,Notes');
      for (final t in txns) {
        buffer.writeln(
            '"${t.dateTime.toIso8601String().split('T')[0]}","${t.dateTime.toIso8601String().split('T')[1].split('.')[0]}","${t.type.name}","${t.amount}","${t.description}","${t.tags.join(', ')}","${t.moneySourcePerson}","${t.beneficiaryPerson}","${t.paymentMode.name}","${t.notes ?? ''}"');
      }

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/beconscious_transactions_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'BeConscious Transactions',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showImportInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
            'To import data, place your backup JSON file in the device storage and tap "Import".\n\nNote: Imported data will be merged with existing data without duplicates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
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
                  width: 40,
                  height: 4,
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
                                decoration: const InputDecoration(
                                    hintText: 'Tag name'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const Text('Cancel'),
                                ),
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
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: tags.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppTheme.primaryColor.withOpacity(0.15),
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
                  width: 40,
                  height: 4,
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
                                decoration: const InputDecoration(
                                    hintText: 'Person name'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const Text('Cancel'),
                                ),
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
            'This will permanently delete ALL your transactions, loans, and savings goals. This action cannot be undone.\n\nPlease export a backup first if needed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await LocalDatabase.init(); // Ensure boxes are open
              // Clear all boxes
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
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
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

