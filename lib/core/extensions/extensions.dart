import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

extension DateTimeExtension on DateTime {
  /// Is this date today?
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Is this date yesterday?
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Is this date in the same month as now?
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Is this date in the same year as now?
  bool get isThisYear {
    return year == DateTime.now().year;
  }

  /// Formatted string
  String get formatted => AppConstants.formatDate(this);
  String get formattedShort => AppConstants.formatDateShort(this);
}

extension DoubleExtension on double {
  /// Format as Indian currency
  String get asCurrency => AppConstants.formatCurrency(this);
  String get asCurrencyShort => AppConstants.formatCurrencyShort(this);
}

extension StringExtension on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

extension ColorExtension on Color {
  /// Get a lighter version
  Color lighter([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Get a darker version
  Color darker([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}

