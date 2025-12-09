import 'package:flutter/material.dart';
import '../../features/daily_activities/models/event.dart';

class EventStatusColors {
  static Color getBackgroundColor(
    EventStatus status, {
    bool isDarkTheme = false,
  }) {
    final baseColor = _getBaseColor(status);
    if (isDarkTheme) {
      return Color.alphaBlend(baseColor.withOpacity(0.15), Colors.black);
    }
    return baseColor.withOpacity(0.2);
  }

  static Color getChipColor(EventStatus status) {
    return _getBaseColor(status);
  }

  static Color _getBaseColor(EventStatus status) {
    switch (status) {
      case EventStatus.notStarted:
        return Colors.orange; // Yellow-orange for better visibility
      case EventStatus.ongoing:
        return Colors.blue;
      case EventStatus.completed:
        return Colors.green;
    }
  }

  static Color getTextColor(EventStatus status, {bool isDarkTheme = false}) {
    if (isDarkTheme) {
      switch (status) {
        case EventStatus.notStarted:
          return Colors.orange[300]!;
        case EventStatus.ongoing:
          return Colors.blue[300]!;
        case EventStatus.completed:
          return Colors.green[300]!;
      }
    }
    return _getBaseColor(status);
  }
}
