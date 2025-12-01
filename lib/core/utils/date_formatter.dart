import 'package:intl/intl.dart';

class DateFormatter {
  // Format date to readable string
  static String toReadable(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Format date with time
  static String toReadableWithTime(DateTime date) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  // Format to time only
  static String toTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  // Format to short date
  static String toShortDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  // Get relative time (e.g., "2 hours ago")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  // Get day name
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  // Get month name
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  // Format for display (Today, Yesterday, or date)
  static String formatForDisplay(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else {
      return toReadable(date);
    }
  }

  // Islamic date greeting
  static String getIslamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'السلام عليكم (Good Morning)';
    } else if (hour < 17) {
      return 'السلام عليكم (Good Afternoon)';
    } else {
      return 'السلام عليكم (Good Evening)';
    }
  }
}
