import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/transaction_model.dart';
import '../../models/loan_model.dart';
import '../../models/savings_model.dart';

class LocalDatabase {
  static const String _transactionsBox = 'transactions';
  static const String _loansBox = 'loans';
  static const String _savingsBox = 'savings';
  static const String _tagsBox = 'tags';
  static const String _personsBox = 'persons';
  static const String _settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_transactionsBox);
    await Hive.openBox(_loansBox);
    await Hive.openBox(_savingsBox);
    await Hive.openBox<String>(_tagsBox);
    await Hive.openBox<String>(_personsBox);
    await Hive.openBox(_settingsBox);

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
    return _txnBox.values.map((e) {
      return TransactionModel.fromJson(jsonDecode(e as String));
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
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
    return _loanBox.values.map((e) {
      return LoanModel.fromJson(jsonDecode(e as String));
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
    return _savBox.values.map((e) {
      return SavingsGoalModel.fromJson(jsonDecode(e as String));
    }).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
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
    final key = _tagBox.keys.firstWhere(
      (k) => _tagBox.get(k) == tag,
      orElse: () => null,
    );
    if (key != null) await _tagBox.delete(key);
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
    final key = _personBox.keys.firstWhere(
      (k) => _personBox.get(k) == person,
      orElse: () => null,
    );
    if (key != null) await _personBox.delete(key);
  }

  // ==================== SETTINGS ====================

  static Box get _setBox => Hive.box(_settingsBox);

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return _setBox.get(key, defaultValue: defaultValue);
  }

  static Future<void> setSetting(String key, dynamic value) async {
    await _setBox.put(key, value);
  }

  // ==================== EXPORT ALL DATA ====================

  static Map<String, dynamic> exportAllData() {
    return {
      'transactions': getAllTransactions().map((t) => t.toJson()).toList(),
      'loans': getAllLoans().map((l) => l.toJson()).toList(),
      'savings': getAllSavingsGoals().map((s) => s.toJson()).toList(),
      'tags': getAllTags(),
      'persons': getAllPersons(),
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static Future<void> importAllData(Map<String, dynamic> data) async {
    if (data['transactions'] != null) {
      for (final t in data['transactions']) {
        await saveTransaction(TransactionModel.fromJson(t));
      }
    }
    if (data['loans'] != null) {
      for (final l in data['loans']) {
        await saveLoan(LoanModel.fromJson(l));
      }
    }
    if (data['savings'] != null) {
      for (final s in data['savings']) {
        await saveSavingsGoal(SavingsGoalModel.fromJson(s));
      }
    }
    if (data['tags'] != null) {
      for (final t in data['tags']) {
        final existing = getAllTags();
        if (!existing.contains(t)) await addTag(t);
      }
    }
    if (data['persons'] != null) {
      for (final p in data['persons']) {
        final existing = getAllPersons();
        if (!existing.contains(p)) await addPerson(p);
      }
    }
  }
}

