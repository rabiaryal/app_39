import 'package:app_039/core/theme.dart';
import 'package:flutter/material.dart';

enum SnackBarType { success, deleted, error }

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = AppColors.lightSecondary;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case SnackBarType.deleted:
        backgroundColor = AppColors.lightError;
        textColor = Colors.white;
        icon = Icons.delete;
        break;
      case SnackBarType.error:
        backgroundColor = AppColors.lightError;
        textColor = Colors.white;
        icon = Icons.error;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, color: textColor, size: 18),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
      action: null, // Remove default action since we have custom close button
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.success);
  }

  static void showDeleted(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.deleted);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.error);
  }
}
