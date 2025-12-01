import 'package:intl/intl.dart';

class NumberFormatter {
  // Format number with commas
  static String formatWithCommas(num number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  // Format currency
  static String formatCurrency(num amount, {String symbol = '\$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  // Format compact number (1K, 1M, etc.)
  static String formatCompact(num number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  // Format percentage
  static String formatPercentage(num value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    } else if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '$bytes B';
  }

  // Format decimal places
  static String formatDecimal(num number, {int decimals = 2}) {
    return number.toStringAsFixed(decimals);
  }

  // Parse string to number safely
  static num? parseNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    return num.tryParse(value.replaceAll(',', ''));
  }

  // Format ordinal numbers (1st, 2nd, 3rd, etc.)
  static String formatOrdinal(int number) {
    if (number % 100 >= 11 && number % 100 <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
}
