import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static const bool _isDebugMode = kDebugMode;

  /// Debug level logs - only shown in debug mode
  static void debug(String message, [String? tag]) {
    if (_isDebugMode) {
      _log(LogLevel.debug, message, tag);
    }
  }

  /// Info level logs - general information
  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }

  /// Warning level logs - potential issues
  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }

  /// Error level logs - critical errors
  static void error(
    String message, [
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.error, message, tag);
    if (error != null) {
      debugPrint('Error details: $error');
    }
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Firebase/Firestore specific logs
  static void firebase(String message, [String? operation]) {
    debug(message, 'FIREBASE${operation != null ? '-$operation' : ''}');
  }

  /// Authentication specific logs
  static void auth(String message, [String? userId]) {
    debug('${userId != null ? '[User: $userId] ' : ''}$message', 'AUTH');
  }

  /// Events specific logs
  static void event(String message, [String? eventId]) {
    debug('${eventId != null ? '[Event: $eventId] ' : ''}$message', 'EVENTS');
  }

  /// Network specific logs
  static void network(String message, [String? endpoint]) {
    debug('${endpoint != null ? '[$endpoint] ' : ''}$message', 'NETWORK');
  }

  /// Private method to handle actual logging
  static void _log(LogLevel level, String message, String? tag) {
    final timestamp = DateTime.now().toIso8601String();
    final levelString = level.name.toUpperCase().padRight(7);
    final tagString = tag != null ? '[$tag] ' : '';

    final logMessage = '$timestamp $levelString $tagString$message';

    switch (level) {
      case LogLevel.debug:
        debugPrint('🔍 $logMessage');
        break;
      case LogLevel.info:
        debugPrint('ℹ️ $logMessage');
        break;
      case LogLevel.warning:
        debugPrint('⚠️ $logMessage');
        break;
      case LogLevel.error:
        debugPrint('❌ $logMessage');
        break;
    }
  }

  /// Log exception with detailed information
  static void exception(
    String context,
    dynamic exception, [
    StackTrace? stackTrace,
  ]) {
    error(
      'Exception in $context: $exception',
      'EXCEPTION',
      exception,
      stackTrace,
    );
  }

  /// Log user actions for debugging
  static void userAction(String action, [Map<String, dynamic>? data]) {
    final dataString = data != null ? ' Data: $data' : '';
    info('User action: $action$dataString', 'USER_ACTION');
  }

  /// Log performance metrics
  static void performance(
    String operation,
    Duration duration, [
    Map<String, dynamic>? metrics,
  ]) {
    final metricsString = metrics != null ? ' Metrics: $metrics' : '';
    info(
      'Performance: $operation took ${duration.inMilliseconds}ms$metricsString',
      'PERFORMANCE',
    );
  }
}
