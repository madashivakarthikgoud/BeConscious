import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../data/datasources/local/local_database.dart';

/// Handles all data export/import for backup and phone migration
class BackupService {
  /// Export ALL app data as a single JSON file and share it
  static Future<String?> exportData() async {
    try {
      final data = LocalDatabase.exportAllData();
      final json = const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final fileName = 'BeConscious_Backup_$timestamp.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'BeConscious Backup - $timestamp',
        text: 'My BeConscious financial data backup. Import this file in BeConscious app on any phone to restore all data.',
      );

      return null; // success
    } catch (e) {
      return 'Export failed: $e';
    }
  }


  /// Import data from a backup JSON file
  /// Merges with existing data (won't create duplicates for same IDs)
  static Future<String?> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return 'No file selected';
      }

      final filePath = result.files.single.path;
      if (filePath == null) return 'Could not read file';

      final file = File(filePath);
      if (!file.existsSync()) return 'File not found';

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate it's a BeConscious backup
      if (!data.containsKey('transactions') && !data.containsKey('loans') && !data.containsKey('savings')) {
        return 'Invalid backup file. This does not look like a BeConscious backup.';
      }

      await LocalDatabase.importAllData(data);

      // Count imported items
      int count = 0;
      if (data['transactions'] != null) count += (data['transactions'] as List).length;
      if (data['loans'] != null) count += (data['loans'] as List).length;
      if (data['savings'] != null) count += (data['savings'] as List).length;
      if (data['mindSpace'] != null) count += (data['mindSpace'] as List).length;

      return 'SUCCESS:$count'; // special success format
    } catch (e) {
      return 'Import failed: $e';
    }
  }

  /// Get data summary for display
  static Map<String, int> getDataSummary() {
    return {
      'transactions': LocalDatabase.getAllTransactions().length,
      'loans': LocalDatabase.getAllLoans().length,
      'savings': LocalDatabase.getAllSavingsGoals().length,
      'mindItems': LocalDatabase.getAllMindItems().length,
      'tags': LocalDatabase.getAllTags().length,
      'persons': LocalDatabase.getAllPersons().length,
    };
  }
}
