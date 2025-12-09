import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/daily_activities/models/event.dart';
import '../../features/journal/models/journal_entry.dart';
import '../widgets/app_logger.dart';

/// Service for managing local storage of events using SharedPreferences
class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;

  static const String _eventsKey = 'local_events';
  static const String _pendingSyncKey = 'pending_sync_events';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _journalEntriesKey = 'local_journal_entries';
  static const String _pendingJournalSyncKey = 'pending_sync_journal_entries';

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    try {
      _instance ??= LocalStorageService._();
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
        AppLogger.info('SharedPreferences initialized successfully', 'STORAGE');
      }
      return _instance!;
    } catch (e) {
      AppLogger.exception('Failed to initialize LocalStorageService', e);
      throw Exception('Failed to initialize local storage: $e');
    }
  }

  /// Save an event to local storage
  Future<void> saveEvent(Event event) async {
    try {
      AppLogger.debug('Starting to save event: ${event.id}', 'STORAGE');

      // Ensure SharedPreferences is initialized
      if (_prefs == null) {
        AppLogger.warning(
          'SharedPreferences not initialized, reinitializing',
          'STORAGE',
        );
        await getInstance();
      }

      final events = await getAllEvents();
      AppLogger.debug('Retrieved ${events.length} existing events', 'STORAGE');

      // Remove existing event with same ID if it exists
      final originalCount = events.length;
      events.removeWhere((e) => e.id == event.id);
      if (events.length != originalCount) {
        AppLogger.debug('Removed existing event with same ID', 'STORAGE');
      }

      // Add the new/updated event
      events.add(event);
      AppLogger.debug(
        'Added new event, total events: ${events.length}',
        'STORAGE',
      );

      // Save back to storage
      await _saveEventsToStorage(events);
      AppLogger.debug('Events saved to SharedPreferences', 'STORAGE');

      // Mark as pending sync
      await _addToPendingSync(event.id);
      AppLogger.debug('Event marked as pending sync', 'STORAGE');

      AppLogger.userAction('Event saved locally', {
        'eventId': event.id,
        'title': event.title,
      });
    } catch (e) {
      AppLogger.exception('saveEvent', e);
      throw Exception('Failed to save event locally: $e');
    }
  }

  /// Get all events from local storage
  Future<List<Event>> getAllEvents() async {
    try {
      // Ensure SharedPreferences is initialized
      if (_prefs == null) {
        AppLogger.warning(
          'SharedPreferences not initialized in getAllEvents, reinitializing',
          'STORAGE',
        );
        await getInstance();
      }

      final eventsJson = _prefs!.getString(_eventsKey);
      if (eventsJson == null || eventsJson.isEmpty) {
        AppLogger.debug(
          'No events found in storage, returning empty list',
          'STORAGE',
        );
        return [];
      }

      AppLogger.debug('Found events JSON in storage, parsing...', 'STORAGE');
      final eventsList = json.decode(eventsJson) as List;
      final events = eventsList
          .map((eventMap) => Event.fromJson(eventMap as Map<String, dynamic>))
          .toList();

      AppLogger.debug(
        'Successfully parsed ${events.length} events from storage',
        'STORAGE',
      );
      return events;
    } catch (e) {
      AppLogger.exception('getAllEvents', e);
      // Return empty list instead of throwing to ensure app continues working
      AppLogger.warning('Returning empty list due to storage error', 'STORAGE');
      return [];
    }
  }

  /// Get a specific event by ID
  Future<Event?> getEvent(String id) async {
    try {
      final events = await getAllEvents();
      for (final event in events) {
        if (event.id == id) {
          return event;
        }
      }
      return null;
    } catch (e) {
      AppLogger.exception('getEvent', e);
      return null;
    }
  }

  /// Delete an event from local storage
  Future<void> deleteEvent(String id) async {
    try {
      final events = await getAllEvents();
      events.removeWhere((event) => event.id == id);
      await _saveEventsToStorage(events);

      // Mark deletion for sync
      await _addToPendingSync(id, isDelete: true);

      AppLogger.userAction('Event deleted locally', {'eventId': id});
    } catch (e) {
      AppLogger.exception('deleteEvent', e);
      throw Exception('Failed to delete event locally: $e');
    }
  }

  /// Get events by date
  Future<List<Event>> getEventsByDate(DateTime date) async {
    try {
      final allEvents = await getAllEvents();
      return allEvents.where((event) {
        return event.date.year == date.year &&
            event.date.month == date.month &&
            event.date.day == date.day;
      }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      AppLogger.exception('getEventsByDate', e);
      return [];
    }
  }

  /// Get events in a date range
  Future<List<Event>> getEventsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allEvents = await getAllEvents();
      return allEvents.where((event) {
        return event.date.isAfter(
              startDate.subtract(const Duration(days: 1)),
            ) &&
            event.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList()..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      AppLogger.exception('getEventsInDateRange', e);
      return [];
    }
  }

  /// Get upcoming events
  Future<List<Event>> getUpcomingEvents({int limit = 5}) async {
    try {
      final now = DateTime.now();
      final allEvents = await getAllEvents();
      final upcoming = allEvents.where((event) {
        return event.startTime.isAfter(now);
      }).toList();
      upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
      return upcoming.take(limit).toList();
    } catch (e) {
      AppLogger.exception('getUpcomingEvents', e);
      return [];
    }
  }

  /// Get today's events
  Future<List<Event>> getTodayEvents() async {
    final today = DateTime.now();
    return getEventsByDate(today);
  }

  // ==== JOURNAL ENTRY METHODS ====

  /// Save a journal entry to local storage
  Future<void> saveJournalEntry(JournalEntry entry) async {
    try {
      AppLogger.debug('Starting to save journal entry: ${entry.id}', 'STORAGE');

      // Ensure SharedPreferences is initialized
      if (_prefs == null) {
        AppLogger.warning(
          'SharedPreferences not initialized, reinitializing',
          'STORAGE',
        );
        await getInstance();
      }

      final entries = await getAllJournalEntries();
      AppLogger.debug(
        'Retrieved ${entries.length} existing journal entries',
        'STORAGE',
      );

      // Remove existing entry with same ID if it exists
      final originalCount = entries.length;
      entries.removeWhere((e) => e.id == entry.id);
      if (entries.length != originalCount) {
        AppLogger.debug(
          'Removed existing journal entry with same ID',
          'STORAGE',
        );
      }

      // Add the new/updated entry
      entries.add(entry);
      AppLogger.debug(
        'Added new journal entry, total entries: ${entries.length}',
        'STORAGE',
      );

      // Save back to storage
      await _saveJournalEntriesToStorage(entries);
      AppLogger.debug('Journal entries saved to SharedPreferences', 'STORAGE');

      // Mark as pending sync
      await _addJournalToPendingSync(entry.id);
      AppLogger.debug('Journal entry marked as pending sync', 'STORAGE');

      AppLogger.userAction('Journal entry saved locally', {
        'entryId': entry.id,
        'title': entry.title,
      });
    } catch (e) {
      AppLogger.exception('saveJournalEntry', e);
      throw Exception('Failed to save journal entry locally: $e');
    }
  }

  /// Get all journal entries from local storage
  Future<List<JournalEntry>> getAllJournalEntries() async {
    try {
      // Ensure SharedPreferences is initialized
      if (_prefs == null) {
        AppLogger.warning(
          'SharedPreferences not initialized in getAllJournalEntries, reinitializing',
          'STORAGE',
        );
        await getInstance();
      }

      final entriesJson = _prefs!.getString(_journalEntriesKey);
      if (entriesJson == null || entriesJson.isEmpty) {
        AppLogger.debug(
          'No journal entries found in storage, returning empty list',
          'STORAGE',
        );
        return [];
      }

      AppLogger.debug(
        'Found journal entries JSON in storage, parsing...',
        'STORAGE',
      );
      final entriesList = json.decode(entriesJson) as List;
      final entries = entriesList
          .map(
            (entryMap) =>
                JournalEntry.fromJson(entryMap as Map<String, dynamic>),
          )
          .toList();

      AppLogger.debug(
        'Successfully parsed ${entries.length} journal entries from storage',
        'STORAGE',
      );
      return entries;
    } catch (e) {
      AppLogger.exception('getAllJournalEntries', e);
      // Return empty list instead of throwing to ensure app continues working
      AppLogger.warning(
        'Returning empty journal list due to storage error',
        'STORAGE',
      );
      return [];
    }
  }

  /// Get a specific journal entry by ID
  Future<JournalEntry?> getJournalEntry(String id) async {
    try {
      final entries = await getAllJournalEntries();
      for (final entry in entries) {
        if (entry.id == id) {
          return entry;
        }
      }
      return null;
    } catch (e) {
      AppLogger.exception('getJournalEntry', e);
      return null;
    }
  }

  /// Delete a journal entry from local storage
  Future<void> deleteJournalEntry(String id) async {
    try {
      final entries = await getAllJournalEntries();
      entries.removeWhere((entry) => entry.id == id);
      await _saveJournalEntriesToStorage(entries);

      // Mark deletion for sync
      await _addJournalToPendingSync(id, isDelete: true);

      AppLogger.userAction('Journal entry deleted locally', {'entryId': id});
    } catch (e) {
      AppLogger.exception('deleteJournalEntry', e);
      throw Exception('Failed to delete journal entry locally: $e');
    }
  }

  /// Get journal entries by date
  Future<List<JournalEntry>> getJournalEntriesByDate(DateTime date) async {
    try {
      final allEntries = await getAllJournalEntries();
      return allEntries.where((entry) {
        return entry.createdAt.year == date.year &&
            entry.createdAt.month == date.month &&
            entry.createdAt.day == date.day;
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      AppLogger.exception('getJournalEntriesByDate', e);
      return [];
    }
  }

  /// Get journal entries in a date range
  Future<List<JournalEntry>> getJournalEntriesInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allEntries = await getAllJournalEntries();
      return allEntries.where((entry) {
        return entry.createdAt.isAfter(
              startDate.subtract(const Duration(days: 1)),
            ) &&
            entry.createdAt.isBefore(endDate.add(const Duration(days: 1)));
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      AppLogger.exception('getJournalEntriesInDateRange', e);
      return [];
    }
  }

  /// Get recent journal entries
  Future<List<JournalEntry>> getRecentJournalEntries({int limit = 10}) async {
    try {
      final allEntries = await getAllJournalEntries();
      allEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allEntries.take(limit).toList();
    } catch (e) {
      AppLogger.exception('getRecentJournalEntries', e);
      return [];
    }
  }

  /// Get today's journal entries
  Future<List<JournalEntry>> getTodayJournalEntries() async {
    final today = DateTime.now();
    return getJournalEntriesByDate(today);
  }

  /// Get journal entries by mood
  Future<List<JournalEntry>> getJournalEntriesByMood(Mood mood) async {
    try {
      final allEntries = await getAllJournalEntries();
      return allEntries.where((entry) => entry.mood == mood).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      AppLogger.exception('getJournalEntriesByMood', e);
      return [];
    }
  }

  /// Search journal entries by title or content
  Future<List<JournalEntry>> searchJournalEntries(String query) async {
    try {
      final allEntries = await getAllJournalEntries();
      final lowerQuery = query.toLowerCase();
      return allEntries.where((entry) {
        return entry.title.toLowerCase().contains(lowerQuery) ||
            entry.content.toLowerCase().contains(lowerQuery);
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      AppLogger.exception('searchJournalEntries', e);
      return [];
    }
  }

  /// Get mood distribution for analytics
  Future<Map<Mood, int>> getJournalMoodDistribution() async {
    try {
      final allEntries = await getAllJournalEntries();
      final Map<Mood, int> moodCount = {};

      // Initialize all moods with 0
      for (final mood in Mood.values) {
        moodCount[mood] = 0;
      }

      // Count occurrences
      for (final entry in allEntries) {
        moodCount[entry.mood] = (moodCount[entry.mood] ?? 0) + 1;
      }

      return moodCount;
    } catch (e) {
      AppLogger.exception('getJournalMoodDistribution', e);
      return {};
    }
  }

  /// Get journal entries that are pending sync to Firebase
  Future<List<String>> getPendingSyncJournalEntryIds() async {
    try {
      final pendingJson = _prefs!.getString(_pendingJournalSyncKey);
      if (pendingJson == null || pendingJson.isEmpty) {
        return [];
      }

      final pendingList = json.decode(pendingJson) as List;
      return pendingList.cast<String>();
    } catch (e) {
      AppLogger.exception('getPendingSyncJournalEntryIds', e);
      return [];
    }
  }

  /// Get journal entries that are pending sync
  Future<List<JournalEntry>> getPendingSyncJournalEntries() async {
    try {
      final pendingIds = await getPendingSyncJournalEntryIds();
      final entries = await getAllJournalEntries();
      return entries.where((entry) => pendingIds.contains(entry.id)).toList();
    } catch (e) {
      AppLogger.exception('getPendingSyncJournalEntries', e);
      return [];
    }
  }

  /// Mark journal entry as synced (remove from pending sync)
  Future<void> markJournalEntryAsSynced(String entryId) async {
    try {
      final pendingIds = await getPendingSyncJournalEntryIds();
      pendingIds.remove(entryId);

      await _prefs!.setString(_pendingJournalSyncKey, json.encode(pendingIds));

      AppLogger.userAction('Journal entry marked as synced', {
        'entryId': entryId,
      });
    } catch (e) {
      AppLogger.exception('markJournalEntryAsSynced', e);
    }
  }

  /// Get events that are pending sync to Firebase
  Future<List<String>> getPendingSyncEventIds() async {
    try {
      final pendingJson = _prefs!.getString(_pendingSyncKey);
      if (pendingJson == null || pendingJson.isEmpty) {
        return [];
      }

      final pendingList = json.decode(pendingJson) as List;
      return pendingList.cast<String>();
    } catch (e) {
      AppLogger.exception('getPendingSyncEventIds', e);
      return [];
    }
  }

  /// Get events that are pending sync
  Future<List<Event>> getPendingSyncEvents() async {
    try {
      final pendingIds = await getPendingSyncEventIds();
      final events = await getAllEvents();
      return events.where((event) => pendingIds.contains(event.id)).toList();
    } catch (e) {
      AppLogger.exception('getPendingSyncEvents', e);
      return [];
    }
  }

  /// Mark event as synced (remove from pending sync)
  Future<void> markEventAsSynced(String eventId) async {
    try {
      final pendingIds = await getPendingSyncEventIds();
      pendingIds.remove(eventId);

      await _prefs!.setString(_pendingSyncKey, json.encode(pendingIds));

      AppLogger.userAction('Event marked as synced', {'eventId': eventId});
    } catch (e) {
      AppLogger.exception('markEventAsSynced', e);
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final timestamp = _prefs!.getInt(_lastSyncKey);
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      AppLogger.exception('getLastSyncTime', e);
      return null;
    }
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncTime() async {
    try {
      await _prefs!.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.exception('updateLastSyncTime', e);
    }
  }

  /// Clear all local data
  Future<void> clearAllData() async {
    try {
      await _prefs!.remove(_eventsKey);
      await _prefs!.remove(_pendingSyncKey);
      await _prefs!.remove(_lastSyncKey);

      AppLogger.userAction('Local data cleared', {});
    } catch (e) {
      AppLogger.exception('clearAllData', e);
    }
  }

  /// Get statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      final events = await getAllEvents();
      final pendingIds = await getPendingSyncEventIds();

      return {
        'totalEvents': events.length,
        'completedEvents': events.where((e) => e.isCompleted).length,
        'pendingSyncCount': pendingIds.length,
      };
    } catch (e) {
      AppLogger.exception('getStatistics', e);
      return {'totalEvents': 0, 'completedEvents': 0, 'pendingSyncCount': 0};
    }
  }

  /// Private helper methods

  Future<void> _saveEventsToStorage(List<Event> events) async {
    try {
      AppLogger.debug('Converting ${events.length} events to JSON', 'STORAGE');
      final eventsJson = json.encode(events.map((e) => e.toJson()).toList());

      AppLogger.debug(
        'Saving JSON to SharedPreferences (${eventsJson.length} chars)',
        'STORAGE',
      );
      final success = await _prefs!.setString(_eventsKey, eventsJson);

      if (!success) {
        throw Exception('SharedPreferences.setString returned false');
      }

      AppLogger.debug(
        'Successfully saved events to SharedPreferences',
        'STORAGE',
      );
    } catch (e) {
      AppLogger.exception('_saveEventsToStorage', e);
      throw Exception('Failed to save to SharedPreferences: $e');
    }
  }

  Future<void> _addToPendingSync(
    String eventId, {
    bool isDelete = false,
  }) async {
    try {
      final pendingIds = await getPendingSyncEventIds();

      if (!pendingIds.contains(eventId)) {
        pendingIds.add(eventId);
      }

      await _prefs!.setString(_pendingSyncKey, json.encode(pendingIds));
    } catch (e) {
      AppLogger.exception('_addToPendingSync', e);
    }
  }

  Future<void> _saveJournalEntriesToStorage(List<JournalEntry> entries) async {
    try {
      AppLogger.debug(
        'Converting ${entries.length} journal entries to JSON',
        'STORAGE',
      );
      final entriesJson = json.encode(entries.map((e) => e.toJson()).toList());

      AppLogger.debug(
        'Saving journal JSON to SharedPreferences (${entriesJson.length} chars)',
        'STORAGE',
      );
      final success = await _prefs!.setString(_journalEntriesKey, entriesJson);

      if (!success) {
        throw Exception('SharedPreferences.setString returned false');
      }

      AppLogger.debug(
        'Successfully saved journal entries to SharedPreferences',
        'STORAGE',
      );
    } catch (e) {
      AppLogger.exception('_saveJournalEntriesToStorage', e);
      throw Exception(
        'Failed to save journal entries to SharedPreferences: $e',
      );
    }
  }

  Future<void> _addJournalToPendingSync(
    String entryId, {
    bool isDelete = false,
  }) async {
    try {
      final pendingIds = await getPendingSyncJournalEntryIds();

      if (!pendingIds.contains(entryId)) {
        pendingIds.add(entryId);
      }

      await _prefs!.setString(_pendingJournalSyncKey, json.encode(pendingIds));
    } catch (e) {
      AppLogger.exception('_addJournalToPendingSync', e);
    }
  }

  /// Sync status helpers

  Future<bool> hasUnsyncedData() async {
    final pendingIds = await getPendingSyncEventIds();
    return pendingIds.isNotEmpty;
  }

  Future<int> getUnsyncedCount() async {
    final pendingIds = await getPendingSyncEventIds();
    return pendingIds.length;
  }
}
