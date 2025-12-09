import '../models/journal_entry.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/background_sync_service.dart';
import '../../../core/widgets/app_logger.dart';

class JournalService {
  static Future<void> addEntry(JournalEntry entry) async {
    AppLogger.userAction('Add Journal Entry Started', {
      'entryTitle': entry.title,
      'mood': entry.mood.toString(),
    });

    try {
      AppLogger.debug(
        'Step 1: Initializing local storage for journal entry creation',
        'JOURNAL_SERVICE',
      );

      // 1. Save to local storage first (immediate response)
      LocalStorageService? localStorage;
      try {
        localStorage = await LocalStorageService.getInstance();
        AppLogger.debug(
          'Step 2: Local storage instance obtained successfully',
          'JOURNAL_SERVICE',
        );
      } catch (e) {
        AppLogger.exception('Failed to get LocalStorageService instance', e);
        throw Exception('Local storage initialization failed: $e');
      }

      try {
        await localStorage.saveJournalEntry(entry);
        AppLogger.debug(
          'Step 3: Journal entry saved to local storage successfully',
          'JOURNAL_SERVICE',
        );
      } catch (e) {
        AppLogger.exception('Failed to save journal entry to local storage', e);
        throw Exception('Local storage save failed: $e');
      }

      AppLogger.userAction('Journal entry saved locally', {
        'entryId': entry.id,
        'entryTitle': entry.title,
      });

      // 2. Trigger background sync (non-blocking)
      try {
        AppLogger.debug(
          'Step 4: Triggering background sync',
          'JOURNAL_SERVICE',
        );
        _triggerBackgroundSync(entry.id);
        AppLogger.debug(
          'Step 5: Background sync triggered successfully',
          'JOURNAL_SERVICE',
        );
      } catch (e) {
        AppLogger.warning(
          'Background sync trigger failed: $e',
          'JOURNAL_SERVICE',
        );
        // Don't throw - sync failure shouldn't prevent entry creation
      }

      AppLogger.userAction('Add Journal Entry Completed Successfully', {
        'entryId': entry.id,
        'entryTitle': entry.title,
        'storageType': 'local-first',
      });
    } catch (e) {
      AppLogger.exception('addEntry failed completely', e);
      throw Exception('Failed to add journal entry: $e');
    }
  }

  static Future<void> updateEntry(JournalEntry entry) async {
    try {
      AppLogger.userAction('Update Journal Entry Started', {
        'entryId': entry.id,
        'entryTitle': entry.title,
      });

      // 1. Update local storage first
      final localStorage = await LocalStorageService.getInstance();
      await localStorage.saveJournalEntry(entry);

      AppLogger.userAction('Journal entry updated locally', {
        'entryId': entry.id,
        'entryTitle': entry.title,
      });

      // 2. Trigger background sync
      _triggerBackgroundSync(entry.id);

      AppLogger.userAction('Update Journal Entry Completed', {
        'entryId': entry.id,
        'storageType': 'local-first',
      });
    } catch (e) {
      AppLogger.exception('updateEntry', e);
      throw Exception('Failed to update journal entry: $e');
    }
  }

  static Future<void> deleteEntry(String id) async {
    try {
      AppLogger.userAction('Delete Journal Entry Started', {'entryId': id});

      // 1. Delete from local storage first
      final localStorage = await LocalStorageService.getInstance();
      await localStorage.deleteJournalEntry(id);

      AppLogger.userAction('Journal entry deleted locally', {'entryId': id});

      // 2. Trigger background sync for deletion
      _triggerBackgroundSync(id);

      AppLogger.userAction('Delete Journal Entry Completed', {
        'entryId': id,
        'storageType': 'local-first',
      });
    } catch (e) {
      AppLogger.exception('deleteEntry', e);
      throw Exception('Failed to delete journal entry: $e');
    }
  }

