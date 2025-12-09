import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/daily_activities/models/event.dart';
import '../../features/daily_activities/viewmodels/events_viewmodel.dart';
import '../../features/notes/viewmodels/notes_viewmodel.dart';

import '../../features/journal/viewmodels/journal_viewmodel.dart';

// Optimized dashboard summary data
class DashboardSummary {
  final int totalEvents;
  final int todayEvents;
  final int totalNotes;
  final int pinnedNotes;

  const DashboardSummary({
    required this.totalEvents,
    required this.todayEvents,
    required this.totalNotes,
    required this.pinnedNotes,
  });
}

// Cached providers for better performance

final cachedEventsSummaryProvider = Provider<Map<String, int>>((ref) {
  final eventsState = ref.watch(eventsProvider);
  final today = DateTime.now();

  int totalEvents = eventsState.events.length;
  int todayEvents = 0;

  for (final event in eventsState.events) {
    if (event.date.year == today.year &&
        event.date.month == today.month &&
        event.date.day == today.day) {
      todayEvents++;
    }
  }

  return {'totalEvents': totalEvents, 'todayEvents': todayEvents};
});

final cachedNotesSummaryProvider = Provider<Map<String, int>>((ref) {
  final notesState = ref.watch(notesProvider);

  int totalNotes = notesState.notes.length;
  int pinnedNotes = notesState.notes.where((note) => note.isPinned).length;

  return {'totalNotes': totalNotes, 'pinnedNotes': pinnedNotes};
});

// Optimized dashboard provider using cached summaries
final optimizedDashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final eventsSummary = ref.watch(cachedEventsSummaryProvider);
  final notesSummary = ref.watch(cachedNotesSummaryProvider);

  return DashboardSummary(
    totalEvents: eventsSummary['totalEvents']!,
    todayEvents: eventsSummary['todayEvents']!,
    totalNotes: notesSummary['totalNotes']!,
    pinnedNotes: notesSummary['pinnedNotes']!,
  );
});

// Enhanced recent activities provider - sorts by execution date, includes all activity types
final recentActivitiesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final eventsState = ref.watch(eventsProvider);
  final notesState = ref.watch(notesProvider);
  final journalState = ref.watch(journalProvider);

  final activities = <Map<String, dynamic>>[];
  // Look back only 2 weeks instead of 3 to optimize data loading
  final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
  final now = DateTime.now();

  // Add events - sort by start time (execution date)
  for (var event in eventsState.events) {
    if (event.startTime.isAfter(twoWeeksAgo)) {
      final description = event.description.isNotEmpty
          ? event.description
          : 'Event scheduled for ${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}';

      activities.add({
        'type': 'event',
        'id': event.id,
        'title': event.title,
        'description': description,
        'executionTime': event.startTime, // Use start time for sorting
        'status': _getEventActivityStatus(event, now),
        'label': 'Event',
      });
    }
  }

  // Add notes - sort by updated date
  for (var note in notesState.notes) {
    if (note.updatedAt.isAfter(twoWeeksAgo)) {
      final description = note.content.isNotEmpty
          ? (note.content.length > 50
                ? '${note.content.substring(0, 50)}...'
                : note.content)
          : 'No content';

      activities.add({
        'type': 'note',
        'id': note.id,
        'title': note.title,
        'description': description,
        'executionTime': note.updatedAt, // Use updated date for sorting
        'status': 'no_status', // Notes don't have status
        'label': 'Note',
      });
    }
  }

  // Add journal entries - sort by created date
  for (var journal in journalState.entries) {
    if (journal.createdAt.isAfter(twoWeeksAgo)) {
      final description = journal.content.isNotEmpty
          ? (journal.content.length > 50
                ? '${journal.content.substring(0, 50)}...'
                : journal.content)
          : 'No content';

      activities.add({
        'type': 'journal',
        'id': journal.id,
        'title': journal.title,
        'description': description,
        'executionTime': journal.createdAt, // Use created date for sorting
        'status': 'no_status', // Journal entries don't have status
        'label': 'Journal',
      });
    }
  }

  // Sort by execution time (most recent first)
  activities.sort(
    (a, b) => (b['executionTime'] as DateTime).compareTo(
      a['executionTime'] as DateTime,
    ),
  );

  // Return top 10 most recent activities
  return activities.take(10).toList();
});

