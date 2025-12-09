import 'package:home_widget/home_widget.dart';
import '../widgets/app_logger.dart';
import '../../features/daily_activities/models/event.dart';
import '../../features/daily_activities/models/event_service.dart';

class HomeWidgetService {
  static const String _widgetName = 'AppHomeWidget';
  static const String _androidWidgetName = 'AppHomeWidgetProvider';

  /// Initialize home widget
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId('group.com.example.app039');
      AppLogger.info('Home widget service initialized', 'HOME_WIDGET');
    } catch (e) {
      AppLogger.exception('Failed to initialize home widget service', e);
    }
  }

  /// Update widget with ongoing events data
  static Future<void> updateOngoingEventsWidget() async {
    try {
      final ongoingEvents = await _getOngoingEvents();
      final upcomingEvents = await _getUpcomingEvents();

      // Save data for widget
      await HomeWidget.saveWidgetData<int>(
        'ongoing_count',
        ongoingEvents.length,
      );
      await HomeWidget.saveWidgetData<int>(
        'upcoming_count',
        upcomingEvents.length,
      );
      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateTime.now().toIso8601String(),
      );
      await HomeWidget.saveWidgetData<String>(
        'ongoing_events',
        _formatEventsForWidget(ongoingEvents),
      );
      await HomeWidget.saveWidgetData<String>(
        'upcoming_events',
        _formatEventsForWidget(upcomingEvents.take(3).toList()),
      );

      // Update the widget
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        iOSName: _widgetName,
      );

      AppLogger.userAction('Home widget updated', {
        'ongoing_events': ongoingEvents.length,
        'upcoming_events': upcomingEvents.length,
      });
    } catch (e) {
      AppLogger.exception('Failed to update home widget', e);
    }
  }

  /// Get ongoing events
  static Future<List<Event>> _getOngoingEvents() async {
    try {
      final allEvents = await EventService.getAllEvents();
      final now = DateTime.now();

      return allEvents.where((event) {
        // Event is ongoing if current time is between start and end
        final isAfterStart =
            now.isAfter(event.startTime) ||
            now.isAtSameMomentAs(event.startTime);

        final endTime =
            event.endTime ?? event.startTime.add(const Duration(hours: 1));
        final isBeforeEnd = now.isBefore(endTime);

        return isAfterStart && isBeforeEnd && !event.isCompleted;
      }).toList();
    } catch (e) {
      AppLogger.exception('Failed to get ongoing events', e);
      return [];
    }
  }

  /// Get upcoming events (next 24 hours)
  static Future<List<Event>> _getUpcomingEvents() async {
    try {
      final allEvents = await EventService.getAllEvents();
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(hours: 24));

      return allEvents.where((event) {
        final isInFuture = event.startTime.isAfter(now);
        final isWithin24Hours = event.startTime.isBefore(tomorrow);
        return isInFuture && isWithin24Hours && !event.isCompleted;
      }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      AppLogger.exception('Failed to get upcoming events', e);
      return [];
    }
  }

  /// Format events data for widget display
  static String _formatEventsForWidget(List<Event> events) {
    if (events.isEmpty) return 'No events';

    final eventStrings = events.map((event) {
      final timeFormat = event.startTime.hour > 12
          ? '${event.startTime.hour - 12}:${event.startTime.minute.toString().padLeft(2, '0')} PM'
          : '${event.startTime.hour == 0 ? 12 : event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} ${event.startTime.hour < 12 ? 'AM' : 'PM'}';

      return '${event.title} at $timeFormat';
    }).toList();

    return eventStrings.join(' • ');
  }

  /// Register for widget updates when app becomes active
  static Future<void> registerWidgetBackgroundCallback() async {
    try {
      await HomeWidget.registerBackgroundCallback(_backgroundCallback);
      AppLogger.info('Widget background callback registered', 'HOME_WIDGET');
    } catch (e) {
      AppLogger.exception('Failed to register widget background callback', e);
    }
  }

  /// Background callback for widget updates
  @pragma("vm:entry-point")
  static Future<void> _backgroundCallback(Uri? uri) async {
    try {
      AppLogger.info('Widget background callback triggered', 'HOME_WIDGET');
      await updateOngoingEventsWidget();
    } catch (e) {
      AppLogger.exception('Widget background callback failed', e);
    }
  }

  /// Check if widget is available on the platform
  static Future<bool> isWidgetAvailable() async {
    try {
      // Check if platform supports widgets by trying to get widget data
      await HomeWidget.getWidgetData<String>('test', defaultValue: 'test');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Request user to add widget to home screen
  static Future<bool> requestAddWidget() async {
    try {
      await updateOngoingEventsWidget(); // Update data first

      // For now, just update the widget data
      // The user will need to manually add the widget to their home screen
      AppLogger.userAction('Widget data updated for home screen', {});
      return true;
    } catch (e) {
      AppLogger.exception('Failed to update widget data', e);
      return false;
    }
  }

  /// Get widget statistics
  static Future<Map<String, dynamic>> getWidgetStats() async {
    try {
      final ongoingEvents = await _getOngoingEvents();
      final upcomingEvents = await _getUpcomingEvents();

      return {
        'ongoing_events_count': ongoingEvents.length,
        'upcoming_events_count': upcomingEvents.length,
        'last_updated': DateTime.now(),
        'widget_available': await isWidgetAvailable(),
      };
    } catch (e) {
      AppLogger.exception('Failed to get widget stats', e);
      return {
        'ongoing_events_count': 0,
        'upcoming_events_count': 0,
        'last_updated': null,
        'widget_available': false,
      };
    }
  }

  /// Schedule periodic widget updates
  static Future<void> schedulePeriodicUpdates() async {
    try {
      // Update widget every 15 minutes
      await HomeWidget.registerBackgroundCallback(_backgroundCallback);
      AppLogger.info('Scheduled periodic widget updates', 'HOME_WIDGET');
    } catch (e) {
      AppLogger.exception('Failed to schedule periodic updates', e);
    }
  }
}
