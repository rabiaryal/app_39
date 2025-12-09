import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../widgets/app_logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Public getter for debugging
  String? get currentUserId => _userId;

  // Generic CRUD operations for any collection
  Future<String> createDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    if (_userId == null) {
      AppLogger.auth('CreateDocument failed: User not authenticated');
      return ''; // Return empty if not authenticated
    }

    try {
      AppLogger.firebase(
        'Creating document in collection: $collection',
        'CREATE',
      );
      AppLogger.auth('Creating document for user', _userId);

      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(_userId!)
          .collection(collection)
          .add({
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.firebase(
        'Document created successfully with ID: ${docRef.id}',
        'CREATE',
      );
      return docRef.id;
    } catch (e) {
      AppLogger.firebase('Firestore createDocument error: $e', 'ERROR');
      if (e.toString().contains('permission-denied')) {
        AppLogger.error(
          'Permission denied error - Check Firestore security rules',
          'FIRESTORE',
        );
        throw Exception(
          'Permission denied. Please check Firestore security rules.',
        );
      } else if (e.toString().contains('network-request-failed')) {
        AppLogger.network('Network error during Firestore operation');
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      } else {
        AppLogger.exception('Firestore createDocument', e);
        throw Exception('Failed to create document: $e');
      }
    }
  }

  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    if (_userId == null) return; // Do nothing if not authenticated

    try {
      await _firestore
          .collection('users')
          .doc(_userId!)
          .collection(collection)
          .doc(docId)
          .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  Future<void> deleteDocument(String collection, String docId) async {
    if (_userId == null) return; // Do nothing if not authenticated

    try {
      await _firestore
          .collection('users')
          .doc(_userId!)
          .collection(collection)
          .doc(docId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String docId,
  ) async {
    if (_userId == null) return null; // Return null if not authenticated

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_userId!)
          .collection(collection)
          .doc(docId)
          .get();

      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  Stream<QuerySnapshot> getCollectionStream(
    String collection, {
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    if (_userId == null)
      return const Stream.empty(); // Return empty stream if not authenticated

    Query query = _firestore
        .collection('users')
        .doc(_userId!)
        .collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  Future<List<Map<String, dynamic>>> getCollection(
    String collection, {
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    if (_userId == null) return []; // Return empty list if not authenticated

    try {
      Query query = _firestore
          .collection('users')
          .doc(_userId!)
          .collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Failed to get collection: $e');
    }
  }

  // Specific methods for different collections
  Future<String> createEvent(Map<String, dynamic> eventData) async {
    return createDocument('events', eventData);
  }

  Future<String> createFinanceRecord(Map<String, dynamic> financeData) async {
    return createDocument('finance', financeData);
  }

  Future<String> createNote(Map<String, dynamic> noteData) async {
    return createDocument('notes', noteData);
  }

  Future<String> createJournalEntry(Map<String, dynamic> journalData) async {
    return createDocument('journal', journalData);
  }

  Future<void> updateEvent(
    String eventId,
    Map<String, dynamic> eventData,
  ) async {
    return updateDocument('events', eventId, eventData);
  }

  Future<void> updateFinanceRecord(
    String recordId,
    Map<String, dynamic> financeData,
  ) async {
    return updateDocument('finance', recordId, financeData);
  }

  Future<void> updateNote(String noteId, Map<String, dynamic> noteData) async {
    return updateDocument('notes', noteId, noteData);
  }

  Future<void> updateJournalEntry(
    String entryId,
    Map<String, dynamic> journalData,
  ) async {
    return updateDocument('journal', entryId, journalData);
  }

  Future<void> deleteEvent(String eventId) async {
    return deleteDocument('events', eventId);
  }

  Future<void> deleteFinanceRecord(String recordId) async {
    return deleteDocument('finance', recordId);
  }

  Future<void> deleteNote(String noteId) async {
    return deleteDocument('notes', noteId);
  }

  Future<void> deleteJournalEntry(String entryId) async {
    return deleteDocument('journal', entryId);
  }

  Stream<QuerySnapshot> getEventsStream() {
    return getCollectionStream(
      'events',
      orderBy: 'createdAt',
      descending: true,
    );
  }

  Stream<QuerySnapshot> getFinanceStream() {
    return getCollectionStream('finance', orderBy: 'date', descending: true);
  }

  Stream<QuerySnapshot> getNotesStream() {
    return getCollectionStream('notes', orderBy: 'updatedAt', descending: true);
  }

  Stream<QuerySnapshot> getJournalEntriesStream() {
    return getCollectionStream(
      'journal',
      orderBy: 'createdAt',
      descending: true,
    );
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    return getCollection('events', orderBy: 'createdAt', descending: true);
  }

  Future<List<Map<String, dynamic>>> getFinanceRecords() async {
    return getCollection('finance', orderBy: 'date', descending: true);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    return getCollection('notes', orderBy: 'updatedAt', descending: true);
  }

  Future<List<Map<String, dynamic>>> getJournalEntries() async {
    return getCollection('journal', orderBy: 'createdAt', descending: true);
  }
}
