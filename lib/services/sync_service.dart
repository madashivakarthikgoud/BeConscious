import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/datasources/local/local_database.dart';
import '../data/models/transaction_model.dart';
import '../data/models/loan_model.dart';
import '../data/models/savings_model.dart';

/// Syncs local Hive data ↔ Cloud Firestore (Firebase FREE tier)
/// Call after Firebase.initializeApp() and user is signed in.
class SyncService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> _userCol(String sub) {
    return _db.collection('users').doc(_userId).collection(sub);
  }

  /// Upload all local data to Firestore (batch to save write ops)
  static Future<void> uploadAll() async {
    if (_userId == null) return;

    final batch = _db.batch();

    // Transactions
    for (final t in LocalDatabase.getAllTransactions()) {
      batch.set(_userCol('transactions').doc(t.id), t.toJson());
    }

    // Loans
    for (final l in LocalDatabase.getAllLoans()) {
      batch.set(_userCol('loans').doc(l.id), l.toJson());
    }

    // Savings
    for (final s in LocalDatabase.getAllSavingsGoals()) {
      batch.set(_userCol('savings').doc(s.id), s.toJson());
    }

    // Tags & Persons
    batch.set(_userCol('meta').doc('tags'), {
      'list': LocalDatabase.getAllTags(),
    });
    batch.set(_userCol('meta').doc('persons'), {
      'list': LocalDatabase.getAllPersons(),
    });

    await batch.commit();
  }

  /// Download all cloud data and merge into local
  static Future<void> downloadAll() async {
    if (_userId == null) return;

    // Transactions
    final txnSnap = await _userCol('transactions').get();
    for (final doc in txnSnap.docs) {
      final txn = TransactionModel.fromJson(doc.data());
      await LocalDatabase.saveTransaction(txn);
    }

    // Loans
    final loanSnap = await _userCol('loans').get();
    for (final doc in loanSnap.docs) {
      final loan = LoanModel.fromJson(doc.data());
      await LocalDatabase.saveLoan(loan);
    }

    // Savings
    final savSnap = await _userCol('savings').get();
    for (final doc in savSnap.docs) {
      final goal = SavingsGoalModel.fromJson(doc.data());
      await LocalDatabase.saveSavingsGoal(goal);
    }

    // Tags
    final tagsDoc = await _userCol('meta').doc('tags').get();
    if (tagsDoc.exists) {
      final tags = List<String>.from(tagsDoc.data()!['list'] ?? []);
      final existing = LocalDatabase.getAllTags();
      for (final t in tags) {
        if (!existing.contains(t)) await LocalDatabase.addTag(t);
      }
    }

    // Persons
    final personsDoc = await _userCol('meta').doc('persons').get();
    if (personsDoc.exists) {
      final persons = List<String>.from(personsDoc.data()!['list'] ?? []);
      final existing = LocalDatabase.getAllPersons();
      for (final p in persons) {
        if (!existing.contains(p)) await LocalDatabase.addPerson(p);
      }
    }
  }

  /// Sync a single transaction to cloud
  static Future<void> syncTransaction(TransactionModel txn) async {
    if (_userId == null) return;
    await _userCol('transactions').doc(txn.id).set(txn.toJson());
  }

  /// Sync a single loan to cloud
  static Future<void> syncLoan(LoanModel loan) async {
    if (_userId == null) return;
    await _userCol('loans').doc(loan.id).set(loan.toJson());
  }

  /// Sync a single savings goal to cloud
  static Future<void> syncSavingsGoal(SavingsGoalModel goal) async {
    if (_userId == null) return;
    await _userCol('savings').doc(goal.id).set(goal.toJson());
  }

  /// Delete from cloud
  static Future<void> deleteFromCloud(String collection, String id) async {
    if (_userId == null) return;
    await _userCol(collection).doc(id).delete();
  }
}

