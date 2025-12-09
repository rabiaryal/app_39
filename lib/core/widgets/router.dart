import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/widgets/persistent_navigation.dart';
import '../../features/daily_activities/UI/add_event_screen.dart';
import '../../features/notes/UI/add_note_screen.dart';
import '../../features/journal/screens/add_journal_entry_screen.dart';
import '../../features/daily_activities/History/event_history_screen.dart';
import '../../features/notes/History/note_history_screen.dart';
import '../../dashboard/screens/stats_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../services/firebase_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );

      final isAuthRoute = state.matchedLocation == '/auth';
      final isGoingToAuth = state.matchedLocation == '/auth';

      // If not authenticated and not already going to auth screen, redirect to auth
      if (!isAuthenticated && !isGoingToAuth) {
        return '/auth';
      }

      // If authenticated and going to auth screen, redirect to main
      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
        routes: [
          GoRoute(
            path: 'forgot-password',
            name: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/',
        name: 'main',
        builder: (context, state) => const PersistentNavigation(),
        routes: [
          // Add screens for modal navigation
          GoRoute(
            path: 'add-event',
            name: 'add-event',
            builder: (context, state) => const AddEventScreen(),
          ),
          GoRoute(
            path: 'edit-event/:id',
            name: 'edit-event',
            builder: (context, state) {
              final eventId = state.pathParameters['id']!;
              return AddEventScreen(eventId: eventId);
            },
          ),

          GoRoute(
            path: 'add-note',
            name: 'add-note',
            builder: (context, state) => const AddNoteScreen(),
          ),
          GoRoute(
            path: 'edit-note/:id',
            name: 'edit-note',
            builder: (context, state) {
              final noteId = state.pathParameters['id']!;
              return AddNoteScreen(noteId: noteId);
            },
          ),
          GoRoute(
            path: 'add-journal',
            name: 'add-journal',
            builder: (context, state) => const AddJournalEntryScreen(),
          ),
          GoRoute(
            path: 'edit-journal/:id',
            name: 'edit-journal',
            builder: (context, state) {
              final journalId = state.pathParameters['id']!;
              return AddJournalEntryScreen(journalId: journalId);
            },
          ),
          GoRoute(
            path: 'event-history',
            name: 'event-history',
            builder: (context, state) => const EventHistoryScreen(),
          ),

          GoRoute(
            path: 'note-history',
            name: 'note-history',
            builder: (context, state) => const NoteHistoryScreen(),
          ),
          GoRoute(
            path: 'stats',
            name: 'stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

// Helper class for navigation
class AppNavigation {
  // Main tab navigation - now handled by persistent navigation
  static void goToDashboard(BuildContext context) {
    // Navigation handled by PersistentNavigation
  }

  static void goToEvents(BuildContext context) {
    // Navigation handled by PersistentNavigation
  }

  static void goToJournal(BuildContext context) {
    // Navigation handled by PersistentNavigation
  }

  static void goToNotes(BuildContext context) {
    // Navigation handled by PersistentNavigation
  }

  static void goToAppointments(BuildContext context) {
    // Navigation handled by PersistentNavigation
  }

  // Modal navigation for add/edit screens
  static void goToAddEvent(BuildContext context) {
    context.go('/add-event');
  }

  static void goToEditEvent(BuildContext context, String eventId) {
    context.go('/edit-event/$eventId');
  }

  static void goToAddNote(BuildContext context) {
    context.go('/add-note');
  }

  static void goToEditNote(BuildContext context, String noteId) {
    context.go('/edit-note/$noteId');
  }

  static void goToAddJournal(BuildContext context) {
    context.go('/add-journal');
  }

  static void goToAddJournalEntry(BuildContext context) {
    context.go('/add-journal');
  }

  static void goToEditJournalEntry(BuildContext context, String journalId) {
    context.go('/edit-journal/$journalId');
  }

  static void goToAddAppointment(BuildContext context) {
    // Not implemented yet
  }

  static void goToEditAppointment(BuildContext context, String appointmentId) {
    // Not implemented yet
  }

  // History navigation methods
  static void goToEventHistory(BuildContext context) {
    context.go('/event-history');
  }

  static void goToTransactionHistory(BuildContext context) {
    context.go('/transaction-history');
  }

  static void goToNotesHistory(BuildContext context) {
    context.go('/note-history');
  }

  static void goToStats(BuildContext context) {
    context.go('/stats');
  }

  static void goToSettings(BuildContext context) {
    context.go('/settings');
  }
}
