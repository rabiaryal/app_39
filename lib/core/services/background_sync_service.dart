import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_logger.dart';
import 'local_storage_service.dart';
import 'firestore_service.dart';
import '../../features/daily_activities/models/event.dart';
import '../../features/notes/models/note.dart';
import '../../features/journal/models/journal_entry.dart';
import '../../features/notes/services/hive_note_service.dart' as hive_notes;

/// Service that handles background synchronization with Firebase
class BackgroundSyncService {
  static BackgroundSyncService? _instance;
  static Timer? _syncTimer;
  static bool _isSyncing = false;

  // Sync configuration
  static const Duration _syncInterval = Duration(minutes: 2);

  BackgroundSyncService._();

  static BackgroundSyncService get instance {
    _instance ??= BackgroundSyncService._();
    return _instance!;
  }

  /// Start background sync process
  Future<void> startBackgroundSync() async {
    try {
      // Cancel existing timer if any
      _syncTimer?.cancel();

      AppLogger.info('Starting background sync service', 'SYNC');

      // Don't run initial sync - let it happen on first timer tick
      // This prevents blocking app startup if Firebase is not available

      // Set up periodic sync
      _syncTimer = Timer.periodic(_syncInterval, (_) async {
        if (!_isSyncing) {
          await _performSync();
        }
      });

      AppLogger.info('Background sync service started', 'SYNC');
    } catch (e) {
      AppLogger.exception('startBackgroundSync', e);
    }
  }

