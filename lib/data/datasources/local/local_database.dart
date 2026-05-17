import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/transaction_model.dart';
import '../../models/loan_model.dart';
import '../../models/savings_model.dart';
import '../../models/mind_space_model.dart';

class LocalDatabase {
  static const String _transactionsBox = 'transactions';
  static const String _loansBox = 'loans';
  static const String _savingsBox = 'savings';
  static const String _tagsBox = 'tags';
  static const String _personsBox = 'persons';
  static const String _settingsBox = 'settings';
  static const String _mindSpaceBox = 'mindspace';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_transactionsBox);
    await Hive.openBox(_loansBox);
    await Hive.openBox(_savingsBox);
    await Hive.openBox<String>(_tagsBox);
    await Hive.openBox<String>(_personsBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_mindSpaceBox);

    // Initialize default tags
    final tagsBox = Hive.box<String>(_tagsBox);
    if (tagsBox.isEmpty) {
      final defaults = [
        'Food', 'Transport', 'Shopping', 'Medical', 'Entertainment',
        'Bills', 'Groceries', 'Education', 'Rent', 'Fuel',
        'Recharge', 'Clothing', 'Gifts', 'Travel', 'Other',
      ];
      for (int i = 0; i < defaults.length; i++) {
        await tagsBox.put('tag_$i', defaults[i]);
      }
    }

    // Initialize default persons
    final personsBox = Hive.box<String>(_personsBox);
    if (personsBox.isEmpty) {
      await personsBox.put('person_0', 'Self');
      await personsBox.put('person_1', 'Father');
      await personsBox.put('person_2', 'Mother');
    }
  }

  // ==================== TRANSACTIONS ====================

  static Box get _txnBox => Hive.box(_transactionsBox);

  static Future<void> saveTransaction(TransactionModel txn) async {
    await _txnBox.put(txn.id, jsonEncode(txn.toJson()));
  }

  static Future<void> deleteTransaction(String id) async {
    await _txnBox.delete(id);
  }

  static List<TransactionModel> getAllTransactions() {
    final results = <TransactionModel>[];
    for (final e in _txnBox.values) {
      try {
        results.add(TransactionModel.fromJson(jsonDecode(e as String)));
      } catch (_) {
        // Skip corrupted entries silently
      }
    }
    results.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return results;
  }

  static List<TransactionModel> getTransactionsByDateRange(
      DateTime start, DateTime end) {
    return getAllTransactions()
        .where((t) =>
            t.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.dateTime.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  // ==================== LOANS ====================

  static Box get _loanBox => Hive.box(_loansBox);

  static Future<void> saveLoan(LoanModel loan) async {
    await _loanBox.put(loan.id, jsonEncode(loan.toJson()));
  }

  static Future<void> deleteLoan(String id) async {
    await _loanBox.delete(id);
  }

  static List<LoanModel> getAllLoans() {
    final results = <LoanModel>[];
    for (final e in _loanBox.values) {
      try {
        results.add(LoanModel.fromJson(jsonDecode(e as String)));
      } catch (_) {
        // Skip corrupted entries silently
      }
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  // ==================== SAVINGS ====================

  static Box get _savBox => Hive.box(_savingsBox);

  static Future<void> saveSavingsGoal(SavingsGoalModel goal) async {
    await _savBox.put(goal.id, jsonEncode(goal.toJson()));
  }

  static Future<void> deleteSavingsGoal(String id) async {
    await _savBox.delete(id);
  }

  static List<SavingsGoalModel> getAllSavingsGoals() {
    final results = <SavingsGoalModel>[];
    for (final e in _savBox.values) {
      try {
        results.add(SavingsGoalModel.fromJson(jsonDecode(e as String)));
      } catch (_) {
        // Skip corrupted entries silently
      }
    }
    results.sort((a, b) => a.deadline.compareTo(b.deadline));
    return results;
  }

  // ==================== TAGS ====================

  static Box<String> get _tagBox => Hive.box<String>(_tagsBox);

  static List<String> getAllTags() {
    return _tagBox.values.toList();
  }

  static Future<void> addTag(String tag) async {
    final key = 'tag_${DateTime.now().millisecondsSinceEpoch}';
    await _tagBox.put(key, tag);
  }

  static Future<void> removeTag(String tag) async {
    for (final key in _tagBox.keys) {
      if (_tagBox.get(key) == tag) {
        await _tagBox.delete(key);
        return;
      }
    }
  }

  // ==================== PERSONS ====================

  static Box<String> get _personBox => Hive.box<String>(_personsBox);

  static List<String> getAllPersons() {
    return _personBox.values.toList();
  }

  static Future<void> addPerson(String person) async {
    final key = 'person_${DateTime.now().millisecondsSinceEpoch}';
    await _personBox.put(key, person);
  }

  static Future<void> removePerson(String person) async {
    for (final key in _personBox.keys) {
      if (_personBox.get(key) == person) {
        await _personBox.delete(key);
        return;
      }
    }
  }

  // ==================== SETTINGS ====================

  static Box get _setBox => Hive.box(_settingsBox);

  /// Type-safe setting retrieval — callers must check type at boundary
  static Object? getSetting(String key, {Object? defaultValue}) {
    return _setBox.get(key, defaultValue: defaultValue);
  }

  static Future<void> setSetting(String key, Object value) async {
    await _setBox.put(key, value);
  }

  // ==================== EXPORT ALL DATA ====================

  static Map<String, dynamic> exportAllData() {
    return {
      'transactions': getAllTransactions().map((t) => t.toJson()).toList(),
      'loans': getAllLoans().map((l) => l.toJson()).toList(),
      'savings': getAllSavingsGoals().map((s) => s.toJson()).toList(),
      'mindSpace': getAllMindItems().map((m) => m.toJson()).toList(),
      'tags': getAllTags(),
      'persons': getAllPersons(),
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static Future<void> importAllData(Map<String, dynamic> data) async {
    if (data['transactions'] is List) {
      for (final t in data['transactions'] as List) {
        try {
          await saveTransaction(
              TransactionModel.fromJson(t as Map<String, dynamic>));
        } catch (_) {}
      }
    }
    if (data['loans'] is List) {
      for (final l in data['loans'] as List) {
        try {
          await saveLoan(LoanModel.fromJson(l as Map<String, dynamic>));
        } catch (_) {}
      }
    }
    if (data['savings'] is List) {
      for (final s in data['savings'] as List) {
        try {
          await saveSavingsGoal(
              SavingsGoalModel.fromJson(s as Map<String, dynamic>));
        } catch (_) {}
      }
    }
    if (data['tags'] is List) {
      for (final t in data['tags'] as List) {
        try {
          final tag = t as String;
          final existing = getAllTags();
          if (!existing.contains(tag)) await addTag(tag);
        } catch (_) {}
      }
    }
    if (data['persons'] is List) {
      for (final p in data['persons'] as List) {
        try {
          final person = p as String;
          final existing = getAllPersons();
          if (!existing.contains(person)) await addPerson(person);
        } catch (_) {}
      }
    }
    if (data['mindSpace'] is List) {
      for (final m in data['mindSpace'] as List) {
        try {
          await saveMindItem(
              MindSpaceItem.fromJson(m as Map<String, dynamic>));
        } catch (_) {}
      }
    }
  }

  // ==================== MIND SPACE ====================

  static Box get _mindBox => Hive.box(_mindSpaceBox);

  static Future<void> saveMindItem(MindSpaceItem item) async {
    await _mindBox.put(item.id, jsonEncode(item.toJson()));
  }

  static Future<void> deleteMindItem(String id) async {
    await _mindBox.delete(id);
  }

  static List<MindSpaceItem> getAllMindItems() {
    final results = <MindSpaceItem>[];
    for (final e in _mindBox.values) {
      try {
        results.add(MindSpaceItem.fromJson(jsonDecode(e as String)));
      } catch (_) {}
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  /// Clear all user data (transactions, loans, savings, mind items)
  static Future<void> clearAll() async {
    await _txnBox.clear();
    await _loanBox.clear();
    await _savBox.clear();
    await _mindBox.clear();
  }

  /// Clear absolutely everything including tags, persons, and settings
  static Future<void> clearEverything() async {
    await _txnBox.clear();
    await _loanBox.clear();
    await _savBox.clear();
    await _mindBox.clear();
    await _tagBox.clear();
    await _personBox.clear();
  }
}
