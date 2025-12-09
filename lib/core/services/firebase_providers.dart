import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

// Firebase Auth Service Provider
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Firestore Service Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Auth State Provider
final authStateProvider = StreamProvider((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(data: (user) => user, orElse: () => null);
});

// Events Stream Provider
final eventsStreamProvider = StreamProvider((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getEventsStream();
});

// Finance Stream Provider
final financeStreamProvider = StreamProvider((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getFinanceStream();
});

// Notes Stream Provider
final notesStreamProvider = StreamProvider((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getNotesStream();
});
