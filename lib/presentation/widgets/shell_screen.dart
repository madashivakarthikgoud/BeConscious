import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'pop_calculator.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _tabs = [
    '/home',
    '/transactions',
    '/loans',
    '/savings',
    '/mindspace',
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
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark.withOpacity(0.85),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: idx,
              onTap: (i) {
                HapticFeedback.selectionClick();
                context.go(_tabs[i]);
              },
              selectedFontSize: 10,
              unselectedFontSize: 10,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_rounded),
                  label: 'Txns',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.handshake_rounded),
                  label: 'Loans',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.savings_rounded),
                  label: 'Savings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.psychology_rounded),
                  label: 'Mind',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_rounded),
                  label: 'Analytics',
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent1.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showQuickAddSheet(context);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF152A1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Add',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.north_east_rounded,
                  label: 'Expense',
                  color: AppTheme.expenseColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/add-transaction', extra: {'type': 'expense'});
                  },
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.south_west_rounded,
                  label: 'Income',
                  color: AppTheme.incomeColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/add-transaction', extra: {'type': 'income'});
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
                const SizedBox(width: 12),
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
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.psychology_rounded,
                  label: 'Mind Note',
                  color: AppTheme.accent2,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/mindspace');
                  },
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.calculate_rounded,
                  label: 'Calculator',
                  color: AppTheme.accent1,
                  onTap: () {
                    Navigator.pop(ctx);
                    PopCalculator.show(context);
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
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
