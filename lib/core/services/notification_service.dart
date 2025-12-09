import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import '../../features/daily_activities/models/event.dart';

import '../../features/notes/models/note.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'app_039_channel';
  static const String _channelName = 'App 039 Notifications';
  static const String _channelDescription =
      'Notifications for events, appointments, and reminders';

  /// Initialize the notification service with proper permissions and channel setup
  Future<void> initialize() async {
    // Initialize timezone data first to prevent LateInitializationError
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          requestCriticalPermission: false,
          requestProvisionalPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Create notification channel for Android with proper importance
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Request permissions after initialization
    await requestPermissions();
  }

  void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) {
    // Handle notification tap
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      // You can navigate to specific screens based on payload
      // TODO: Implement navigation logic based on payload
    }
  }

  // Generic notification template methods
  Future<void> showCompletionNotification({
    required String title,
    required String body,
    required String payload,
    int notificationId = 0,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      enableLights: true,
      enableVibration: true,
      playSound: true,
      channelShowBadge: true,
    );

    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Event-specific notification methods
  Future<void> showEventCompletionNotification(Event event) async {
    final title = 'Event Completed! 🎉';
    final body = '"${event.title}" has been completed successfully!';
    final payload = 'event:${event.id}';

    await showCompletionNotification(
      title: title,
      body: body,
      payload: payload,
      notificationId: event.id.hashCode,
    );
  }

  Future<void> showEventReminderNotification(Event event) async {
    final title = 'Upcoming Event Reminder';
    final body =
        '"${event.title}" is scheduled for ${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}';
    final payload = 'event_reminder:${event.id}';

    await showCompletionNotification(
      title: title,
      body: body,
      payload: payload,
      notificationId: event.id.hashCode + 1000,
    );
  }

  /// Schedule event notifications: 5 minutes before, at start, and at completion
  Future<void> scheduleEventNotifications(Event event) async {
    final now = DateTime.now();

    // Schedule 5-minute reminder (only if event is more than 5 minutes away)
    final fiveMinutesBefore = event.startTime.subtract(
      const Duration(minutes: 5),
    );
    if (fiveMinutesBefore.isAfter(now)) {
      await scheduleNotification(
        id: event.id.hashCode + 1000,
        title: 'Event Starting Soon! ⏰',
        body: '"${event.title}" starts in 5 minutes',
        scheduledDate: fiveMinutesBefore,
        payload: 'event_reminder_5min:${event.id}',
      );
    }

    // Schedule start notification
    if (event.startTime.isAfter(now)) {
      await scheduleNotification(
        id: event.id.hashCode + 2000,
        title: 'Event Started! 🚀',
        body: '"${event.title}" is starting now',
        scheduledDate: event.startTime,
        payload: 'event_start:${event.id}',
      );
    }

    // Schedule completion notification (only for events with endTime)
    if (event.endTime != null && event.endTime!.isAfter(now)) {
      await scheduleNotification(
        id: event.id.hashCode + 3000,
        title: 'Event Completed! 🎉',
        body: '"${event.title}" has ended. How was it?',
        scheduledDate: event.endTime!,
        payload: 'event_completion:${event.id}',
      );
    }
  }

  /// Cancel all scheduled notifications for an event
  Future<void> cancelEventNotifications(Event event) async {
    await cancelNotification(event.id.hashCode + 1000); // 5-minute reminder
    await cancelNotification(event.id.hashCode + 2000); // Start notification
    await cancelNotification(
      event.id.hashCode + 3000,
    ); // Completion notification
  }

  // Appointment-specific notification methods


  
  

  // Note-specific notification methods
  Future<void> showNoteCompletionNotification(Note note) async {
    final title = 'Note Completed! 📝';
    final body = '"${note.title}" has been marked as completed!';
    final payload = 'note:${note.id}';

    await showCompletionNotification(
      title: title,
      body: body,
      payload: payload,
      notificationId: note.id.hashCode,
    );
  }

  // Test immediate notification (for debugging permission issues)
  Future<void> showTestNotification() async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        enableLights: true,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      9999, // Unique ID for test notification
      'Test Notification ��',
      'This is a test to verify notifications are working properly!',
      notificationDetails,
      payload: 'test:notification',
    );
  }

  /// Safely get the local timezone, initializing it if necessary
  tz.Location _getLocalTimeZone() {
    try {
      return tz.local;
    } catch (e) {
      // If tz.local fails, initialize timezone data and try again
      tz_data.initializeTimeZones();
      return tz.local;
    }
  }

  // Scheduled notifications
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
    );

    try {
      final localTZ = _getLocalTimeZone();
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, localTZ),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      // If scheduling fails, show immediate notification as fallback
      debugPrint('Failed to schedule notification: $e');
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    }
  }

  // Cancel notifications
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Request permissions (for both Android and iOS)
  Future<bool> requestPermissions() async {
    // Request iOS permissions
    final bool? iosGranted = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Request Android permissions (API 33+ for POST_NOTIFICATIONS)
    final bool? androidGranted = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Request exact alarm permission for Android (if needed)
    final bool? exactAlarmGranted = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();

    // Return true if permissions are granted on the current platform
    final bool iosResult = iosGranted ?? true; // Default to true for non-iOS
    final bool androidResult =
        androidGranted ?? true; // Default to true for non-Android
    final bool exactAlarmResult =
        exactAlarmGranted ?? true; // Default to true if not needed

    return iosResult && androidResult && exactAlarmResult;
  }

  // Check if permissions are granted
  Future<bool> arePermissionsGranted() async {
    // Check iOS permissions
    final NotificationsEnabledOptions? iosOptions =
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.checkPermissions();

    // Check Android permissions
    final bool? androidGranted = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();

    final bool iosResult =
        iosOptions?.isEnabled ?? true; // Default to true for non-iOS
    final bool androidResult =
        androidGranted ?? true; // Default to true for non-Android

    return iosResult && androidResult;
  }

  // Show permission dialog if needed
  Future<void> showPermissionDialogIfNeeded(BuildContext context) async {
    final bool hasPermission = await arePermissionsGranted();
    if (!hasPermission && context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'Notifications help you stay on track with your events, tasks, and reminders. '
            'Would you like to enable them?\n\n'
            'Note: If prompted to go to "Alarms & Reminders", this is normal. '
            'You can enable notifications there or try the test notification below.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not Now'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await requestPermissions();
                // Show test notification after requesting permissions
                await Future.delayed(const Duration(seconds: 1));
                await showTestNotification();
              },
              child: const Text('Enable & Test'),
            ),
          ],
        ),
      );
    }
  }

  /// Test notifications by showing an immediate test notification
  /// This helps verify that notifications are working properly
  Future<void> testNotifications(BuildContext context) async {
    final bool hasPermission = await arePermissionsGranted();
    if (!hasPermission) {
      // Show permission dialog first
      if (context.mounted) {
        await showPermissionDialogIfNeeded(context);
      }
    } else {
      // Show test notification directly
      await showTestNotification();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Test notification sent! Check your notification shade.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
