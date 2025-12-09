import 'package:uuid/uuid.dart';

class IdGenerator {
  static const _uuid = Uuid();

  static String generate() {
    return _uuid.v4();
  }
}

class DateTimeUtils {
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String formatDate(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at ${formatTime(dateTime)}';
  }
}

class CurrencyUtils {
  static String format(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  static String formatWithSign(double amount) {
    if (amount >= 0) {
      return '+${format(amount)}';
    } else {
      return '-${format(amount.abs())}';
    }
  }
}

class ValidationUtils {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(phone);
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    return null;
  }
}

class AppConstants {
  static const String appName = 'Daily Tracker';
  static const String appVersion = '1.0.0';

  // Default categories
  static const List<String> eventCategories = [
    'Work',
    'Personal',
    'Health',
    'Education',
    'Social',
    'Travel',
    'Other',
  ];

  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Other',
  ];

  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Gift',
    'Other',
  ];

  static const List<String> taskCategories = [
    'Work',
    'Personal',
    'Health',
    'Home',
    'Shopping',
    'Study',
    'Other',
  ];

  static const List<String> noteCategories = [
    'Ideas',
    'Reminders',
    'Goals',
    'Learning',
    'Projects',
    'Personal',
    'Other',
  ];
}
