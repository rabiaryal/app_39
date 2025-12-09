import 'package:flutter/material.dart';

/// Parses natural language input for quick add functionality
class NaturalLanguageParser {
  /// Parse transaction input like "Coffee $5.50" or "Starbucks 5.50"
  static ParsedTransaction? parseTransaction(String input) {
    final text = input.trim();

    // Pattern: "description $amount" or "description amount"
    final patterns = [
      RegExp(r'^(.+?)\s+\$(\d+\.?\d*)$'), // "Coffee $5.50"
      RegExp(r'^(.+?)\s+(\d+\.?\d*)$'), // "Coffee 5.50"
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final description = match.group(1)!.trim();
        final amount = double.tryParse(match.group(2)!);

        if (amount != null) {
          return ParsedTransaction(
            description: description,
            amount: amount,
            category: _guessCategory(description),
          );
        }
      }
    }

    return null;
  }

  /// Parse event input like "Meeting with John tomorrow 3pm"
  static ParsedEvent? parseEvent(String input) {
    final text = input.toLowerCase().trim();
    DateTime? date;
    TimeOfDay? time;
    String title = input.trim();

    // Extract time (3pm, 15:00, 3:30pm, etc.)
    final timePatterns = [
      RegExp(r'(\d{1,2}):?(\d{2})?\s*(am|pm)', caseSensitive: false),
      RegExp(r'(\d{1,2})\s*(am|pm)', caseSensitive: false),
    ];

    for (final pattern in timePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
        final period = match.group(3) ?? match.group(2);

        if (period != null && period.toLowerCase() == 'pm' && hour < 12) {
          hour += 12;
        } else if (period != null &&
            period.toLowerCase() == 'am' &&
            hour == 12) {
          hour = 0;
        }

        time = TimeOfDay(hour: hour, minute: minute);
        title = text.replaceAll(match.group(0)!, '').trim();
        break;
      }
    }

    // Extract date (today, tomorrow, monday, etc.)
    final now = DateTime.now();

    if (text.contains('today')) {
      date = now;
      title = title
          .replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '')
          .trim();
    } else if (text.contains('tomorrow')) {
      date = now.add(const Duration(days: 1));
      title = title
          .replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '')
          .trim();
    } else if (text.contains('next week')) {
      date = now.add(const Duration(days: 7));
      title = title
          .replaceAll(RegExp(r'\bnext week\b', caseSensitive: false), '')
          .trim();
    }

    // Check for specific dates like "Oct 15" or "October 15"
    final datePattern = RegExp(
      r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+(\d{1,2})\b',
      caseSensitive: false,
    );
    final dateMatch = datePattern.firstMatch(text);
    if (dateMatch != null) {
      final monthStr = dateMatch.group(1)!;
      final day = int.parse(dateMatch.group(2)!);
      final month = _parseMonth(monthStr);

      if (month != null) {
        date = DateTime(now.year, month, day);
        if (date.isBefore(now)) {
          date = DateTime(now.year + 1, month, day);
        }
        title = text.replaceAll(dateMatch.group(0)!, '').trim();
      }
    }

    if (title.isEmpty) {
      title = input.trim();
    }

    return ParsedEvent(title: title, date: date, time: time);
  }

  /// Parse task input like "Call dentist high" or "Buy groceries tomorrow"
  static ParsedTask? parseTask(String input) {
    final text = input.toLowerCase().trim();
    String title = input.trim();
    String? priority;
    DateTime? dueDate;

    // Extract priority
    if (text.contains('high') || text.contains('urgent')) {
      priority = 'high';
      title = title
          .replaceAll(RegExp(r'\bhigh\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\burgent\b', caseSensitive: false), '')
          .trim();
    } else if (text.contains('low')) {
      priority = 'low';
      title = title
          .replaceAll(RegExp(r'\blow\b', caseSensitive: false), '')
          .trim();
    } else {
      priority = 'medium';
    }

    // Extract date
    final now = DateTime.now();
    if (text.contains('today')) {
      dueDate = now;
      title = title
          .replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '')
          .trim();
    } else if (text.contains('tomorrow')) {
      dueDate = now.add(const Duration(days: 1));
      title = title
          .replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '')
          .trim();
    } else if (text.contains('next week')) {
      dueDate = now.add(const Duration(days: 7));
      title = title
          .replaceAll(RegExp(r'\bnext week\b', caseSensitive: false), '')
          .trim();
    }

    return ParsedTask(title: title, priority: priority, dueDate: dueDate);
  }

  /// Parse appointment input like "Doctor Oct 15 at 2pm"
  static ParsedAppointment? parseAppointment(String input) {
    // Reuse event parsing logic
    final event = parseEvent(input);
    if (event != null) {
      return ParsedAppointment(
        title: event.title,
        date: event.date,
        time: event.time,
      );
    }
    return null;
  }

  static String _guessCategory(String description) {
    final lower = description.toLowerCase();

    // Food & Dining
    if (lower.contains('coffee') ||
        lower.contains('lunch') ||
        lower.contains('dinner') ||
        lower.contains('breakfast') ||
        lower.contains('restaurant') ||
        lower.contains('starbucks') ||
        lower.contains('food')) {
      return 'Food & Dining';
    }

    // Transportation
    if (lower.contains('gas') ||
        lower.contains('uber') ||
        lower.contains('lyft') ||
        lower.contains('taxi') ||
        lower.contains('parking') ||
        lower.contains('transport')) {
      return 'Transportation';
    }

    // Shopping
    if (lower.contains('amazon') ||
        lower.contains('shop') ||
        lower.contains('store') ||
        lower.contains('mall')) {
      return 'Shopping';
    }

    // Entertainment
    if (lower.contains('movie') ||
        lower.contains('cinema') ||
        lower.contains('game') ||
        lower.contains('netflix') ||
        lower.contains('spotify')) {
      return 'Entertainment';
    }

    return 'Other';
  }

  static int? _parseMonth(String month) {
    const months = {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };

    return months[month.toLowerCase()];
  }
}

class ParsedTransaction {
  final String description;
  final double amount;
  final String category;

  ParsedTransaction({
    required this.description,
    required this.amount,
    required this.category,
  });
}

class ParsedEvent {
  final String title;
  final DateTime? date;
  final TimeOfDay? time;

  ParsedEvent({required this.title, this.date, this.time});
}

class ParsedTask {
  final String title;
  final String priority;
  final DateTime? dueDate;

  ParsedTask({required this.title, required this.priority, this.dueDate});
}

class ParsedAppointment {
  final String title;
  final DateTime? date;
  final TimeOfDay? time;

  ParsedAppointment({required this.title, this.date, this.time});
}