  /// Stop background sync process
  void stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    AppLogger.info('Background sync service stopped', 'SYNC');
  }

  /// Perform manual sync
  Future<SyncResult> performManualSync() async {
    return await _performSync(isManual: true);
  }

  /// Immediately sync a specific event to Firebase
  Future<void> syncEventImmediately(String eventId) async {
    try {
      if (!(await _checkConnectivity())) {
        AppLogger.warning('No connectivity for immediate event sync', 'SYNC');
        return;
      }

      final localStorage = await LocalStorageService.getInstance();
      final event = await localStorage.getEvent(eventId);

      if (event != null) {
        final success = await _syncSingleEvent(event);
        if (success) {
          AppLogger.info('Event $eventId synced immediately', 'SYNC');
        } else {
          AppLogger.warning(
            'Failed to sync event $eventId immediately',
            'SYNC',
          );
        }
      }
    } catch (e) {
      AppLogger.exception('syncEventImmediately $eventId', e);
    }
  }

  /// Immediately sync a specific note to Firebase
  Future<void> syncNoteImmediately(String noteId) async {
    try {
      if (!await _checkConnectivity()) {
        AppLogger.warning('No connectivity for immediate note sync', 'SYNC');
        return;
      }

      final note = hive_notes.NoteService.getNote(noteId);

      if (note != null) {
        final success = await _syncSingleNote(note);
        if (success) {
          AppLogger.info('Note $noteId synced immediately', 'SYNC');
        } else {
          AppLogger.warning('Failed to sync note $noteId immediately', 'SYNC');
        }
      }
    } catch (e) {
      AppLogger.exception('syncNoteImmediately $noteId', e);
    }
  }

  /// Immediately sync a specific journal entry to Firebase
  Future<void> syncJournalEntryImmediately(String entryId) async {
    try {
      if (!await _checkConnectivity()) {
        AppLogger.warning(
          'No connectivity for immediate journal entry sync',
          'SYNC',
        );
        return;
      }

      final localStorage = await LocalStorageService.getInstance();
      final entry = await localStorage.getJournalEntry(entryId);

      if (entry != null) {
        final success = await _syncSingleJournalEntry(entry);
        if (success) {
          AppLogger.info('Journal entry $entryId synced immediately', 'SYNC');
        } else {
          AppLogger.warning(
            'Failed to sync journal entry $entryId immediately',
            'SYNC',
          );
        }
      }
    } catch (e) {
      AppLogger.exception('syncJournalEntryImmediately $entryId', e);
    }
  }

  /// Check if sync is currently running
  bool get isSyncing => _isSyncing;

  /// Get sync status information
  Future<SyncStatus> getSyncStatus() async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      final lastSync = await localStorage.getLastSyncTime();
      final pendingCount = await localStorage.getUnsyncedCount();

      return SyncStatus(
        lastSyncTime: lastSync,
        pendingSyncCount: pendingCount,
        isSyncing: _isSyncing,
        isConnected: await _checkConnectivity(),
      );
    } catch (e) {
      AppLogger.exception('getSyncStatus', e);
      return SyncStatus(
        lastSyncTime: null,
        pendingSyncCount: 0,
        isSyncing: false,
        isConnected: false,
      );
    }
  }

  /// Private sync implementation

  Future<SyncResult> _performSync({bool isManual = false}) async {
    if (_isSyncing) {
      AppLogger.warning('Sync already in progress, skipping', 'SYNC');
      return SyncResult.alreadyRunning();
    }

    _isSyncing = true;

    try {
      AppLogger.info(
        'Starting sync operation${isManual ? ' (manual)' : ''}',
        'SYNC',
      );

      // Check if user is authenticated - if not, skip sync but don't fail
      if (FirebaseAuth.instance.currentUser == null) {
        AppLogger.auth(
          'User not authenticated, skipping Firebase sync (local storage continues to work)',
        );
        return SyncResult.authFailure();
      }

      // Check connectivity - if not available, skip sync but don't fail
      if (!await _checkConnectivity()) {
        AppLogger.warning(
          'No connectivity, skipping Firebase sync (local storage continues to work)',
          'SYNC',
        );
        return SyncResult.networkFailure();
      }

      final localStorage = await LocalStorageService.getInstance();
      final pendingEvents = await localStorage.getPendingSyncEvents();
      final pendingJournalEntries = await localStorage
          .getPendingSyncJournalEntries();

      final totalPending = pendingEvents.length + pendingJournalEntries.length;

      if (totalPending == 0) {
        AppLogger.info('No items pending sync', 'SYNC');
        await localStorage.updateLastSyncTime();
        return SyncResult.success(0, 0);
      }

      AppLogger.info(
        'Syncing $totalPending items (${pendingEvents.length} events, ${pendingJournalEntries.length} journal entries)',
        'SYNC',
      );

      int successCount = 0;
      int failureCount = 0;

      // Sync events
      for (final event in pendingEvents) {
        try {
          final success = await _syncSingleEvent(event);
          if (success) {
            await localStorage.markEventAsSynced(event.id);
            successCount++;
            AppLogger.debug('Synced event: ${event.title}', 'SYNC');
          } else {
            failureCount++;
            AppLogger.warning('Failed to sync event: ${event.title}', 'SYNC');
          }
        } catch (e) {
          failureCount++;
          AppLogger.exception('_syncSingleEvent for ${event.id}', e);
        }

        // Small delay between syncs to avoid overwhelming Firebase
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Sync journal entries
      for (final entry in pendingJournalEntries) {
        try {
          final success = await _syncSingleJournalEntry(entry);
          if (success) {
            await localStorage.markJournalEntryAsSynced(entry.id);
            successCount++;
            AppLogger.debug('Synced journal entry: ${entry.title}', 'SYNC');
          } else {
            failureCount++;
            AppLogger.warning(
              'Failed to sync journal entry: ${entry.title}',
              'SYNC',
            );
          }
        } catch (e) {
          failureCount++;
          AppLogger.exception('_syncSingleJournalEntry for ${entry.id}', e);
        }

        // Small delay between syncs to avoid overwhelming Firebase
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await localStorage.updateLastSyncTime();

      AppLogger.userAction('Sync completed', {
        'successful': successCount,
        'failed': failureCount,
        'total': totalPending,
        'events': pendingEvents.length,
        'journalEntries': pendingJournalEntries.length,
      });

      return SyncResult.success(successCount, failureCount);
    } catch (e) {
      AppLogger.exception('_performSync', e);
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _syncSingleEvent(Event event) async {
    try {
      final firestoreService = FirestoreService();

      // Check if this is a deleted event (we might need to handle this differently)
      // For now, we'll assume all pending events are create/update operations

      final eventData = event.toJson();

      // Try to create the event (this will update if it already exists)
      await firestoreService.createEvent(eventData);

      return true;
    } catch (e) {
      AppLogger.exception('_syncSingleEvent ${event.id}', e);
      return false;
    }
  }

  Future<bool> _syncSingleNote(Note note) async {
    try {
      final firestoreService = FirestoreService();

      final noteData = note.toJson();

      // Try to create the note (this will update if it already exists)
      await firestoreService.createNote(noteData);

      return true;
    } catch (e) {
      AppLogger.exception('_syncSingleNote ${note.id}', e);
      return false;
    }
  }

  Future<bool> _syncSingleJournalEntry(JournalEntry entry) async {
    try {
      final firestoreService = FirestoreService();

      final entryData = entry.toFirestore();

      // Try to create the journal entry (this will update if it already exists)
      await firestoreService.createJournalEntry(entryData);

      return true;
    } catch (e) {
      AppLogger.exception('_syncSingleJournalEntry ${entry.id}', e);
      return false;
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      // Simple connectivity check - try to get current user
      // This will also validate Firebase connection
      final user = FirebaseAuth.instance.currentUser;
      return user != null;
    } catch (e) {
      return false;
    }
  }
}

/// Data classes for sync results and status

class SyncResult {
  final bool success;
  final int successfulSyncs;
  final int failedSyncs;
  final String? errorMessage;
  final SyncFailureReason? failureReason;

  SyncResult.success(this.successfulSyncs, this.failedSyncs)
    : success = true,
      errorMessage = null,
      failureReason = null;

  SyncResult.error(this.errorMessage)
    : success = false,
      successfulSyncs = 0,
      failedSyncs = 0,
      failureReason = SyncFailureReason.unknown;

  SyncResult.networkFailure()
    : success = false,
      successfulSyncs = 0,
      failedSyncs = 0,
      errorMessage = 'Network connectivity issue',
      failureReason = SyncFailureReason.network;

  SyncResult.authFailure()
    : success = false,
      successfulSyncs = 0,
      failedSyncs = 0,
      errorMessage = 'Authentication required',
      failureReason = SyncFailureReason.authentication;

  SyncResult.alreadyRunning()
    : success = false,
      successfulSyncs = 0,
      failedSyncs = 0,
      errorMessage = 'Sync already in progress',
      failureReason = SyncFailureReason.alreadyRunning;
}

enum SyncFailureReason { network, authentication, unknown, alreadyRunning }

class SyncStatus {
  final DateTime? lastSyncTime;
  final int pendingSyncCount;
  final bool isSyncing;
  final bool isConnected;

  SyncStatus({
    required this.lastSyncTime,
    required this.pendingSyncCount,
    required this.isSyncing,
    required this.isConnected,
  });

  bool get hasUnsyncedData => pendingSyncCount > 0;

  String get statusMessage {
    if (isSyncing) return 'Syncing...';
    if (!isConnected) return 'Offline';
    if (hasUnsyncedData) return '$pendingSyncCount items pending sync';
    return 'All synced';
  }
}
