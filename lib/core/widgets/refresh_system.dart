import 'package:flutter/material.dart';

class AppRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final double strokeWidth;

  const AppRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? (isDark ? Colors.tealAccent : Colors.blue),
      backgroundColor:
          backgroundColor ?? (isDark ? Colors.grey[800] : Colors.white),
      displacement: displacement,
      strokeWidth: strokeWidth,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: child,
    );
  }
}

class AppRefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String? refreshMessage;
  final bool showMessage;

  const AppRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshMessage,
    this.showMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator(
      onRefresh: () async {
        if (showMessage && refreshMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(refreshMessage!),
              duration: const Duration(milliseconds: 800),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        await onRefresh();
      },
      child: child,
    );
  }
}

// Extension to make refresh functionality easier to use
extension RefreshableWidget on Widget {
  Widget withRefresh(Future<void> Function() onRefresh, {String? message}) {
    return AppRefreshWrapper(
      onRefresh: onRefresh,
      refreshMessage: message,
      showMessage: message != null,
      child: this,
    );
  }
}
