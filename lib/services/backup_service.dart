import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/datasources/local/local_database.dart';

/// Handles local backup (JSON export) to share via any app
/// For Google Drive: user can share the exported file to Drive manually
class BackupService {
  /// Export all data to a JSON file and share it
  static Future<void> exportAndShare() async {
    final data = LocalDatabase.exportAllData();
    final json = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/beconscious_backup_$timestamp.json');
    await file.writeAsString(json);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'BeConscious Backup',
      text: 'My BeConscious financial data backup',
    );
  }

  /// Export transactions as CSV
  static Future<void> exportTransactionsCsv() async {
    final txns = LocalDatabase.getAllTransactions();
    final buffer = StringBuffer();
    buffer.writeln(
        'Date,Time,Type,Amount,Description,Tags,Money Source,For Whom,Payment Mode,Notes');
    for (final t in txns) {
      final date = t.dateTime.toIso8601String().split('T')[0];
      final time = t.dateTime.toIso8601String().split('T')[1].split('.')[0];
      buffer.writeln(
          '"$date","$time","${t.type.name}","${t.amount}","${t.description}","${t.tags.join(', ')}","${t.moneySourcePerson}","${t.beneficiaryPerson}","${t.paymentMode.name}","${t.notes ?? ''}"');
    }

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file =
        File('${dir.path}/beconscious_transactions_$timestamp.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'BeConscious Transactions',
    );
  }

  /// Import data from a JSON string
  static Future<int> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      await LocalDatabase.importAllData(data);
      return 0; // success
    } catch (e) {
      return -1; // error
    }
  }
}

