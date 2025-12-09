import 'event.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/background_sync_service.dart';
import '../../../core/services/home_widget_service.dart';
import '../../../core/widgets/app_logger.dart';

class EventService {
  static Future<void> addEvent(Event event) async {
    AppLogger.userAction('Add Event Started', {
      'eventTitle': event.title,
      'category': event.category,
    });

    try {
      AppLogger.debug(
        'Step 1: Initializing local storage for event creation',
        'EVENT_SERVICE',
      );

      // 1. Save to local storage first (immediate response)
      LocalStorageService? localStorage;
      try {
        localStorage = await LocalStorageService.getInstance();
        AppLogger.debug(
          'Step 2: Local storage instance obtained successfully',
          'EVENT_SERVICE',
        );
      } catch (e) {
        AppLogger.exception('Failed to get LocalStorageService instance', e);
        throw Exception('Local storage initialization failed: $e');
      }

      try {
        await localStorage.saveEvent(event);
        AppLogger.debug(
          'Step 3: Event saved to local storage successfully',
          'EVENT_SERVICE',
        );
      } catch (e) {
        AppLogger.exception('Failed to save event to local storage', e);
        throw Exception('Local storage save failed: $e');
      }

      AppLogger.userAction('Event saved locally', {
        'eventId': event.id,
        'eventTitle': event.title,
      });

      // 2. Schedule notifications immediately
      try {
        AppLogger.debug('Step 4: Scheduling notifications', 'EVENT_SERVICE');
        await NotificationService().scheduleEventNotifications(event);
        AppLogger.info('Notifications scheduled for event', 'NOTIFICATIONS');
      } catch (e) {
        AppLogger.warning(
          'Failed to schedule notifications for event: $e',
          'NOTIFICATIONS',
        );
        // Don't throw - notifications are not critical for event creation
      }

      // 3. Trigger background sync (non-blocking)
      try {
        AppLogger.debug('Step 5: Triggering background sync', 'EVENT_SERVICE');
        _triggerBackgroundSync(event.id);
        AppLogger.debug(
          'Step 6: Background sync triggered successfully',
          'EVENT_SERVICE',
        );
      } catch (e) {
        AppLogger.warning(
          'Background sync trigger failed: $e',
          'EVENT_SERVICE',
        );
        // Don't throw - sync failure shouldn't prevent event creation
      }

      // 4. Update home widget (non-blocking)
      try {
        AppLogger.debug('Step 7: Updating home widget', 'EVENT_SERVICE');
        _updateHomeWidget();
      } catch (e) {
        AppLogger.warning('Home widget update failed: $e', 'EVENT_SERVICE');
        // Don't throw - widget update failure shouldn't prevent event creation
      }

      AppLogger.userAction('Add Event Completed Successfully', {
        'eventId': event.id,
        'eventTitle': event.title,
        'storageType': 'local-first',
      });
    } catch (e) {
      AppLogger.exception('addEvent failed completely', e);
      throw Exception('Failed to add event: $e');
    }
  }

  static Future<void> updateEvent(Event event) async {
    try {
      AppLogger.userAction('Update Event Started', {
        'eventId': event.id,
        'eventTitle': event.title,
      });

      // 1. Update local storage first
      final localStorage = await LocalStorageService.getInstance();
      await localStorage.saveEvent(event);

      AppLogger.userAction('Event updated locally', {
        'eventId': event.id,
        'eventTitle': event.title,
      });

      // 2. Update notifications immediately
      try {
        await NotificationService().cancelEventNotifications(event);
        await NotificationService().scheduleEventNotifications(event);
        AppLogger.info('Notifications updated for event', 'NOTIFICATIONS');
      } catch (e) {
        AppLogger.warning(
          'Failed to update notifications for event: $e',
          'NOTIFICATIONS',
        );
      }

      // 3. Trigger background sync
      _triggerBackgroundSync(event.id);

      // 4. Update home widget (non-blocking)
      _updateHomeWidget();

      AppLogger.userAction('Update Event Completed', {
        'eventId': event.id,
        'storageType': 'local-first',
      });
    } catch (e) {
      AppLogger.exception('updateEvent', e);
      throw Exception('Failed to update event: $e');
    }
  }

  static Future<void> deleteEvent(String id) async {
    try {
      AppLogger.userAction('Delete Event Started', {'eventId': id});

      // 1. Get event for notifications before deleting
      final localStorage = await LocalStorageService.getInstance();
      final event = await localStorage.getEvent(id);

      // 2. Delete from local storage first
      await localStorage.deleteEvent(id);

      AppLogger.userAction('Event deleted locally', {'eventId': id});

      // 3. Cancel notifications immediately
      if (event != null) {
        try {
          await NotificationService().cancelEventNotifications(event);
          AppLogger.info(
            'Notifications cancelled for deleted event',
            'NOTIFICATIONS',
          );
        } catch (e) {
          AppLogger.warning(
            'Failed to cancel notifications for deleted event: $e',
            'NOTIFICATIONS',
          );
        }
      }

      // 4. Trigger background sync for deletion
      _triggerBackgroundSync(id);

      // 5. Update home widget (non-blocking)
      _updateHomeWidget();

      AppLogger.userAction('Delete Event Completed', {
        'eventId': id,
        'storageType': 'local-first',
      });
    } catch (e) {
      AppLogger.exception('deleteEvent', e);
      throw Exception('Failed to delete event: $e');
    }
  }

