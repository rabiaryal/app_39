import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';

class JournalState {
  final List<JournalEntry> entries;
  final bool isLoading;
  final String? error;

  const JournalState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  JournalState copyWith({
    List<JournalEntry>? entries,
    bool? isLoading,
    String? error,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class JournalNotifier extends StateNotifier<JournalState> {
  JournalNotifier() : super(const JournalState()) {
    // Delay loading to ensure local storage is initialized
    Future.delayed(const Duration(milliseconds: 100), () async {
      await loadEntries();
    });
  }

  /// Load all journal entries from local storage
  Future<void> loadEntries() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entries = await JournalService.getAllEntries();
      state = state.copyWith(entries: entries, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add a new journal entry
  Future<void> addEntry(JournalEntry entry) async {
    try {
      await JournalService.addEntry(entry);
      // Reload from local storage to get updated list
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Update an existing journal entry
  Future<void> updateEntry(JournalEntry entry) async {
    try {
      await JournalService.updateEntry(entry);
      // Reload from local storage to get updated list
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Delete a journal entry
  Future<void> deleteEntry(String entryId) async {
    try {
      await JournalService.deleteEntry(entryId);
      // Reload from local storage to get updated list
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Search journal entries
  Future<List<JournalEntry>> searchEntries(String query) async {
    try {
      return await JournalService.searchEntries(query);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Get mood distribution for analytics
  Future<Map<Mood, int>> getMoodDistribution() async {
    try {
      return await JournalService.getMoodDistribution();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final journalProvider = StateNotifierProvider<JournalNotifier, JournalState>(
  (ref) => JournalNotifier(),
);

// Today's entries provider
final todayEntriesProvider = Provider<List<JournalEntry>>((ref) {
  final journalState = ref.watch(journalProvider);
  final today = DateTime.now();

  return journalState.entries.where((entry) {
    return entry.createdAt.year == today.year &&
        entry.createdAt.month == today.month &&
        entry.createdAt.day == today.day;
  }).toList();
});

// Recent entries provider (last 7 days)
final recentEntriesProvider = Provider<List<JournalEntry>>((ref) {
  final journalState = ref.watch(journalProvider);
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

  return journalState.entries.where((entry) {
    return entry.createdAt.isAfter(sevenDaysAgo);
  }).toList();
});

// Entries by mood provider
final entriesByMoodProvider = Provider.family<List<JournalEntry>, Mood>((
  ref,
  mood,
) {
  final journalState = ref.watch(journalProvider);
  return journalState.entries.where((entry) => entry.mood == mood).toList();
});

// Entry count provider
final entryCountProvider = Provider<int>((ref) {
  final journalState = ref.watch(journalProvider);
  return journalState.entries.length;
});
