import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../../features/daily_activities/models/event.dart';
import '../../features/notes/models/note.dart';

class AwesomeNotificationService {
  static final AwesomeNotificationService _instance =
      AwesomeNotificationService._internal();
  factory AwesomeNotificationService() => _instance;
  AwesomeNotificationService._internal();

  // Notification channels
  static const String _eventsChannelKey = 'events_channel';
  static const String _appointmentsChannelKey = 'appointments_channel';
  static const String _notesChannelKey = 'notes_channel';
  static const String _financeChannelKey = 'finance_channel';
  static const String _remindersChannelKey = 'reminders_channel';

  // Notification groups
  static const String _eventsGroupKey = 'events_group';
  static const String _appointmentsGroupKey = 'appointments_group';
  static const String _notesGroupKey = 'notes_group';
  static const String _financeGroupKey = 'finance_group';

  /// Initialize the awesome notifications service
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_launcher',
      [
        // Events Channel
        NotificationChannel(
          channelKey: _eventsChannelKey,
          channelName: 'Events',
          channelDescription: 'Notifications for event reminders and updates',
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
          vibrationPattern: lowVibrationPattern,
          groupKey: _eventsGroupKey,
        ),

        // Appointments Channel
        NotificationChannel(
          channelKey: _appointmentsChannelKey,
          channelName: 'Appointments',
          channelDescription: 'Notifications for appointment reminders',
          defaultColor: Colors.green,
          ledColor: Colors.green,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
          vibrationPattern: mediumVibrationPattern,
          groupKey: _appointmentsGroupKey,
        ),

        // Notes Channel
        NotificationChannel(
          channelKey: _notesChannelKey,
          channelName: 'Notes',
          channelDescription: 'Notifications for note reminders',
          defaultColor: Colors.orange,
          ledColor: Colors.orange,
          importance: NotificationImportance.Default,
          channelShowBadge: true,
          playSound: false,
          enableVibration: false,
          groupKey: _notesGroupKey,
        ),

        // Finance Channel
        NotificationChannel(
          channelKey: _financeChannelKey,
          channelName: 'Finance',
          channelDescription: 'Notifications for financial reminders',
          defaultColor: Colors.purple,
          ledColor: Colors.purple,
          importance: NotificationImportance.Default,
          channelShowBadge: true,
          playSound: false,
          enableVibration: false,
          groupKey: _financeGroupKey,
        ),

        // Reminders Channel
        NotificationChannel(
          channelKey: _remindersChannelKey,
          channelName: 'Reminders',
          channelDescription: 'General reminders and notifications',
          defaultColor: Colors.red,
          ledColor: Colors.red,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
          vibrationPattern: highVibrationPattern,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: _eventsGroupKey,
          channelGroupName: 'Events',
        ),
        NotificationChannelGroup(
          channelGroupKey: _appointmentsGroupKey,
          channelGroupName: 'Appointments',
        ),
        NotificationChannelGroup(
          channelGroupKey: _notesGroupKey,
          channelGroupName: 'Notes',
        ),
        NotificationChannelGroup(
          channelGroupKey: _financeGroupKey,
          channelGroupName: 'Finance',
        ),
      ],
    );

    // Request permissions
    await requestPermissions();

    // Set up listeners
    _setupListeners();
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    final result = await AwesomeNotifications()
        .requestPermissionToSendNotifications(
          channelKey: _eventsChannelKey,
          permissions: [
            NotificationPermission.Alert,
            NotificationPermission.Sound,
            NotificationPermission.Badge,
            NotificationPermission.Vibration,
            NotificationPermission.Light,
            NotificationPermission.FullScreenIntent,
          ],
        );
    return result;
  }

  /// Check if notifications are allowed
  Future<bool> isNotificationsAllowed() async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    return allowed;
  }

  /// Set up notification listeners
  void _setupListeners() {
    // Listen for notification actions
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );
  }

  /// Handle notification action received
  @pragma('vm:entry-point')
  static Future<void> _onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    final payload = receivedAction.payload ?? {};

    switch (receivedAction.buttonKeyPressed) {
      case 'VIEW_EVENT':
        // Navigate to event details
        _handleEventAction(payload);
        break;
      case 'MARK_COMPLETE':
        // Mark event as complete
        _handleMarkComplete(payload);
        break;
      case 'SNOOZE':
        // Snooze notification
        _handleSnooze(payload);
        break;
      case 'VIEW_APPOINTMENT':
        // Navigate to appointment
        _handleAppointmentAction(payload);
        break;
      default:
        // Handle general notification tap
        _handleNotificationTap(payload);
        break;
    }
  }

  /// Handle notification created
  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Log notification creation for analytics
    print('Notification created: ${receivedNotification.title}');
  }

  /// Handle notification displayed
  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Log notification display for analytics
    print('Notification displayed: ${receivedNotification.title}');
  }

  /// Handle notification dismissed
  @pragma('vm:entry-point')
  static Future<void> _onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    // Log notification dismissal
    print('Notification dismissed: ${receivedAction.title}');
  }

  // ===== EVENT NOTIFICATIONS =====

  /// Schedule event reminder notification
  Future<void> scheduleEventReminder(
    Event event, {
    Duration? reminderTime,
  }) async {
    final reminder = reminderTime ?? const Duration(minutes: 15);
    final scheduledTime = event.startTime.subtract(reminder);

    if (scheduledTime.isBefore(DateTime.now())) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: event.id.hashCode + 1000,
        channelKey: _eventsChannelKey,
        title: '📅 Event Reminder',
        body: '"${event.title}" starts in ${reminder.inMinutes} minutes',
        notificationLayout: NotificationLayout.Default,
        payload: {
          'type': 'event_reminder',
          'eventId': event.id,
          'action': 'view_event',
        },
        color: Colors.blue,
        backgroundColor: Colors.blue.withOpacity(0.1),
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'VIEW_EVENT',
          label: 'View Event',
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'SNOOZE',
          label: 'Snooze 10min',
          actionType: ActionType.SilentAction,
        ),
      ],
      schedule: NotificationCalendar.fromDate(date: scheduledTime),
    );
  }

  /// Schedule event start notification
  Future<void> scheduleEventStartNotification(Event event) async {
    if (event.startTime.isBefore(DateTime.now())) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: event.id.hashCode + 2000,
        channelKey: _eventsChannelKey,
        title: '🚀 Event Starting Now!',
        body: '"${event.title}" is starting right now',
        notificationLayout: NotificationLayout.BigText,
        payload: {
          'type': 'event_start',
          'eventId': event.id,
          'action': 'view_event',
        },
        color: Colors.green,
        backgroundColor: Colors.green.withOpacity(0.1),
        category: NotificationCategory.Event,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'VIEW_EVENT',
          label: 'Start Event',
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'MARK_COMPLETE',
          label: 'Mark Complete',
          actionType: ActionType.SilentAction,
        ),
      ],
      schedule: NotificationCalendar.fromDate(date: event.startTime),
    );
  }

  /// Show in-app notification for event status change
  Future<void> showEventStatusChangeNotification(
    Event event,
    String oldStatus,
    String newStatus,
  ) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: event.id.hashCode + 3000,
        channelKey: _eventsChannelKey,
        title: '📊 Event Status Updated',
        body: '"${event.title}" changed from $oldStatus to $newStatus',
        notificationLayout: NotificationLayout.Default,
        payload: {
          'type': 'event_status_change',
          'eventId': event.id,
          'action': 'view_event',
        },
        color: Colors.orange,
        backgroundColor: Colors.orange.withOpacity(0.1),
        displayOnForeground: true, // Show even when app is open
        displayOnBackground: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'VIEW_EVENT',
          label: 'View Details',
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  // ===== NOTE NOTIFICATIONS =====

  /// Schedule note reminder
  Future<void> scheduleNoteReminder(Note note, DateTime reminderTime) async {
    if (reminderTime.isBefore(DateTime.now())) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: note.id.hashCode + 5000,
        channelKey: _notesChannelKey,
        title: '📝 Note Reminder',
        body: note.title,
        notificationLayout: NotificationLayout.BigText,
        payload: {
          'type': 'note_reminder',
          'noteId': note.id,
          'action': 'view_note',
        },
        color: Colors.orange,
        backgroundColor: Colors.orange.withOpacity(0.1),
      ),
      schedule: NotificationCalendar.fromDate(date: reminderTime),
    );
  }

  // ===== FINANCE NOTIFICATIONS =====

  /// Schedule financial reminder
  Future<void> scheduleFinancialReminder(
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 6000,
        channelKey: _financeChannelKey,
        title: '💰 $title',
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: {'type': 'finance_reminder', 'action': 'view_finance'},
        color: Colors.purple,
        backgroundColor: Colors.purple.withOpacity(0.1),
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledTime),
    );
  }

  // ===== GENERAL NOTIFICATIONS =====

  /// Show success notification (in-app)
  Future<void> showSuccessNotification(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 7000,
        channelKey: _remindersChannelKey,
        title: '✅ $title',
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: Colors.green,
        backgroundColor: Colors.green.withOpacity(0.1),
        displayOnForeground: true,
        displayOnBackground: false, // Only show in-app
      ),
    );
  }

  /// Show error notification (in-app)
  Future<void> showErrorNotification(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 8000,
        channelKey: _remindersChannelKey,
        title: '❌ $title',
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: Colors.red,
        backgroundColor: Colors.red.withOpacity(0.1),
        displayOnForeground: true,
        displayOnBackground: false,
      ),
    );
  }

  /// Show warning notification (in-app)
  Future<void> showWarningNotification(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 9000,
        channelKey: _remindersChannelKey,
        title: '⚠️ $title',
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: Colors.orange,
        backgroundColor: Colors.orange.withOpacity(0.1),
        displayOnForeground: true,
        displayOnBackground: false,
      ),
    );
  }

  /// Show info notification (in-app)
  Future<void> showInfoNotification(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 10000,
        channelKey: _remindersChannelKey,
        title: 'ℹ️ $title',
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: Colors.blue,
        backgroundColor: Colors.blue.withOpacity(0.1),
        displayOnForeground: true,
        displayOnBackground: false,
      ),
    );
  }

  /// Show progress notification
  Future<void> showProgressNotification(
    String title,
    String body,
    int progress,
  ) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 11000,
        channelKey: _remindersChannelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.ProgressBar,
        progress: progress.toDouble(),
        color: Colors.blue,
        backgroundColor: Colors.blue.withOpacity(0.1),
        displayOnForeground: true,
        displayOnBackground: false,
      ),
    );
  }

  // ===== UTILITY METHODS =====

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  /// Cancel notifications by channel
  Future<void> cancelNotificationsByChannel(String channelKey) async {
    await AwesomeNotifications().cancelNotificationsByChannelKey(channelKey);
  }

  /// Get notification permissions status
  Future<bool> checkPermissionStatus() async {
    final status = await AwesomeNotifications().checkPermissionList();
    return status.contains(NotificationPermission.Alert);
  }

  // ===== ACTION HANDLERS =====

  static void _handleEventAction(Map<String, String?> payload) {
    final eventId = payload['eventId'];
    if (eventId != null) {
      // Navigate to event details - this would be handled by your navigation system
      print('Navigate to event: $eventId');
    }
  }

  static void _handleMarkComplete(Map<String, String?> payload) {
    final eventId = payload['eventId'];
    if (eventId != null) {
      // Mark event as complete - this would update your data
      print('Mark event complete: $eventId');
    }
  }

  static void _handleSnooze(Map<String, String?> payload) {
    final eventId = payload['eventId'];
    if (eventId != null) {
      // Snooze notification for 10 minutes
      print('Snooze notification for event: $eventId');
    }
  }

  static void _handleAppointmentAction(Map<String, String?> payload) {
    final appointmentId = payload['appointmentId'];
    if (appointmentId != null) {
      // Navigate to appointment details
      print('Navigate to appointment: $appointmentId');
    }
  }

  static void _handleNotificationTap(Map<String, String?> payload) {
    final type = payload['type'];
    final action = payload['action'];

    switch (type) {
      case 'event_reminder':
      case 'event_start':
      case 'event_status_change':
        _handleEventAction(payload);
        break;
      case 'appointment_reminder':
        _handleAppointmentAction(payload);
        break;
      default:
        print('Unhandled notification tap: $type, action: $action');
        break;
    }
  }
}
