import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PopCalculator extends StatefulWidget {
  const PopCalculator({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PopCalculator(),
    );
  }

  @override
  State<PopCalculator> createState() => _PopCalculatorState();
}

class _PopCalculatorState extends State<PopCalculator> {
  String _display = '0';
  String _expression = '';
  double? _result;
  String _operator = '';
  bool _newNumber = true;

  void _onDigit(String d) {
    setState(() {
      if (_display == 'Error') {
        _onClear();
      }
      if (_newNumber) {
        _display = d;
        _newNumber = false;
      } else {
        if (_display == '0' && d != '.') {
          _display = d;
        } else {
          _display += d;
        }
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      final current = double.tryParse(_display) ?? 0;
      if (_result == null) {
        _result = current;
      } else if (!_newNumber) {
        _result = _calculate(_result!, current, _operator);
      }
      _operator = op;
      _expression = '${_formatNum(_result!)} $op';
      _display = _formatNum(_result!);
      _newNumber = true;
    });
  }

  void _onEquals() {
    setState(() {
      final current = double.tryParse(_display) ?? 0;
      if (_result != null && _operator.isNotEmpty) {
        _result = _calculate(_result!, current, _operator);
        _expression = '';
        _display = _formatNum(_result!);
        _operator = '';
        _newNumber = true;
      }
    });
  }

  double _calculate(double a, double b, String op) {
    switch (op) {
      case '+': return a + b;
      case '−': return a - b;
      case '×': return a * b;
      case '÷': return b != 0 ? a / b : double.nan;
      default: return b;
    }
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _expression = '';
      _result = null;
      _operator = '';
      _newNumber = true;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
        _newNumber = true;
      }
    });
  }

  void _onPercent() {
    setState(() {
      final current = double.tryParse(_display) ?? 0;
      _display = _formatNum(current / 100);
    });
  }

  void _onNegate() {
    setState(() {
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else if (_display != '0') {
        _display = '-$_display';
      }
    });
  }

  String _formatNum(double n) {
    if (n.isNaN) return 'Error';
    if (n.isInfinite) return 'Error';
    if (n == n.roundToDouble() && n.abs() < 1e15) return n.toInt().toString();
    return n.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Calculator', style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textSecondary)),
              // Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_expression.isNotEmpty)
                      Text(
                        _expression,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _display,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    _row(['C', '±', '%', '÷']),
                    _row(['7', '8', '9', '×']),
                    _row(['4', '5', '6', '−']),
                    _row(['1', '2', '3', '+']),
                    _row(['⌫', '0', '.', '=']),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(List<String> btns) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: btns.map((b) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _CalcButton(
              label: b,
              onTap: () => _handleTap(b),
              isOperator: ['÷', '×', '−', '+'].contains(b),
              isSpecial: ['C', '±', '%', '⌫'].contains(b),
              isEquals: b == '=',
            ),
          ),
        )).toList(),
      ),
    );
  }

  void _handleTap(String b) {
    if ('0123456789'.contains(b)) {
      _onDigit(b);
    } else if (b == '.') {
      if (!_display.contains('.')) _onDigit('.');
    } else if (['+', '−', '×', '÷'].contains(b)) {
      _onOperator(b);
    } else if (b == '=') {
      _onEquals();
    } else if (b == 'C') {
      _onClear();
    } else if (b == '⌫') {
      _onBackspace();
    } else if (b == '%') {
      _onPercent();
    } else if (b == '±') {
      _onNegate();
    }
  }
}

class _CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOperator;
  final bool isSpecial;
  final bool isEquals;

  const _CalcButton({
    required this.label,
    required this.onTap,
    this.isOperator = false,
    this.isSpecial = false,
    this.isEquals = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (isEquals) {
      bg = AppTheme.accent1;
      fg = AppTheme.backgroundDark;
    } else if (isOperator) {
      bg = AppTheme.accent2.withOpacity(0.15);
      fg = AppTheme.accent2;
    } else if (isSpecial) {
      bg = Colors.white.withOpacity(0.08);
      fg = AppTheme.textSecondary;
    } else {
      bg = Colors.white.withOpacity(0.05);
      fg = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isEquals ? 26 : 22,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

