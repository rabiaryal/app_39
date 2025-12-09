// import 'package:live_activities/live_activities.dart';
import '../../features/daily_activities/models/event.dart';
import '../../features/daily_activities/models/event_service.dart';

class LiveActivitiesService {
  // static final LiveActivities _liveActivities = LiveActivities();

  static Future<void> initialize() async {
    // Initialize live activities
    // await _liveActivities.init(appGroupId: 'group.com.app039.liveactivities');
  }

  static Future<String?> startLiveActivityForEvent(Event event) async {
    // try {
    //   final activityId = await _liveActivities.createActivity({
    //     'eventId': event.id,
    //     'title': event.title,
    //     'description': event.description,
    //     'startTime': event.startTime.toIso8601String(),
    //     'status': event.status.displayName,
    //     'emoji': event.status.emoji,
    //   });
    //   return activityId;
    // } catch (e) {
    //   print('Error starting live activity: $e');
    //   return null;
    // }
    return null;
  }

  static Future<void> updateLiveActivity(String activityId, Event event) async {
    // try {
    //   await _liveActivities.updateActivity(activityId, {
    //     'eventId': event.id,
    //     'title': event.title,
    //     'description': event.description,
    //     'startTime': event.startTime.toIso8601String(),
    //     'status': event.status.displayName,
    //     'emoji': event.status.emoji,
    //     'currentTime': DateTime.now().toIso8601String(),
    //   });
    // } catch (e) {
    //   print('Error updating live activity: $e');
    // }
  }

  static Future<void> endLiveActivity(String activityId) async {
    // try {
    //   await _liveActivities.endActivity(activityId);
    // } catch (e) {
    //   print('Error ending live activity: $e');
    // }
  }

  static Future<void> updateRunningEventsActivities() async {
    try {
      final allEvents = await EventService.getAllEvents();
      final runningEvents = allEvents
          .where(
            (event) =>
                event.status == EventStatus.ongoing &&
                event.actualStartTime != null,
          )
          .toList();

      // For each running event, ensure it has a live activity
      for (final event in runningEvents) {
        // You could store activity IDs in the event or maintain a separate mapping
        // For now, we'll create/update activities for running events
        final activityId = await startLiveActivityForEvent(event);
        if (activityId != null) {
          // Store the activity ID somewhere (could be added to Event model)
          print('Live activity started for event: ${event.title}');
        }
      }
    } catch (e) {
      print('Error updating running events activities: $e');
    }
  }

  static Future<void> dispose() async {
    // await _liveActivities.dispose();
  }
}
