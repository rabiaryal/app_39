import 'dart:async';
import '../../features/daily_activities/models/event.dart';
import '../../features/daily_activities/models/event_service.dart';
import '../services/notification_service.dart';
import '../services/live_activities_service.dart';

class EventTimerService {
  static Timer? _timer;
  static List<Event> _events = [];
  static Function(List<Event>)? _onEventsUpdated;
  static bool _isInitialized = false;

  static void initialize(
    List<Event> events,
    Function(List<Event>) onEventsUpdated,
  ) {
    if (_isInitialized) {
      updateEvents(events);
      return;
    }

    _events = events;
    _onEventsUpdated = onEventsUpdated;
    _isInitialized = true;
    _startPersistentTimer();
  }

  static void updateEvents(List<Event> events) {
    _events = events;
  }

  static void dispose() {
    _timer?.cancel();
    _timer = null;
    _onEventsUpdated = null;
    _isInitialized = false;
  }

  // Persistent timer that survives screen changes
  static void _startPersistentTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAndUpdateEventStatuses();
      _scheduleUpcomingNotifications();
    });

    // Also check immediately when starting
    _checkAndUpdateEventStatuses();
    _scheduleUpcomingNotifications();
  }

  static Future<void> _checkAndUpdateEventStatuses() async {
    bool hasUpdates = false;
    final now = DateTime.now();

    for (int i = 0; i < _events.length; i++) {
      final event = _events[i];
      Event? updatedEvent;

      // Auto-start events (within 1 minute of start time)
      if (event.shouldAutoStart &&
          now.difference(event.startTime).inMinutes.abs() <= 1) {
        updatedEvent = event.copyWith(
          status: EventStatus.ongoing,
          actualStartTime: now,
          updatedAt: now,
        );
        // Cancel any existing notifications and schedule new ones for ongoing event
        await cancelEventNotifications(event);
      }
      // Auto-complete events (within 1 minute after end time)
      else if (event.shouldAutoComplete &&
          event.effectiveEndTime != null &&
          now.difference(event.effectiveEndTime!).inMinutes.abs() <= 1) {
        final wasCompleted = event.status == EventStatus.ongoing;
        updatedEvent = event.copyWith(
          status: EventStatus.completed,
          actualEndTime: now,
          isCompleted: true,
          updatedAt: now,
        );

        // Cancel ongoing timer notifications and schedule end notification
        await cancelEventNotifications(event);
        await _scheduleEndOfEventNotification(updatedEvent, wasCompleted);
      }

      if (updatedEvent != null) {
        // Handle live activities for automatic status changes
        if (updatedEvent.status == EventStatus.ongoing &&
            event.status != EventStatus.ongoing) {
          // Event just started - start live activity
          try {
            await LiveActivitiesService.startLiveActivityForEvent(updatedEvent);
          } catch (e) {
            print('Failed to start live activity for auto-started event: $e');
          }
        } else if (updatedEvent.status == EventStatus.completed &&
            event.status == EventStatus.ongoing) {
          // Event just completed - end live activity
          try {
            await LiveActivitiesService.endLiveActivity(updatedEvent.id);
          } catch (e) {
            print('Failed to end live activity for auto-completed event: $e');
          }
        }

        _events[i] = updatedEvent;
        await EventService.updateEvent(updatedEvent);
        hasUpdates = true;
      }
    }

    if (hasUpdates && _onEventsUpdated != null) {
      _onEventsUpdated!(_events);
    }
  }

  static Future<void> _scheduleUpcomingNotifications() async {
    final notificationService = NotificationService();
    final now = DateTime.now();

    for (final event in _events) {
      // Skip completed events
      if (event.isCompleted || event.status == EventStatus.completed) continue;

      final timeUntilStart = event.startTime.difference(now);

      // Schedule reminder 5 minutes before event
      if (timeUntilStart.inMinutes <= 5 && timeUntilStart.inMinutes > 0) {
        final reminderTime = event.startTime.subtract(
          const Duration(minutes: 5),
        );
        if (reminderTime.isAfter(now)) {
          try {
            await notificationService.scheduleNotification(
              id: event.id.hashCode + 1000,
              title: 'Event Starting Soon! ⏰',
              body: '"${event.title}" starts in 5 minutes',
              scheduledDate: reminderTime,
              payload: 'event_reminder:${event.id}',
            );
          } catch (e) {
            // Log the error but don't crash the app
            print(
              'Failed to schedule reminder notification for event ${event.id}: $e',
            );
          }
        }
      }

      // Schedule start notification (at exact start time)
      if (timeUntilStart.inMinutes <= 1 && timeUntilStart.inMinutes >= 0) {
        // Only schedule if the start time is still in the future
        if (event.startTime.isAfter(now)) {
          try {
            await notificationService.scheduleNotification(
              id: event.id.hashCode + 2000,
              title: 'Event Starting Now! 🎯',
              body: '"${event.title}" is starting right now',
              scheduledDate: event.startTime,
              payload: 'event_start:${event.id}',
            );
          } catch (e) {
            // Log the error but don't crash the app
            print(
              'Failed to schedule start notification for event ${event.id}: $e',
            );
          }
        }
      }

      // Schedule ongoing timer notifications for active events
      if (event.status == EventStatus.ongoing && event.endTime != null) {
        await _scheduleOngoingTimerNotifications(event);
      }
    }
  }

  static Future<void> _scheduleOngoingTimerNotifications(Event event) async {
    final notificationService = NotificationService();
    final now = DateTime.now();

    if (event.endTime == null || event.status != EventStatus.ongoing) return;

    final remainingTime = event.remainingTime;
    if (remainingTime == null || remainingTime <= Duration.zero) return;

    // Schedule timer notifications every minute for the remaining duration
    final minutesRemaining = remainingTime.inMinutes;

    for (int i = 1; i <= minutesRemaining && i <= 30; i++) {
      // Limit to 30 minutes
      final notificationTime = now.add(Duration(minutes: i));
      if (notificationTime.isBefore(event.endTime!)) {
        final timeAtNotification = remainingTime - Duration(minutes: i);
        final hours = timeAtNotification.inHours;
        final minutes = timeAtNotification.inMinutes.remainder(60);

        String timeText;
        if (hours > 0) {
          timeText = '${hours}h ${minutes}m remaining';
        } else {
          timeText = '${minutes}m remaining';
        }

        try {
          await notificationService.scheduleNotification(
            id:
                event.id.hashCode +
                4000 +
                i, // Unique ID for each timer notification
            title: '⏱️ $event.title',
            body: '$timeText',
            scheduledDate: notificationTime,
            payload: 'event_timer:${event.id}:$i',
          );
        } catch (e) {
          print(
            'Failed to schedule timer notification for event ${event.id}: $e',
          );
        }
      }
    }
  }

  static Future<void> _scheduleEndOfEventNotification(
    Event event,
    bool wasCompleted,
  ) async {
    final notificationService = NotificationService();

    // Schedule end-of-event notification immediately
    final notificationTime = DateTime.now().add(const Duration(seconds: 5));

    String title;
    String body;

    if (wasCompleted) {
      title = 'Event Completed! 🎉';
      body = '"${event.title}" has been completed successfully!';
    } else {
      title = 'Event Time Over ⏰';
      body = '"${event.title}" time is over. Status: Not Started';
    }

    try {
      await notificationService.scheduleNotification(
        id: event.id.hashCode + 5000,
        title: title,
        body: body,
        scheduledDate: notificationTime,
        payload:
            'event_end:${event.id}:${wasCompleted ? 'completed' : 'not_started'}',
      );
    } catch (e) {
      print(
        'Failed to schedule end-of-event notification for event ${event.id}: $e',
      );
    }
  }

  static Future<Event> pauseEvent(Event event) async {
    final now = DateTime.now();
    final updatedEvent = event.copyWith(
      status: EventStatus.ongoing,
      pausedAt: now,
      updatedAt: now,
    );
    await EventService.updateEvent(updatedEvent);

    // Update local events list
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = updatedEvent;
    }

    return updatedEvent;
  }

  static Future<Event> resumeEvent(Event event) async {
    final now = DateTime.now();
    Duration totalPausedDuration = event.pausedDuration ?? Duration.zero;

    if (event.pausedAt != null) {
      totalPausedDuration =
          totalPausedDuration + now.difference(event.pausedAt!);
    }

    final updatedEvent = event.copyWith(
      status: EventStatus.ongoing,
      pausedDuration: totalPausedDuration,
      pausedAt: null,
      updatedAt: now,
    );
    await EventService.updateEvent(updatedEvent);

    // Update local events list
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = updatedEvent;
    }

    return updatedEvent;
  }

  static Future<void> cancelEventNotifications(Event event) async {
    final notificationService = NotificationService();

    // Cancel all event-related notifications
    await notificationService.cancelNotification(
      event.id.hashCode + 1000,
    ); // 5-minute reminder
    await notificationService.cancelNotification(
      event.id.hashCode + 2000,
    ); // Start notification
    await notificationService.cancelNotification(
      event.id.hashCode + 5000,
    ); // End notification

    // Cancel ongoing timer notifications (up to 30)
    for (int i = 1; i <= 30; i++) {
      await notificationService.cancelNotification(
        event.id.hashCode + 4000 + i,
      );
    }
  }
}
