import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _tabs = [
    '/home',
    '/transactions',
    '/loans',
    '/savings',
    '/analytics',
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) => context.go(_tabs[i]),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handshake_rounded),
              activeIcon: Icon(Icons.handshake_rounded),
              label: 'Loans',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.savings_rounded),
              activeIcon: Icon(Icons.savings_rounded),
              label: 'Savings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'Analytics',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showQuickAddSheet(context);
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Add',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.remove_circle_outline,
                  label: 'Expense',
                  color: AppTheme.expenseColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/add-transaction',
                        extra: {'type': 'expense'});
                  },
                ),
                const SizedBox(width: 16),
                _QuickAction(
                  icon: Icons.add_circle_outline,
                  label: 'Income',
                  color: AppTheme.incomeColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/add-transaction',
                        extra: {'type': 'income'});
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.handshake_rounded,
                  label: 'Loan',
                  color: AppTheme.loanTakenColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/add-loan');
                  },
                ),
                const SizedBox(width: 16),
                _QuickAction(
                  icon: Icons.savings_rounded,
                  label: 'Savings',
                  color: AppTheme.savingsColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/add-savings');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