// Helper function to determine event activity status
String _getEventActivityStatus(Event event, DateTime now) {
  // If explicitly completed
  if (event.isCompleted || event.status == EventStatus.completed) {
    return 'completed';
  }

  // If ongoing
  if (event.status == EventStatus.ongoing) {
    return 'ongoing';
  }

  // For not started events
  if (event.status == EventStatus.notStarted) {
    if (event.startTime.isAfter(now)) {
      return 'upcoming';
    } else {
      // Event was supposed to start but hasn't - consider it ongoing if end time hasn't passed
      if (event.endTime != null && event.endTime!.isBefore(now)) {
        return 'completed';
      }
      return 'ongoing'; // Could be started now
    }
  }

  // Default - for past events that are not explicitly completed, consider them completed
  if (event.endTime != null && event.endTime!.isBefore(now)) {
    return 'completed';
  }

  return 'ongoing';
}

// Additional providers for charts
final completedEventsCountProvider = Provider<int>((ref) {
  final eventsState = ref.watch(eventsProvider);
  final now = DateTime.now();

  return eventsState.events.where((event) {
    // If explicitly completed
    if (event.isCompleted || event.status == EventStatus.completed) {
      return true;
    }

    // If event has ended and not marked as completed, consider it completed
    if (event.endTime != null && event.endTime!.isBefore(now)) {
      return true;
    }

    return false;
  }).length;
});

final totalEventsCountProvider = Provider<int>((ref) {
  final eventsState = ref.watch(eventsProvider);
  return eventsState.events.length;
});

// Time-series data for charts
class TimeSeriesData {
  final DateTime date;
  final int eventCount;
  final int journalCount;
  final int noteCount;

  const TimeSeriesData({
    required this.date,
    required this.eventCount,
    this.journalCount = 0,
    this.noteCount = 0,
  });
}

// Events time-series data for the last 7 days
final eventsTimeSeriesProvider = Provider<List<TimeSeriesData>>((ref) {
  final eventsState = ref.watch(eventsProvider);
  final now = DateTime.now();
  final List<TimeSeriesData> data = [];

  // Generate data for the last 7 days
  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    int dayEventCount = 0;

    for (final event in eventsState.events) {
      if (event.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          event.date.isBefore(dayEnd)) {
        dayEventCount++;
      }
    }

    data.add(
      TimeSeriesData(
        date: dayStart,
        // Will be filled by financial provider
        eventCount: dayEventCount,
      ),
    );
  }

  return data;
});

// Journal time-series data for the last 7 days
final journalTimeSeriesProvider = Provider<List<TimeSeriesData>>((ref) {
  final journalsState = ref.watch(journalProvider);
  final now = DateTime.now();
  final List<TimeSeriesData> data = [];

  // Generate data for the last 7 days
  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    int dayJournalCount = 0;

    for (final journal in journalsState.entries) {
      if (journal.createdAt.isAfter(
            dayStart.subtract(const Duration(seconds: 1)),
          ) &&
          journal.createdAt.isBefore(dayEnd)) {
        dayJournalCount++;
      }
    }

    data.add(
      TimeSeriesData(
        date: dayStart,
        eventCount: 0, // Will be filled by combined provider
        journalCount: dayJournalCount,
      ),
    );
  }

  return data;
});

// Notes time-series data for the last 7 days
final notesTimeSeriesProvider = Provider<List<TimeSeriesData>>((ref) {
  final notesState = ref.watch(notesProvider);
  final now = DateTime.now();
  final List<TimeSeriesData> data = [];

  // Generate data for the last 7 days
  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    int dayNoteCount = 0;

    for (final note in notesState.notes) {
      if (note.createdAt.isAfter(
            dayStart.subtract(const Duration(seconds: 1)),
          ) &&
          note.createdAt.isBefore(dayEnd)) {
        dayNoteCount++;
      }
    }

    data.add(
      TimeSeriesData(
        date: dayStart,
        eventCount: 0, // Will be filled by combined provider
        journalCount: 0, // Will be filled by combined provider
        noteCount: dayNoteCount,
      ),
    );
  }

  return data;
});

// Combined time-series data provider
final combinedTimeSeriesProvider = Provider<List<TimeSeriesData>>((ref) {
  final eventsData = ref.watch(eventsTimeSeriesProvider);
  final journalData = ref.watch(journalTimeSeriesProvider);
  final notesData = ref.watch(notesTimeSeriesProvider);

  return List.generate(7, (index) {
    return TimeSeriesData(
      date: eventsData[index].date,
      eventCount: eventsData[index].eventCount,
      journalCount: journalData[index].journalCount,
      noteCount: notesData[index].noteCount,
    );
  });
});
