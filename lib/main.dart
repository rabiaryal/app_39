import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/home_widget_service.dart';
import 'core/services/firebase_providers.dart';
import 'core/widgets/router.dart';
import 'core/theme.dart';
import 'features/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize timezone data early to prevent LateInitializationError
  tz.initializeTimeZones();

  // Initialize Hive storage with no user initially (anonymous)
  await HiveService.init();

  // Initialize local storage (SharedPreferences)
  try {
    await LocalStorageService.getInstance();
    debugPrint('Local storage initialized successfully');
  } catch (e) {
    debugPrint('Error initializing local storage: $e');
  }

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Request notification permissions with better error handling
  try {
    final bool permissionsGranted = await notificationService
        .requestPermissions();
    if (!permissionsGranted) {
      debugPrint('Notification permissions were not granted');
      // You could show a dialog here to inform the user
    } else {
      debugPrint('Notification permissions granted successfully');
    }
  } catch (e) {
    debugPrint('Error requesting notification permissions: $e');
  }

  // Initialize auth service - this will start sync when user logs in
  try {
    await AuthService.initialize();
    debugPrint('Auth service initialized successfully');
  } catch (e) {
    debugPrint('Error initializing auth service: $e');
  }

  // Initialize home widget service
  try {
    await HomeWidgetService.initialize();
    await HomeWidgetService.schedulePeriodicUpdates();
    debugPrint('Home widget service initialized successfully');
  } catch (e) {
    debugPrint('Error initializing home widget service: $e');
  }

  // Note: Background sync will be started automatically when user logs in
  // This ensures the app works completely offline until user authenticates

  // Initialize timer service with existing events
  // TODO: Update this to use Firebase EventService when viewmodels are updated
  /*
  try {
    final events = EventService.getAllEvents();
    EventTimerService.initialize(events, (updatedEvents) {
      // This callback will be updated when the events screen is active
    });
  } catch (e) {
    // Handle initialization error gracefully
    debugPrint('Error initializing timer service: $e');
  }
  */

  runApp(const ProviderScope(child: MyApp()));
}

// Auth State Manager to handle user switching
class AuthStateManager extends ConsumerWidget {
  final Widget child;

  const AuthStateManager({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (previous, next) async {
      // Handle auth state changes
      next.whenData((user) async {
        final previousUser = previous?.value;

        // If user changed (login/logout/switch account)
        if (previousUser?.uid != user?.uid) {
          try {
            await HiveService.switchUser(user?.uid);
            debugPrint('Switched to user: ${user?.uid ?? "anonymous"}');
          } catch (e) {
            debugPrint('Error switching user: $e');
          }
        }
      });
    });

    return child;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return AuthStateManager(
      child: MaterialApp.router(
        title: 'Daily Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}
