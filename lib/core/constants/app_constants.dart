import 'package:intl/intl.dart';

class AppConstants {
  static const String appName = 'BeConscious';
  static const String currency = '₹';

  static String formatCurrency(double amount) {
    if (amount.isNaN || amount.isInfinite) return '${currency}0.00';
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: currency,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatCurrencyShort(double amount) {
    if (amount.isNaN || amount.isInfinite) return '${currency}0';
    final isNegative = amount < 0;
    final abs = amount.abs();
    String result;
    if (abs >= 10000000) {
      result = '$currency${(abs / 10000000).toStringAsFixed(2)}Cr';
    } else if (abs >= 100000) {
      result = '$currency${(abs / 100000).toStringAsFixed(2)}L';
    } else if (abs >= 1000) {
      result = '$currency${(abs / 1000).toStringAsFixed(1)}K';
    } else {
      return formatCurrency(amount);
    }
    return isNegative ? '-$result' : result;
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (dateOnly == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (date.year == now.year) return DateFormat('dd MMM').format(date);
    return DateFormat('dd MMM yy').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatDateTime(DateTime date) {
    return '${formatDateShort(date)}, ${formatTime(date)}';
  }
}

