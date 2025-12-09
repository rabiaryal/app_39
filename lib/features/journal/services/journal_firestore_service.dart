import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';

class JournalFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's UID
  static String? get _currentUserId => _auth.currentUser?.uid;

  // Get reference to user's journals collection
  static CollectionReference<Map<String, dynamic>>? get _journalsCollection {
    if (_currentUserId == null) return null;
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('journals');
  }

  /// Add a new journal entry
  static Future<String> addEntry(JournalEntry entry) async {
    try {
      if (_journalsCollection == null) {
        throw Exception('User not authenticated');
      }

      final docRef = await _journalsCollection!.add(entry.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add journal entry: $e');
    }
  }

  /// Update an existing journal entry
  static Future<void> updateEntry(JournalEntry entry) async {
    try {
      if (_journalsCollection == null) {
        throw Exception('User not authenticated');
      }

      await _journalsCollection!
          .doc(entry.id)
          .update(entry.toFirestoreUpdate());
    } catch (e) {
      throw Exception('Failed to update journal entry: $e');
    }
  }

  /// Delete a journal entry
  static Future<void> deleteEntry(String entryId) async {
    try {
      if (_journalsCollection == null) {
        throw Exception('User not authenticated');
      }

      await _journalsCollection!.doc(entryId).delete();
    } catch (e) {
      throw Exception('Failed to delete journal entry: $e');
    }
  }

  /// Get a specific journal entry
  static Future<JournalEntry?> getEntry(String entryId) async {
    try {
      if (_journalsCollection == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _journalsCollection!.doc(entryId).get();
      if (doc.exists) {
        return JournalEntry.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get journal entry: $e');
    }
  }

  /// Get all journal entries as a stream (real-time updates)
  static Stream<List<JournalEntry>> getEntries() {
    if (_journalsCollection == null) {
      return Stream.error('User not authenticated');
    }

    return _journalsCollection!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JournalEntry.fromFirestore(doc))
              .toList();
        });
  }

  /// Get journal entries for a specific date range
  static Stream<List<JournalEntry>> getEntriesInDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (_journalsCollection == null) {
      return Stream.error('User not authenticated');
    }

    return _journalsCollection!
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JournalEntry.fromFirestore(doc))
              .toList();
        });
  }

  /// Get journal entries by mood
  static Stream<List<JournalEntry>> getEntriesByMood(Mood mood) {
    if (_journalsCollection == null) {
      return Stream.error('User not authenticated');
    }

    return _journalsCollection!
        .where('mood', isEqualTo: mood.toString())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JournalEntry.fromFirestore(doc))
              .toList();
        });
  }

  /// Search journal entries by title or content
  static Future<List<JournalEntry>> searchEntries(String query) async {
    try {
      if (_journalsCollection == null) {
        throw Exception('User not authenticated');
      }

      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that searches by title prefix
      final snapshot = await _journalsCollection!
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('title')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => JournalEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search journal entries: $e');
    }
  }

  /// Get journal entries count
  static Future<int> getEntriesCount() async {
    try {
      if (_journalsCollection == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _journalsCollection!.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get entries count: $e');
    }
  }

  /// Get mood distribution for analytics
  static Future<Map<Mood, int>> getMoodDistribution() async {
    try {
      if (_journalsCollection == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _journalsCollection!.get();
      final Map<Mood, int> moodCount = {};

      // Initialize all moods with 0
      for (final mood in Mood.values) {
        moodCount[mood] = 0;
      }

      // Count occurrences
      for (final doc in snapshot.docs) {
        final entry = JournalEntry.fromFirestore(doc);
        moodCount[entry.mood] = (moodCount[entry.mood] ?? 0) + 1;
      }

      return moodCount;
    } catch (e) {
      throw Exception('Failed to get mood distribution: $e');
    }
  }

  /// Delete all journal entries (use with caution)
  static Future<void> deleteAllEntries() async {
    try {
      if (_journalsCollection == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _journalsCollection!.get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all journal entries: $e');
    }
  }

  /// Batch add multiple journal entries
  static Future<void> batchAddEntries(List<JournalEntry> entries) async {
    try {
      if (_journalsCollection == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();

      for (final entry in entries) {
        final docRef = _journalsCollection!.doc();
        batch.set(docRef, entry.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch add journal entries: $e');
    }
  }
}
