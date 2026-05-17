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
import '../../presentation/screens/mindspace/mind_space_screen.dart';
import '../../presentation/widgets/shell_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Smooth slide-up page transition for detail screens
CustomTransitionPage _slideUpPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(0, 0.05), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

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
          path: '/mindspace',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MindSpaceScreen()),
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
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return _slideUpPage(
          AddTransactionScreen(editTransaction: extra?['transaction']),
          state,
        );
      },
    ),
    GoRoute(
      path: '/add-loan',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return _slideUpPage(AddLoanScreen(editLoan: extra?['loan']), state);
      },
    ),
    GoRoute(
      path: '/loan-detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        return _slideUpPage(
          LoanDetailScreen(loanId: state.pathParameters['id']!),
          state,
        );
      },
    ),
    GoRoute(
      path: '/add-savings',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return _slideUpPage(AddSavingsScreen(editGoal: extra?['goal']), state);
      },
    ),
    GoRoute(
      path: '/savings-detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        return _slideUpPage(
          SavingsDetailScreen(goalId: state.pathParameters['id']!),
          state,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _slideUpPage(const SettingsScreen(), state),
    ),
  ],
);
