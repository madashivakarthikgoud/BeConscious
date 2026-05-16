import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/transactions/transactions_screen.dart';
import '../../presentation/screens/transactions/add_transaction_screen.dart';
import '../../presentation/screens/loans/loans_screen.dart';
import '../../presentation/screens/loans/add_loan_screen.dart';
import '../../presentation/screens/loans/loan_detail_screen.dart';
import '../../presentation/screens/savings/savings_screen.dart';
import '../../presentation/screens/savings/add_savings_screen.dart';
import '../../presentation/screens/savings/savings_detail_screen.dart';
import '../../presentation/screens/analytics/analytics_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/widgets/shell_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/transactions',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TransactionsScreen()),
        ),
        GoRoute(
          path: '/loans',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LoansScreen()),
        ),
        GoRoute(
          path: '/savings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SavingsScreen()),
        ),
        GoRoute(
          path: '/analytics',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AnalyticsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/add-transaction',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AddTransactionScreen(editTransaction: extra?['transaction']);
      },
    ),
    GoRoute(
      path: '/add-loan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AddLoanScreen(editLoan: extra?['loan']);
      },
    ),
    GoRoute(
      path: '/loan-detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return LoanDetailScreen(loanId: state.pathParameters['id']!);
      },
    ),
    GoRoute(
      path: '/add-savings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AddSavingsScreen(editGoal: extra?['goal']);
      },
    ),
    GoRoute(
      path: '/savings-detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return SavingsDetailScreen(goalId: state.pathParameters['id']!);
      },
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

