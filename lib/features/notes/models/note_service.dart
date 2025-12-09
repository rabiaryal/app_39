import '../models/note.dart';
import '../services/hive_note_service.dart' as hive_service;
import '../../../core/services/background_sync_service.dart';
import '../../../core/widgets/app_logger.dart';

/// Service for managing notes with local-first approach
/// Uses Hive as local storage and syncs to Firebase in background
class NoteService {
  /// Add a new note (local-first)
  static Future<void> addNote(Note note) async {
    AppLogger.userAction('Add Note Started', {
      'noteTitle': note.title,
      'category': note.category,
    });

    try {
      AppLogger.debug('Step 1: Saving note to local storage', 'NOTE_SERVICE');

      // 1. Save to Hive first (immediate response)
      await hive_service.NoteService.addNote(note);

      AppLogger.userAction('Note saved locally', {
        'noteId': note.id,
        'noteTitle': note.title,
      });

      // 2. Trigger background sync (non-blocking)
      try {
        AppLogger.debug('Step 2: Triggering background sync', 'NOTE_SERVICE');
        _triggerBackgroundSync(note.id);
        AppLogger.debug(
          'Step 3: Background sync triggered successfully',
          'NOTE_SERVICE',
        );
      } catch (e) {
        AppLogger.warning('Background sync trigger failed: $e', 'NOTE_SERVICE');
        // Don't throw - sync failure shouldn't prevent note creation
      }

      AppLogger.userAction('Add Note Completed Successfully', {
        'noteId': note.id,
        'noteTitle': note.title,
        'storageType': 'local-first',
      });
    } catch (e) {
      AppLogger.exception('addNote failed completely', e);
      throw Exception('Failed to add note: $e');
    }
  }

  /// Update a note (local-first)
  static Future<void> updateNote(Note note) async {
    try {
      AppLogger.userAction('Update Note Started', {
        'noteId': note.id,
        'noteTitle': note.title,
      });

      // 1. Update Hive first
      await hive_service.NoteService.updateNote(note);

      AppLogger.userAction('Note updated locally', {
        'noteId': note.id,
        'noteTitle': note.title,
      });

      // 2. Trigger background sync
      _triggerBackgroundSync(note.id);

      AppLogger.userAction('Update Note Completed', {
        'noteId': note.id,
        'storageType': 'local-first',
      });
    } catch (e) {
      AppLogger.exception('updateNote', e);
      throw Exception('Failed to update note: $e');
    }
  }

  /// Delete a note (local-first)
  static Future<void> deleteNote(String id) async {
    try {
      AppLogger.userAction('Delete Note Started', {'noteId': id});

      // 1. Delete from Hive first
      await hive_service.NoteService.deleteNote(id);

      AppLogger.userAction('Note deleted locally', {'noteId': id});

      // 2. Trigger background sync for deletion
      _triggerBackgroundSync(id);

      AppLogger.userAction('Delete Note Completed', {
        'noteId': id,
        'storageType': 'local-first',
      });
    } catch (e) {
      AppLogger.exception('deleteNote', e);
      throw Exception('Failed to delete note: $e');
    }
  }

  /// Get a single note
  static Note? getNote(String id) {
    try {
      return hive_service.NoteService.getNote(id);
    } catch (e) {
      AppLogger.exception('getNote', e);
      return null;
    }
  }

  /// Get all notes
  static List<Note> getAllNotes() {
    try {
      return hive_service.NoteService.getAllNotes();
    } catch (e) {
      AppLogger.exception('getAllNotes', e);
      return [];
    }
  }

  /// Get notes by date
  static List<Note> getNotesByDate(DateTime date) {
    try {
      return hive_service.NoteService.getNotesByDate(date);
    } catch (e) {
      AppLogger.exception('getNotesByDate', e);
      return [];
    }
  }

  /// Search notes
  static List<Note> searchNotes(String query) {
    try {
      return hive_service.NoteService.searchNotes(query);
    } catch (e) {
      AppLogger.exception('searchNotes', e);
      return [];
    }
  }

  /// Get notes by category
  static List<Note> getNotesByCategory(String category) {
    try {
      return hive_service.NoteService.getNotesByCategory(category);
    } catch (e) {
      AppLogger.exception('getNotesByCategory', e);
      return [];
    }
  }

  /// Get notes by tag
  static List<Note> getNotesByTag(String tag) {
    try {
      return hive_service.NoteService.getNotesByTag(tag);
    } catch (e) {
      AppLogger.exception('getNotesByTag', e);
      return [];
    }
  }

  /// Get pinned notes
  static List<Note> getPinnedNotes() {
    try {
      return hive_service.NoteService.getPinnedNotes();
    } catch (e) {
      AppLogger.exception('getPinnedNotes', e);
      return [];
    }
  }

  /// Toggle pin note
  static Future<void> togglePinNote(String id) async {
    try {
      await hive_service.NoteService.togglePinNote(id);
      _triggerBackgroundSync(id);
    } catch (e) {
      AppLogger.exception('togglePinNote', e);
      throw Exception('Failed to toggle pin note: $e');
    }
  }

  /// Get all categories
  static List<String> getAllCategories() {
    try {
      return hive_service.NoteService.getAllCategories();
    } catch (e) {
      AppLogger.exception('getAllCategories', e);
      return [];
    }
  }

  /// Get all tags
  static List<String> getAllTags() {
    try {
      return hive_service.NoteService.getAllTags();
    } catch (e) {
      AppLogger.exception('getAllTags', e);
      return [];
    }
  }

  /// Get total notes count
  static int getTotalNotesCount() {
    try {
      return hive_service.NoteService.getTotalNotesCount();
    } catch (e) {
      AppLogger.exception('getTotalNotesCount', e);
      return 0;
    }
  }

  /// Get pinned notes count
  static int getPinnedNotesCount() {
    try {
      return hive_service.NoteService.getPinnedNotesCount();
    } catch (e) {
      AppLogger.exception('getPinnedNotesCount', e);
      return 0;
    }
  }

  /// Clear all notes
  static Future<void> clearAllNotes() async {
    try {
      await hive_service.NoteService.clearAllNotes();
    } catch (e) {
      throw Exception('Failed to clear all notes: $e');
    }
  }

  /// Update note status
  static Future<void> updateNoteStatus(String id, NoteStatus status) async {
    try {
      await hive_service.NoteService.updateNoteStatus(id, status);
      _triggerBackgroundSync(id);
    } catch (e) {
      throw Exception('Failed to update note status: $e');
    }
  }

  /// Sync Management Methods

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

  /// Private helper method to trigger background sync
  static void _triggerBackgroundSync(String noteId) {
    try {
      // Fire and forget - trigger sync without waiting
      // This should NEVER block local operations
      Future.microtask(() async {
        try {
          final syncService = BackgroundSyncService.instance;
          await syncService.syncNoteImmediately(noteId);
        } catch (e) {
          // Sync failure should not affect local operations
          AppLogger.warning(
            'Background sync failed for note $noteId: $e',
            'SYNC',
          );
        }
      });

      AppLogger.debug('Background sync triggered for note: $noteId', 'SYNC');
    } catch (e) {
      // Even triggering sync failure should not affect local operations
      AppLogger.warning(
        'Failed to trigger background sync for note $noteId: $e',
        'SYNC',
      );
    }
  }
}
