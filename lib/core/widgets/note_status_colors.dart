import 'package:flutter/material.dart';
import '../../features/notes/models/note.dart';

class NoteStatusColors {
  static Color getBackgroundColor(
    NoteStatus status, {
    bool isDarkTheme = false,
  }) {
    final baseColor = _getBaseColor(status);
    if (isDarkTheme) {
      return Color.alphaBlend(baseColor.withOpacity(0.15), Colors.black);
    }
    return baseColor.withOpacity(0.2);
  }

  static Color getChipColor(NoteStatus status) {
    return _getBaseColor(status);
  }

  static Color _getBaseColor(NoteStatus status) {
    switch (status) {
      case NoteStatus.notStarted:
        return Colors.orange; // Yellow-orange for better visibility
      case NoteStatus.active:
        return Colors.blue;
      case NoteStatus.done:
        return Colors.green;
      case NoteStatus.urgent:
        return Colors.red;
    }
  }

  static Color getTextColor(NoteStatus status, {bool isDarkTheme = false}) {
    if (isDarkTheme) {
      switch (status) {
        case NoteStatus.notStarted:
          return Colors.orange[300]!;
        case NoteStatus.active:
          return Colors.blue[300]!;
        case NoteStatus.done:
          return Colors.green[300]!;
        case NoteStatus.urgent:
          return Colors.red[300]!;
      }
    }
    return _getBaseColor(status);
  }
}
