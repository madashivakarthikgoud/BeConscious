import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/local_database.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/savings_model.dart';

// ==================== TRANSACTIONS ====================

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionNotifier() : super([]) {
    loadAll();
  }

  void loadAll() {
    state = LocalDatabase.getAllTransactions();
  }

  Future<void> add(TransactionModel txn) async {
    await LocalDatabase.saveTransaction(txn);
    loadAll();
  }

  Future<void> update(TransactionModel txn) async {
    await LocalDatabase.saveTransaction(txn);
    loadAll();
  }

  Future<void> delete(String id) async {
    await LocalDatabase.deleteTransaction(id);
    loadAll();
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionModel>>(
  (ref) => TransactionNotifier(),
);

// ==================== LOANS ====================

class LoanNotifier extends StateNotifier<List<LoanModel>> {
  LoanNotifier() : super([]) {
    loadAll();
  }

  void loadAll() {
    state = LocalDatabase.getAllLoans();
  }

  Future<void> add(LoanModel loan) async {
    await LocalDatabase.saveLoan(loan);
    loadAll();
  }

  Future<void> update(LoanModel loan) async {
    await LocalDatabase.saveLoan(loan);
    loadAll();
  }

  Future<void> delete(String id) async {
    await LocalDatabase.deleteLoan(id);
    loadAll();
  }

  Future<void> addPayment(String loanId, LoanPayment payment) async {
    final loan = state.firstWhere((l) => l.id == loanId);
    final updated = loan.copyWith(
      payments: [...loan.payments, payment],
      status: (loan.totalPaid + payment.amount) >= (loan.principalAmount + loan.currentInterest)
          ? LoanStatus.completed
          : loan.status,
    );
    await update(updated);
  }
}

final loanProvider = StateNotifierProvider<LoanNotifier, List<LoanModel>>(
  (ref) => LoanNotifier(),
);

// ==================== SAVINGS ====================

class SavingsNotifier extends StateNotifier<List<SavingsGoalModel>> {
  SavingsNotifier() : super([]) {
    loadAll();
  }

  void loadAll() {
    state = LocalDatabase.getAllSavingsGoals();
  }

  Future<void> add(SavingsGoalModel goal) async {
    await LocalDatabase.saveSavingsGoal(goal);
    loadAll();
  }

  Future<void> update(SavingsGoalModel goal) async {
    await LocalDatabase.saveSavingsGoal(goal);
    loadAll();
  }

  Future<void> delete(String id) async {
    await LocalDatabase.deleteSavingsGoal(id);
    loadAll();
  }

  Future<void> addContribution(
      String goalId, SavingsContribution contribution) async {
    final goal = state.firstWhere((g) => g.id == goalId);
    final updated = goal.copyWith(
      contributions: [...goal.contributions, contribution],
    );
    await update(updated);
  }
}

final savingsProvider =
    StateNotifierProvider<SavingsNotifier, List<SavingsGoalModel>>(
  (ref) => SavingsNotifier(),
);

// ==================== TAGS ====================

class TagNotifier extends StateNotifier<List<String>> {
  TagNotifier() : super([]) {
    loadAll();
  }

  void loadAll() {
    state = LocalDatabase.getAllTags();
  }

  Future<void> add(String tag) async {
    if (!state.contains(tag)) {
      await LocalDatabase.addTag(tag);
      loadAll();
    }
  }

  Future<void> remove(String tag) async {
    await LocalDatabase.removeTag(tag);
    loadAll();
  }
}

final tagProvider = StateNotifierProvider<TagNotifier, List<String>>(
  (ref) => TagNotifier(),
);

// ==================== PERSONS ====================

class PersonNotifier extends StateNotifier<List<String>> {
  PersonNotifier() : super([]) {
    loadAll();
  }

  void loadAll() {
    state = LocalDatabase.getAllPersons();
  }

  Future<void> add(String person) async {
    if (!state.contains(person)) {
      await LocalDatabase.addPerson(person);
      loadAll();
    }
  }

  Future<void> remove(String person) async {
    await LocalDatabase.removePerson(person);
    loadAll();
  }
}

final personProvider = StateNotifierProvider<PersonNotifier, List<String>>(
  (ref) => PersonNotifier(),
);

// ==================== THEME ====================

final isDarkModeProvider = StateProvider<bool>((ref) {
  return LocalDatabase.getSetting('darkMode', defaultValue: true) as bool;
});

// ==================== DERIVED / COMPUTED ====================

final todayTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final all = ref.watch(transactionProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return all.where((t) {
    final d = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
    return d == today;
  }).toList();
});

final thisMonthTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final all = ref.watch(transactionProvider);
  final now = DateTime.now();
  return all
      .where((t) => t.dateTime.year == now.year && t.dateTime.month == now.month)
      .toList();
});

final thisYearTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final all = ref.watch(transactionProvider);
  final now = DateTime.now();
  return all.where((t) => t.dateTime.year == now.year).toList();
});

final todayIncomeProvider = Provider<double>((ref) {
  final txns = ref.watch(todayTransactionsProvider);
  return txns
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final todayExpenseProvider = Provider<double>((ref) {
  final txns = ref.watch(todayTransactionsProvider);
  return txns
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final monthIncomeProvider = Provider<double>((ref) {
  final txns = ref.watch(thisMonthTransactionsProvider);
  return txns
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final monthExpenseProvider = Provider<double>((ref) {
  final txns = ref.watch(thisMonthTransactionsProvider);
  return txns
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final yearIncomeProvider = Provider<double>((ref) {
  final txns = ref.watch(thisYearTransactionsProvider);
  return txns
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final yearExpenseProvider = Provider<double>((ref) {
  final txns = ref.watch(thisYearTransactionsProvider);
  return txns
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final lifetimeIncomeProvider = Provider<double>((ref) {
  final all = ref.watch(transactionProvider);
  return all
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final lifetimeExpenseProvider = Provider<double>((ref) {
  final all = ref.watch(transactionProvider);
  return all
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final activeLoansProvider = Provider<List<LoanModel>>((ref) {
  return ref.watch(loanProvider).where((l) => l.status == LoanStatus.active).toList();
});

final totalLoansTakenDueProvider = Provider<double>((ref) {
  return ref
      .watch(activeLoansProvider)
      .where((l) => l.type == LoanType.taken)
      .fold(0.0, (sum, l) => sum + l.totalDueNow);
});

final totalLoansGivenDueProvider = Provider<double>((ref) {
  return ref
      .watch(activeLoansProvider)
      .where((l) => l.type == LoanType.given)
      .fold(0.0, (sum, l) => sum + l.totalDueNow);
});

final totalSavedProvider = Provider<double>((ref) {
  return ref
      .watch(savingsProvider)
      .fold(0.0, (sum, g) => sum + g.totalSaved);
});

