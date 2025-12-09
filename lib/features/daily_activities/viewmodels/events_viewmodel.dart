import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../models/event_service.dart';
import '../../../core/widgets/event_timer_service.dart';
import '../../../core/services/notification_service.dart';

class EventsState {
  final List<Event> events;
  final bool isLoading;
  final String? error;

  const EventsState({
    this.events = const [],
    this.isLoading = false,
    this.error,
  });

  EventsState copyWith({List<Event>? events, bool? isLoading, String? error}) {
    return EventsState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EventsNotifier extends StateNotifier<EventsState> {
  EventsNotifier() : super(const EventsState()) {
    // Delay loading to ensure Hive is initialized
    Future.delayed(const Duration(milliseconds: 100), () async {
      await loadEvents();
    });
  }

  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final events = await EventService.getAllEvents();
      state = state.copyWith(events: events, isLoading: false);
      await checkMissedEvents();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> checkMissedEvents() async {
    try {
      final updatedMissedEvents =
          await EventService.checkAndUpdateMissedEvents();
      if (updatedMissedEvents.isNotEmpty) {
        final updatedEvents = state.events.map((event) {
          final missedEvent = updatedMissedEvents.firstWhere(
            (e) => e.id == event.id,
            orElse: () => event,
          );
          return missedEvent;
        }).toList();

        state = state.copyWith(events: updatedEvents);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to check missed events: $e');
    }
  }

  String? checkEventOverlap(Event newEvent, {String? excludeEventId}) {
    final eventsOnSameDate = state.events.where((event) {
      if (excludeEventId != null && event.id == excludeEventId) return false;
      return event.date.year == newEvent.date.year &&
          event.date.month == newEvent.date.month &&
          event.date.day == newEvent.date.day;
    }).toList();

    for (final existingEvent in eventsOnSameDate) {
      if (existingEvent.endTime == null || newEvent.endTime == null) continue;

      if (newEvent.startTime.isBefore(existingEvent.endTime!) &&
          newEvent.endTime!.isAfter(existingEvent.startTime)) {
        return 'This event overlaps with "${existingEvent.title}"';
      }
    }

    return null;
  }

  DateTime? suggestNextAvailableTime(Event newEvent, {String? excludeEventId}) {
    if (newEvent.endTime == null) return null;

    final eventsOnSameDate = state.events.where((event) {
      if (excludeEventId != null && event.id == excludeEventId) return false;
      return event.date.year == newEvent.date.year &&
          event.date.month == newEvent.date.month &&
          event.date.day == newEvent.date.day;
    }).toList();

    if (eventsOnSameDate.isEmpty) return null;

    eventsOnSameDate.sort((a, b) => a.startTime.compareTo(b.startTime));

    DateTime currentTime = DateTime(
      newEvent.date.year,
      newEvent.date.month,
      newEvent.date.day,
      0,
      0,
    );

    final neededDuration = newEvent.endTime!.difference(newEvent.startTime);

    for (final event in eventsOnSameDate) {
      if (event.endTime == null) continue;

      final gapDuration = event.startTime.difference(currentTime);
      if (gapDuration >= neededDuration) return currentTime;
      currentTime = event.endTime!;
    }

    final endOfDay = DateTime(
      newEvent.date.year,
      newEvent.date.month,
      newEvent.date.day,
      23,
      59,
    );

    final gapAfterLast = endOfDay.difference(currentTime);
    if (gapAfterLast >= neededDuration) return currentTime;
    return null;
  }

  Future<void> addEvent(Event event) async {
    final overlapError = checkEventOverlap(event);
    if (overlapError != null) throw Exception(overlapError);

    try {
      await EventService.addEvent(event);
      final updatedEvents = [...state.events, event]
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      state = state.copyWith(events: updatedEvents);
      EventTimerService.updateEvents(updatedEvents);
      await _scheduleEventNotifications(event);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateEvent(Event event) async {
    final overlapError = checkEventOverlap(event, excludeEventId: event.id);
    if (overlapError != null) throw Exception(overlapError);

    try {
      final autoStatus = event.getAutoUpdatedStatus();
      final eventToSave = autoStatus != event.status
          ? event.copyWith(status: autoStatus, updatedAt: DateTime.now())
          : event;

      // Handle live activities based on status change
      // final oldEvent = state.events.firstWhere((e) => e.id == event.id);
      // if (oldEvent.status != eventToSave.status) {
      //   if (eventToSave.status == EventStatus.ongoing) {
      //     // Start live activity when event becomes ongoing
      //     try {
      //       await LiveActivitiesService.startLiveActivityForEvent(eventToSave);
      //     } catch (e) {
      //       print('Failed to start live activity: $e');
      //     }
      //   } else if (eventToSave.status == EventStatus.completed) {
      //     // End live activity when event is completed
      //     try {
      //       await LiveActivitiesService.endLiveActivity(eventToSave.id);
      //     } catch (e) {
      //       print('Failed to end live activity: $e');
      //     }
      //   }
      // }

      await EventService.updateEvent(eventToSave);
      final updatedEvents =
          state.events
              .map((e) => e.id == eventToSave.id ? eventToSave : e)
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
      state = state.copyWith(events: updatedEvents);
      EventTimerService.updateEvents(updatedEvents);
      await _scheduleEventNotifications(eventToSave);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await EventService.deleteEvent(id);
      final updatedEvents = state.events.where((e) => e.id != id).toList();
      state = state.copyWith(events: updatedEvents);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markEventCompleted(String id) async {
    try {
      await EventService.markEventCompleted(id);
      final updatedEvents = state.events.map((e) {
        if (e.id == id)
          return e.copyWith(isCompleted: true, updatedAt: DateTime.now());
        return e;
      }).toList();
      state = state.copyWith(events: updatedEvents);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleEventCompletion(String id) async {
    try {
      final event = state.events.firstWhere((e) => e.id == id);
      final updatedEvent = event.copyWith(
        isCompleted: !event.isCompleted,
        updatedAt: DateTime.now(),
      );
      await EventService.updateEvent(updatedEvent);
      final updatedEvents = state.events
          .map((e) => e.id == id ? updatedEvent : e)
          .toList();
      state = state.copyWith(events: updatedEvents);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  List<Event> getEventsByDate(DateTime date) {
    final list = state.events.where((event) {
      return event.date.year == date.year &&
          event.date.month == date.month &&
          event.date.day == date.day;
    }).toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  List<Event> getTodayEvents() => getEventsByDate(DateTime.now());

  List<Event> getUpcomingEvents({int limit = 5}) {
    final now = DateTime.now();
    final list = state.events
        .where((event) => event.startTime.isAfter(now))
        .toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list.take(limit).toList();
  }

  Future<void> clearAllEvents() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await EventService.clearAllEvents();
      await loadEvents();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateEventStatus(String id, EventStatus status) async {
    try {
      await EventService.updateEventStatus(id, status);
      final updatedEvents = state.events.map((event) {
        if (event.id == id)
          return event.copyWith(status: status, updatedAt: DateTime.now());
        return event;
      }).toList();
      state = state.copyWith(events: updatedEvents);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void updateEventsFromTimer(List<Event> updatedEvents) {
    state = state.copyWith(events: updatedEvents);
  }

  Future<void> _scheduleEventNotifications(Event event) async {
    final notificationService = NotificationService();
    final now = DateTime.now();

    await notificationService.cancelNotification(event.id.hashCode + 1000);
    await notificationService.cancelNotification(event.id.hashCode + 2000);
    await notificationService.cancelNotification(event.id.hashCode + 3000);

    if (event.isCompleted || event.status == EventStatus.completed) return;

    final timeUntilStart = event.startTime.difference(now);

    if (timeUntilStart.inMinutes > 5) {
      final reminderTime = event.startTime.subtract(const Duration(minutes: 5));
      await notificationService.scheduleNotification(
        id: event.id.hashCode + 1000,
        title: 'Event Starting Soon! ⏰',
        body: '"${event.title}" starts in 5 minutes',
        scheduledDate: reminderTime,
        payload: 'event_reminder:${event.id}',
      );
    }

    if (timeUntilStart.inMinutes >= 0) {
      await notificationService.scheduleNotification(
        id: event.id.hashCode + 2000,
        title: 'Event Starting Now! 🎯',
        body: '"${event.title}" is starting right now',
        scheduledDate: event.startTime,
        payload: 'event_start:${event.id}',
      );
    }
  }
}

final eventsProvider = StateNotifierProvider<EventsNotifier, EventsState>(
  (ref) => EventsNotifier(),
);

final todayEventsProvider = Provider<List<Event>>((ref) {
  final eventsState = ref.watch(eventsProvider);
  final today = DateTime.now();
  final list = eventsState.events.where((event) {
    return event.date.year == today.year &&
        event.date.month == today.month &&
        event.date.day == today.day;
  }).toList();
  list.sort((a, b) => a.startTime.compareTo(b.startTime));
  return list;
});

final upcomingEventsProvider = Provider<List<Event>>((ref) {
  final eventsState = ref.watch(eventsProvider);
  final now = DateTime.now();
  final list = eventsState.events
      .where((event) => event.startTime.isAfter(now))
      .toList();
  list.sort((a, b) => a.startTime.compareTo(b.startTime));
  return list.take(5).toList();
});

final eventsByDateProvider = Provider.family<List<Event>, DateTime>((
  ref,
  date,
) {
  final eventsState = ref.watch(eventsProvider);
  final list = eventsState.events.where((event) {
    return event.date.year == date.year &&
        event.date.month == date.month &&
        event.date.day == date.day;
  }).toList();
  list.sort((a, b) => a.startTime.compareTo(b.startTime));
  return list;
});
