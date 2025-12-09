import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/daily_activities/models/event_service.dart';
import '../widgets/app_logger.dart';

/// Service to handle Firebase authentication and sync startup
class AuthService {
  static AuthService? _instance;
  static StreamSubscription<User?>? _authSubscription;

  AuthService._();

  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  /// Initialize auth service and listen for auth state changes
  static Future<void> initialize() async {
    try {
      // Listen for auth state changes
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        (User? user) async {
          if (user != null) {
            AppLogger.auth('User authenticated, starting background sync');
            // User is signed in, start background sync
            await EventService.startBackgroundSyncOnAuth();
          } else {
            AppLogger.auth('User signed out, stopping background sync');
            // User is signed out, stop background sync
            EventService.stopBackgroundSync();
          }
        },
        onError: (error) {
          AppLogger.exception('Auth state change listener', error);
        },
      );

      AppLogger.info('Auth service initialized', 'AUTH');
    } catch (e) {
      AppLogger.exception('AuthService.initialize', e);
    }
  }

  /// Get current user
  static User? get currentUser => FirebaseAuth.instance.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Dispose auth service
  static Future<void> dispose() async {
    try {
      await _authSubscription?.cancel();
      _authSubscription = null;
      AppLogger.info('Auth service disposed', 'AUTH');
    } catch (e) {
      AppLogger.exception('AuthService.dispose', e);
    }
  }
}
