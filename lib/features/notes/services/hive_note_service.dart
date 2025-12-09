import 'package:hive/hive.dart';
import '../models/note.dart';
import '../../../core/services/hive_service.dart';

class NoteService {
  static Box<Note> get _box => HiveService.notesBox;

  static Future<void> addNote(Note note) async {
    try {
      if (!HiveService.isInitialized) {
        throw Exception('Hive not initialized');
      }
      final box = _box;
      if (!box.isOpen) {
        throw Exception('Notes box is not open');
      }
      await box.put(note.id, note);
    } catch (e) {
      print('NoteService: Error adding note: $e');
      rethrow;
    }
  }

  static Future<void> updateNote(Note note) async {
    await _box.put(note.id, note);
  }

  static Future<void> deleteNote(String id) async {
    await _box.delete(id);
  }

  static Note? getNote(String id) {
    return _box.get(id);
  }

  static List<Note> getAllNotes() {
    try {
      // Check if HiveService is initialized first
      if (!HiveService.isInitialized) {
        print('NoteService: Hive not initialized, returning empty list');
        return [];
      }

      // Additional check to ensure the box is actually accessible
      final box = _box;
      if (!box.isOpen) {
        print('NoteService: Notes box is not open, returning empty list');
        return [];
      }

      return box.values.toList()..sort((a, b) {
        // Pinned notes first
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        // Then by creation date (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });
    } catch (e) {
      // If Hive box is not ready, return empty list
      print('NoteService: Error getting notes, returning empty list: $e');
      return [];
    }
  }

  static List<Note> getNotesByDate(DateTime date) {
    return _box.values.where((note) {
      return note.date.year == date.year &&
          note.date.month == date.month &&
          note.date.day == date.day;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<Note> searchNotes(String query) {
    final searchTerm = query.toLowerCase();
    return _box.values.where((note) {
      return note.title.toLowerCase().contains(searchTerm) ||
          note.content.toLowerCase().contains(searchTerm) ||
          (note.tags?.any((tag) => tag.toLowerCase().contains(searchTerm)) ??
              false);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<Note> getNotesByCategory(String category) {
    return _box.values.where((note) {
      return note.category == category;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<Note> getNotesByTag(String tag) {
    return _box.values.where((note) {
      return note.tags?.contains(tag) ?? false;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<Note> getPinnedNotes() {
    return _box.values.where((note) => note.isPinned).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> togglePinNote(String id) async {
    final note = getNote(id);
    if (note != null) {
      final updatedNote = note.copyWith(
        isPinned: !note.isPinned,
        updatedAt: DateTime.now(),
      );
      await updateNote(updatedNote);
    }
  }

  static List<String> getAllCategories() {
    final categories = <String>{};
    for (var note in _box.values) {
      if (note.category != null) {
        categories.add(note.category!);
      }
    }
    return categories.toList()..sort();
  }

  static List<String> getAllTags() {
    final tags = <String>{};
    for (var note in _box.values) {
      if (note.tags != null) {
        tags.addAll(note.tags!);
      }
    }
    return tags.toList()..sort();
  }

  static int getTotalNotesCount() {
    return _box.length;
  }

  static int getPinnedNotesCount() {
    return _box.values.where((note) => note.isPinned).length;
  }

  static Future<void> clearAllNotes() async {
    await _box.clear();
  }

  static Future<void> updateNoteStatus(String id, NoteStatus status) async {
    final note = _box.get(id);
    if (note != null) {
      final updatedNote = note.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      await _box.put(id, updatedNote);
    }
  }
}
