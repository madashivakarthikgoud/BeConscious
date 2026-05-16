import 'package:intl/intl.dart';

class AppConstants {
  static const String appName = 'BeConscious';
  static const String currency = '₹';

  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: currency,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatCurrencyShort(double amount) {
    if (amount >= 10000000) {
      return '${currency}${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '${currency}${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${currency}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatCurrency(amount);
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