  static Future<JournalEntry?> getEntry(String id) async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getJournalEntry(id);
    } catch (e) {
      AppLogger.exception('getEntry', e);
      return null;
    }
  }

  static Future<List<JournalEntry>> getAllEntries() async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getAllJournalEntries();
    } catch (e) {
      AppLogger.exception('getAllEntries', e);
      return [];
    }
  }

  static Future<List<JournalEntry>> getEntriesByDate(DateTime date) async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getJournalEntriesByDate(date);
    } catch (e) {
      AppLogger.exception('getEntriesByDate', e);
      return [];
    }
  }

  static Future<List<JournalEntry>> getEntriesInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getJournalEntriesInDateRange(
        startDate,
        endDate,
      );
    } catch (e) {
      AppLogger.exception('getEntriesInDateRange', e);
      return [];
    }
  }

  static Future<List<JournalEntry>> getRecentEntries({int limit = 10}) async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getRecentJournalEntries(limit: limit);
    } catch (e) {
      AppLogger.exception('getRecentEntries', e);
      return [];
    }
  }

  static Future<List<JournalEntry>> getTodayEntries() async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getTodayJournalEntries();
    } catch (e) {
      AppLogger.exception('getTodayEntries', e);
      return [];
    }
  }

  static Future<List<JournalEntry>> getEntriesByMood(Mood mood) async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getJournalEntriesByMood(mood);
    } catch (e) {
      AppLogger.exception('getEntriesByMood', e);
      return [];
    }
  }

  static Future<List<JournalEntry>> searchEntries(String query) async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.searchJournalEntries(query);
    } catch (e) {
      AppLogger.exception('searchEntries', e);
      return [];
    }
  }

  static Future<Map<Mood, int>> getMoodDistribution() async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      return await localStorage.getJournalMoodDistribution();
    } catch (e) {
      AppLogger.exception('getMoodDistribution', e);
      return {};
    }
  }

  static Future<int> getTotalEntriesCount() async {
    try {
      final entries = await getAllEntries();
      return entries.length;
    } catch (e) {
      AppLogger.exception('getTotalEntriesCount', e);
      return 0;
    }
  }

  static Future<void> clearAllEntries() async {
    try {
      final entries = await getAllEntries();
      for (final entry in entries) {
        await deleteEntry(entry.id);
      }
    } catch (e) {
      throw Exception('Failed to clear all journal entries: $e');
    }
  }

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
      AppLogger.userAction('Manual journal sync triggered', {});
      final syncService = BackgroundSyncService.instance;
      final result = await syncService.performManualSync();

      if (result.success) {
        AppLogger.userAction('Manual journal sync completed successfully', {
          'successful': result.successfulSyncs,
          'failed': result.failedSyncs,
        });
      } else {
        AppLogger.warning(
          'Manual journal sync failed: ${result.errorMessage}',
          'SYNC',
        );
      }

      return result.success;
    } catch (e) {
      AppLogger.exception('performManualSync', e);
      return false;
    }
  }

  /// Test local storage functionality
  static Future<bool> testLocalStorage() async {
    try {
      AppLogger.info('Testing journal local storage functionality', 'TEST');

      final localStorage = await LocalStorageService.getInstance();
      AppLogger.info('Journal local storage instance created', 'TEST');

      // Test getting entries (should work even if empty)
      final entries = await localStorage.getAllJournalEntries();
      AppLogger.info(
        'Successfully retrieved ${entries.length} journal entries from storage',
        'TEST',
      );

      return true;
    } catch (e) {
      AppLogger.exception('testLocalStorage', e);
      return false;
    }
  }

  /// Private helper method to trigger background sync
  static void _triggerBackgroundSync(String entryId) {
    try {
      // Fire and forget - trigger sync without waiting
      // This should NEVER block local operations
      Future.microtask(() async {
        try {
          final syncService = BackgroundSyncService.instance;
          // Use the specific journal sync method
          await syncService.syncJournalEntryImmediately(entryId);
        } catch (e) {
          // Sync failure should not affect local operations
          AppLogger.warning(
            'Background sync failed for journal entry $entryId: $e',
            'SYNC',
          );
        }
      });

      AppLogger.debug(
        'Background sync triggered for journal entry: $entryId',
        'SYNC',
      );
    } catch (e) {
      // Even triggering sync failure should not affect local operations
      AppLogger.warning(
        'Failed to trigger background sync for journal entry $entryId: $e',
        'SYNC',
      );
    }
  }
}
