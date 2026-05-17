import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Reusable screen header with title and optional trailing widget
class ScreenHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const ScreenHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.xl, AppTheme.lg, AppTheme.xl, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: AppTheme.headlineMedium),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Reusable type toggle tab (used in AddTransaction and AddLoan)
class TypeToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const TypeToggleTab({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: color.withOpacity(0.4))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? color : AppTheme.textMuted, size: 20),
              const SizedBox(width: AppTheme.sm),
              Text(label,
                  style: AppTheme.titleMedium.copyWith(
                    color: isSelected ? color : AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable glass date picker button
class GlassDatePickerButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const GlassDatePickerButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppTheme.lg),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Text(text, style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Reusable form label style
TextStyle get formLabelStyle => AppTheme.labelLarge;

/// Reusable full-width action button
class FullWidthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  const FullWidthButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: backgroundColor != null
            ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
            : null,
        child: Text(label),
      ),
    );
  }
}

/// Reusable bottom sheet handle
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Reusable empty state widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: iconSize, color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: AppTheme.lg),
            Text(title, style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted)),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.xs),
              Text(subtitle!,
                  style: AppTheme.labelSmall,
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AppTheme.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Reusable metric card (used in HomeScreen twin cards, LoansScreen summary, etc.)
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
            border: Border.all(
              color: Colors.white.withOpacity(AppTheme.glassBorderOpacity),
            ),
            color: Colors.white.withOpacity(AppTheme.glassOpacity),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: AppTheme.sm),
                  Expanded(
                    child: Text(label,
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(value,
                  style: AppTheme.amountMedium.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable detail row for info screens
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const DetailRow(
    this.label,
    this.value, {
    super.key,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label, style: AppTheme.labelMedium),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            color: valueColor ?? Colors.white70,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

/// Reusable status badge (used in LoansScreen)
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.xl),
      ),
      child: Text(
        label,
        style: AppTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Reusable "add new item" dialog
Future<void> showAddItemDialog({
  required BuildContext context,
  required String title,
  required String hint,
  required ValueChanged<String> onAdd,
}) {
  final ctrl = TextEditingController();
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (ctrl.text.trim().isNotEmpty) {
              onAdd(ctrl.text.trim());
              Navigator.pop(ctx);
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

/// Priority color map used in MindSpace and HomeScreen
const Map<String, Color> priorityColorMap = {
  'low': AppTheme.incomeColor,
  'medium': AppTheme.loanTakenColor,
  'high': AppTheme.expenseColor,
};

/// Chart color palette used in analytics
const List<Color> chartColors = [
  AppTheme.accent1,
  AppTheme.expenseColor,
  AppTheme.incomeColor,
  AppTheme.loanTakenColor,
  AppTheme.loanGivenColor,
  AppTheme.savingsColor,
  Color(0xFF00BCD4), // cyan
  Color(0xFFFFC107), // amber
];

