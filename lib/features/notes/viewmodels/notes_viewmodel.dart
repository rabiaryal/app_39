import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../models/note_service.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/services/firebase_providers.dart';

// State class for notes
class NotesState {
  final List<Note> notes;
  final bool isLoading;
  final String? error;

  const NotesState({this.notes = const [], this.isLoading = false, this.error});

  NotesState copyWith({List<Note>? notes, bool? isLoading, String? error}) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notes notifier
class NotesNotifier extends StateNotifier<NotesState> {
  bool _isRefreshing = false;
  bool _isInitialized = false;

  NotesNotifier() : super(const NotesState()) {
    // Don't load notes in constructor to avoid Riverpod state modification error
    // Load notes will be called explicitly when needed
  }

  Future<void> _safeLoadNotes() async {
    try {
      await loadNotes();
    } catch (e) {
      print('Error in _safeLoadNotes: $e');
      // Ensure loading state is false even if there's an error
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadNotes() async {
    if (_isRefreshing) {
      print('NotesNotifier: Already loading, skipping duplicate call');
      return;
    }

    _isRefreshing = true;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Wait briefly for Hive to be ready if needed
      if (!HiveService.isInitialized) {
        print('NotesNotifier: Waiting for Hive initialization');
        await _waitForHive();
      }

      final notes = NoteService.getAllNotes();
      state = state.copyWith(notes: notes, isLoading: false);
      print('Notes loaded successfully: ${notes.length} notes');
    } catch (e) {
      print('Error loading notes: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _waitForHive() async {
    int attempts = 0;
    const maxAttempts = 50; // 2.5 seconds max

    while (!HiveService.isInitialized && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }

    if (!HiveService.isInitialized) {
      print('Warning: Hive still not initialized after waiting');
      throw Exception('Hive initialization timeout');
    }
  }

  Future<void> addNote(Note note) async {
    try {
      await NoteService.addNote(note);
      final updatedNotes = [note, ...state.notes];
      state = state.copyWith(notes: updatedNotes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await NoteService.updateNote(note);
      final updatedNotes = state.notes.map((n) {
        return n.id == note.id ? note : n;
      }).toList();
      state = state.copyWith(notes: updatedNotes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await NoteService.deleteNote(id);
      final updatedNotes = state.notes.where((n) => n.id != id).toList();
      state = state.copyWith(notes: updatedNotes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> togglePinNote(String id) async {
    try {
      await NoteService.togglePinNote(id);
      final updatedNotes = state.notes.map((n) {
        if (n.id == id) {
          return n.copyWith(isPinned: !n.isPinned, updatedAt: DateTime.now());
        }
        return n;
      }).toList();
      // Re-sort notes with pinned notes first
      updatedNotes.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      state = state.copyWith(notes: updatedNotes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return state.notes;

    final searchTerm = query.toLowerCase();
    return state.notes.where((note) {
      return note.title.toLowerCase().contains(searchTerm) ||
          note.content.toLowerCase().contains(searchTerm) ||
          (note.tags?.any((tag) => tag.toLowerCase().contains(searchTerm)) ??
              false);
    }).toList();
  }

  List<Note> getNotesByCategory(String category) {
    return state.notes.where((note) => note.category == category).toList();
  }

  List<Note> getPinnedNotes() {
    return state.notes.where((note) => note.isPinned).toList();
  }

  List<String> getAllCategories() {
    final categories = <String>{};
    for (var note in state.notes) {
      if (note.category != null) {
        categories.add(note.category!);
      }
    }
    return categories.toList()..sort();
  }

  List<String> getAllTags() {
    final tags = <String>{};
    for (var note in state.notes) {
      if (note.tags != null) {
        tags.addAll(note.tags!);
      }
    }
    return tags.toList()..sort();
  }

  // Refresh notes after user switch
  Future<void> refreshAfterUserSwitch() async {
    if (_isRefreshing) {
      print('NotesNotifier: Already refreshing, skipping duplicate call');
      return;
    }

    _isRefreshing = true;
    try {
      print('NotesNotifier: Refreshing notes after user switch');
      state = state.copyWith(isLoading: true, error: null, notes: []);

      // Wait for user boxes to be ready
      await Future.delayed(const Duration(milliseconds: 300));
      await loadNotes();
    } finally {
      _isRefreshing = false;
    }
  } // Clear all notes

  Future<void> clearAllNotes() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await NoteService.clearAllNotes();
      await loadNotes();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Update note status
  Future<void> updateNoteStatus(String id, NoteStatus status) async {
    try {
      await NoteService.updateNoteStatus(id, status);
      final updatedNotes = state.notes.map((note) {
        if (note.id == id) {
          return note.copyWith(status: status, updatedAt: DateTime.now());
        }
        return note;
      }).toList();
      state = state.copyWith(notes: updatedNotes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Providers
final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  final notifier = NotesNotifier();

  // TODO: Fix auth listener - temporarily disabled to prevent infinite loading
  // Listen to auth state changes
  // ref.listen(authStateProvider, (previous, next) {
  //   next.whenData((user) async {
  //     final previousUser = previous?.value;
  //     // If user changed (login/logout/switch account)
  //     if (previousUser?.uid != user?.uid) {
  //       print(
  //         'Notes: User changed from ${previousUser?.uid} to ${user?.uid}, refreshing notes',
  //       );
  //       // Wait a bit for HiveService.switchUser to complete
  //       await Future.delayed(const Duration(milliseconds: 500));
  //       await notifier.refreshAfterUserSwitch();
  //     }
  //   });
  // });

  return notifier;
});

// Helper providers
final pinnedNotesProvider = Provider<List<Note>>((ref) {
  final notesState = ref.watch(notesProvider);
  return notesState.notes.where((note) => note.isPinned).toList();
});

final notesCategoriesProvider = Provider<List<String>>((ref) {
  final notesState = ref.watch(notesProvider);
  final categories = <String>{};
  for (var note in notesState.notes) {
    if (note.category != null) {
      categories.add(note.category!);
    }
  }
  return categories.toList()..sort();
});

final notesTagsProvider = Provider<List<String>>((ref) {
  final notesState = ref.watch(notesProvider);
  final tags = <String>{};
  for (var note in notesState.notes) {
    if (note.tags != null) {
      tags.addAll(note.tags!);
    }
  }
  return tags.toList()..sort();
});

final notesByCategoryProvider = Provider.family<List<Note>, String>((
  ref,
  category,
) {
  final notesState = ref.watch(notesProvider);
  return notesState.notes.where((note) => note.category == category).toList();
});

final searchNotesProvider = Provider.family<List<Note>, String>((ref, query) {
  final notesState = ref.watch(notesProvider);
  if (query.isEmpty) return notesState.notes;

  final searchTerm = query.toLowerCase();
  return notesState.notes.where((note) {
    return note.title.toLowerCase().contains(searchTerm) ||
        note.content.toLowerCase().contains(searchTerm) ||
        (note.tags?.any((tag) => tag.toLowerCase().contains(searchTerm)) ??
            false);
  }).toList();
});