  static Future<Event?> getEvent(String id) async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getEvent(id);
    } catch (e) {
      AppLogger.exception('getEvent', e);
      return null;
    }
  }

  static Future<List<Event>> getAllEvents() async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getAllEvents();
    } catch (e) {
      AppLogger.exception('getAllEvents', e);
      return [];
    }
  }

  static Future<List<Event>> getEventsByDate(DateTime date) async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getEventsByDate(date);
    } catch (e) {
      AppLogger.exception('getEventsByDate', e);
      return [];
    }
  }

  static Future<List<Event>> getEventsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getEventsInDateRange(startDate, endDate);
    } catch (e) {
      AppLogger.exception('getEventsInDateRange', e);
      return [];
    }
  }

  static Future<List<Event>> getUpcomingEvents({int limit = 5}) async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getUpcomingEvents(limit: limit);
    } catch (e) {
      AppLogger.exception('getUpcomingEvents', e);
      return [];
    }
  }

  static Future<List<Event>> getTodayEvents() async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getTodayEvents();
    } catch (e) {
      AppLogger.exception('getTodayEvents', e);
      return [];
    }
  }

  static Future<void> markEventCompleted(String id) async {
    try {
      AppLogger.userAction('Mark Event Completed Started', {'eventId': id});

      final event = await getEvent(id);
      if (event != null) {
        final updatedEvent = event.copyWith(
          isCompleted: true,
          status: EventStatus.completed,
          updatedAt: DateTime.now(),
        );
        await updateEvent(updatedEvent);

        // Show completion notification
        try {
          await NotificationService().showEventCompletionNotification(
            updatedEvent,
          );
          AppLogger.info('Completion notification shown', 'NOTIFICATIONS');
        } catch (e) {
          AppLogger.warning(
            'Failed to show completion notification: $e',
            'NOTIFICATIONS',
          );
        }

        AppLogger.userAction('Mark Event Completed', {
          'eventId': id,
          'eventTitle': event.title,
        });
      }
    } catch (e) {
      AppLogger.exception('markEventCompleted', e);
      throw Exception('Failed to mark event completed: $e');
    }
  }

  static Future<int> getTotalEventsCount() async {
    try {
      final events = await getAllEvents();
      return events.length;
    } catch (e) {
      AppLogger.exception('getTotalEventsCount', e);
      return 0;
    }
  }

  static Future<int> getCompletedEventsCount() async {
    try {
      final events = await getAllEvents();
      return events.where((event) => event.isCompleted).length;
    } catch (e) {
      AppLogger.exception('getCompletedEventsCount', e);
      return 0;
    }
  }

  static Future<void> clearAllEvents() async {
    try {
      final events = await getAllEvents();
      for (final event in events) {
        await deleteEvent(event.id);
      }
    } catch (e) {
      throw Exception('Failed to clear all events: $e');
    }
  }

  static Future<void> updateEventStatus(String id, EventStatus status) async {
    try {
      final event = await getEvent(id);
      if (event != null) {
        final updatedEvent = event.copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        await updateEvent(updatedEvent);
      }
    } catch (e) {
      throw Exception('Failed to update event status: $e');
    }
  }

  /// Check and update all events that should be marked as completed
  static Future<List<Event>> checkAndUpdateMissedEvents() async {
    try {
      final now = DateTime.now();
      final allEvents = await getAllEvents();
      final updatedEvents = <Event>[];

      for (final event in allEvents) {
        // Skip if already completed
        if (event.status == EventStatus.completed) {
          continue;
        }

        bool shouldComplete = false;

        // For events without end time, complete if start time + 1 hour has passed
        if (event.endTime == null) {
          if (now.isAfter(event.startTime.add(const Duration(hours: 1)))) {
            shouldComplete = true;
          }
        }
        // For events with end time, complete if end time has passed
        else {
          final effectiveEnd = event.effectiveEndTime;
          if (now.isAfter(effectiveEnd!)) {
            shouldComplete = true;
          }
        }

        if (shouldComplete) {
          final updatedEvent = event.copyWith(
            status: EventStatus.completed,
            isCompleted: true, // Set both status and isCompleted flag
            updatedAt: now,
          );
          await updateEvent(updatedEvent);
          updatedEvents.add(updatedEvent);

          AppLogger.userAction('Event auto-completed due to time', {
            'eventId': event.id,
            'eventTitle': event.title,
          });

          // Show completion notification
          try {
            await NotificationService().showEventCompletionNotification(
              updatedEvent,
            );
          } catch (e) {
            AppLogger.warning(
              'Failed to show completion notification: $e',
              'NOTIFICATIONS',
            );
          }
        }
      }

      return updatedEvents;
    } catch (e) {
      AppLogger.exception('checkAndUpdateMissedEvents', e);
      return [];
    }
  }

  /// Auto-update event status based on current time
  static Future<Event?> autoUpdateEventStatus(String id) async {
    try {
      final event = await getEvent(id);
      if (event == null) return null;

      final autoStatus = event.getAutoUpdatedStatus();

      // Only update if status changed
      if (autoStatus != event.status) {
        final updatedEvent = event.copyWith(
          status: autoStatus,
          updatedAt: DateTime.now(),
        );
        await updateEvent(updatedEvent);
        AppLogger.userAction('Event status auto-updated', {
          'eventId': event.id,
          'eventTitle': event.title,
          'newStatus': autoStatus.displayName,
        });
        return updatedEvent;
      }

      return event;
    } catch (e) {
      AppLogger.exception('autoUpdateEventStatus', e);
      return null;
    }
  }

  /// Sync Management

  /// Get sync status information
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final syncService = BackgroundSyncService.instance;
      final syncStatus = await syncService.getSyncStatus();

      return {
        'lastSyncTime': syncStatus.lastSyncTime,
        'pendingSyncCount': syncStatus.pendingSyncCount,
        'isSyncing': syncStatus.isSyncing,
        'isConnected': syncStatus.isConnected,
        'statusMessage': syncStatus.statusMessage,
      };
    } catch (e) {
      AppLogger.exception('getSyncStatus', e);
      return {
        'lastSyncTime': null,
        'pendingSyncCount': 0,
        'isSyncing': false,
        'isConnected': false,
        'statusMessage': 'Unknown',
      };
    }
  }

  /// Trigger manual sync
  static Future<bool> performManualSync() async {
    try {
      AppLogger.userAction('Manual sync triggered', {});
      final syncService = BackgroundSyncService.instance;
      final result = await syncService.performManualSync();

      if (result.success) {
        AppLogger.userAction('Manual sync completed successfully', {
          'successful': result.successfulSyncs,
          'failed': result.failedSyncs,
        });
      } else {
        AppLogger.warning('Manual sync failed: ${result.errorMessage}', 'SYNC');
      }

      return result.success;
    } catch (e) {
      AppLogger.exception('performManualSync', e);
      return false;
    }
  }

  /// Start background sync service
  static Future<void> startBackgroundSync() async {
    try {
      final syncService = BackgroundSyncService.instance;
      await syncService.startBackgroundSync();
      AppLogger.info('Background sync service started', 'SYNC');
    } catch (e) {
      AppLogger.exception('startBackgroundSync', e);
    }
  }

  /// Start background sync service when user authenticates
  static Future<void> startBackgroundSyncOnAuth() async {
    try {
      AppLogger.info(
        'Starting background sync after user authentication',
        'SYNC',
      );
      await startBackgroundSync();
    } catch (e) {
      AppLogger.exception('startBackgroundSyncOnAuth', e);
    }
  }

  /// Stop background sync service
  static void stopBackgroundSync() {
    try {
      final syncService = BackgroundSyncService.instance;
      syncService.stopBackgroundSync();
      AppLogger.info('Background sync service stopped', 'SYNC');
    } catch (e) {
      AppLogger.exception('stopBackgroundSync', e);
    }
  }

  /// Test local storage functionality
  static Future<bool> testLocalStorage() async {
    try {
      AppLogger.info('Testing local storage functionality', 'TEST');

      final localStorage = await LocalStorageService.getInstance();
      AppLogger.info('Local storage instance created', 'TEST');

      // Test getting events (should work even if empty)
      final events = await localStorage.getAllEvents();
      AppLogger.info(
        'Successfully retrieved ${events.length} events from storage',
        'TEST',
      );

      return true;
    } catch (e) {
      AppLogger.exception('testLocalStorage', e);
      return false;
    }
  }

  /// Private helper method to update home widget
  static void _updateHomeWidget() {
    try {
      // Fire and forget - update widget without waiting
      // This should NEVER block local operations
      Future.microtask(() async {
        try {
          await HomeWidgetService.updateOngoingEventsWidget();
          AppLogger.debug('Home widget updated successfully', 'WIDGET');
        } catch (e) {
          // Widget update failure should not affect local operations
          AppLogger.warning('Home widget update failed: $e', 'WIDGET');
        }
      });
    } catch (e) {
      // Even triggering widget update failure should not affect local operations
      AppLogger.warning('Failed to trigger home widget update: $e', 'WIDGET');
    }
  }

  /// Private helper method to trigger background sync
  static void _triggerBackgroundSync(String eventId) {
    try {
      // Fire and forget - trigger sync without waiting
      // This should NEVER block local operations
      Future.microtask(() async {
        try {
          final syncService = BackgroundSyncService.instance;
          await syncService.syncEventImmediately(eventId);
        } catch (e) {
          // Sync failure should not affect local operations
          AppLogger.warning(
            'Background sync failed for event $eventId: $e',
            'SYNC',
          );
        }
      });

      AppLogger.debug('Background sync triggered for event: $eventId', 'SYNC');
    } catch (e) {
      // Even triggering sync failure should not affect local operations
      AppLogger.warning(
        'Failed to trigger background sync for event $eventId: $e',
        'SYNC',
      );
    }
  }
}
