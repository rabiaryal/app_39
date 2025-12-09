import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 8)
enum EventStatus {
  @HiveField(0)
  notStarted,
  @HiveField(1)
  ongoing,
  @HiveField(2)
  completed,
}

extension EventStatusExtension on EventStatus {
  String get displayName {
    switch (this) {
      case EventStatus.notStarted:
        return 'Not Started';
      case EventStatus.ongoing:
        return 'Ongoing';
      case EventStatus.completed:
        return 'Completed';
    }
  }

  String get emoji {
    switch (this) {
      case EventStatus.notStarted:
        return '🟡';
      case EventStatus.ongoing:
        return '🔵';
      case EventStatus.completed:
        return '🟢';
    }
  }
}

@HiveType(typeId: 0)
class Event extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  DateTime startTime;

  @HiveField(5)
  DateTime? endTime;

  @HiveField(6)
  String? category;

  @HiveField(7)
  bool isCompleted;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  EventStatus? _status;

  // Getter that provides a default value for existing data
  EventStatus get status => _status ?? EventStatus.notStarted;

  // Setter that updates the internal field
  set status(EventStatus value) => _status = value;

  @HiveField(11)
  Duration? pausedDuration;

  @HiveField(12)
  DateTime? pausedAt;

  @HiveField(13)
  DateTime? actualStartTime;

  @HiveField(14)
  DateTime? actualEndTime;

  @HiveField(15)
  final String? repeatType;

  @HiveField(16)
  final String? priority;

  @HiveField(17)
  String? ratingId;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.repeatType,
    required this.priority,
    this.category,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    EventStatus? status,
    this.pausedDuration,
    this.pausedAt,
    this.actualStartTime,
    this.actualEndTime,
    this.ratingId,
  }) : _status = status ?? EventStatus.notStarted;

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? category,
    String? repeatType,
    String? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    EventStatus? status,
    Duration? pausedDuration,
    DateTime? pausedAt,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    String? ratingId,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      pausedDuration: pausedDuration ?? this.pausedDuration,
      pausedAt: pausedAt ?? this.pausedAt,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      repeatType: repeatType ?? this.repeatType,
      priority: priority ?? this.priority,
      ratingId: ratingId ?? this.ratingId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'category': category,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.index,
      'pausedDuration': pausedDuration?.inMilliseconds,
      'pausedAt': pausedAt?.toIso8601String(),
      'actualStartTime': actualStartTime?.toIso8601String(),
      'actualEndTime': actualEndTime?.toIso8601String(),
      'repeatType': repeatType,
      'priority': priority,
      'ratingId': ratingId,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      category: json['category'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: json['status'] != null
          ? EventStatus.values[json['status']]
          : EventStatus.notStarted,
      pausedDuration: json['pausedDuration'] != null
          ? Duration(milliseconds: json['pausedDuration'])
          : null,
      pausedAt: json['pausedAt'] != null
          ? DateTime.parse(json['pausedAt'])
          : null,
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.parse(json['actualStartTime'])
          : null,
      actualEndTime: json['actualEndTime'] != null
          ? DateTime.parse(json['actualEndTime'])
          : null,

      repeatType: json['repeatType'],
      priority: json['priority'],
      ratingId: json['ratingId'],
    );
  }

  // Helper methods for timer functionality
  DateTime? get effectiveEndTime {
    if (endTime == null) return null;
    if (pausedDuration != null) {
      return endTime!.add(pausedDuration!);
    }
    return endTime;
  }

  Duration get totalPausedDuration {
    Duration total = pausedDuration ?? Duration.zero;
    if (status == EventStatus.ongoing && pausedAt != null) {
      total = total + DateTime.now().difference(pausedAt!);
    }
    return total;
  }

  Duration? get remainingTime {
    if (endTime == null) return null; // Instant events have no duration
    if (status == EventStatus.completed) return Duration.zero;
    if (status == EventStatus.notStarted) {
      return effectiveEndTime!.difference(startTime);
    }

    final now = DateTime.now();
    final adjustedEndTime = endTime!.add(totalPausedDuration);

    if (now.isAfter(adjustedEndTime)) return Duration.zero;
    return adjustedEndTime.difference(now);
  }

  bool get shouldAutoStart {
    // Disabled auto-start behavior - events must be manually started
    return false;
  }

  bool get shouldAutoComplete {
    if (effectiveEndTime == null)
      return false; // Instant events don't auto-complete
    final now = DateTime.now();
    return status == EventStatus.ongoing && now.isAfter(effectiveEndTime!);
  }

  bool get shouldMarkAsMissed {
    if (effectiveEndTime == null)
      return false; // Instant events don't get marked as missed
    final now = DateTime.now();
    // Mark as completed if:
    // 1. Event time has passed (current time is after end time)
    // 2. Event was not completed (status is not 'completed')
    return now.isAfter(effectiveEndTime!) && status != EventStatus.completed;
  }

  /// Gets the appropriate status based on current time and event status
  EventStatus getAutoUpdatedStatus() {
    final now = DateTime.now();

    // If already completed, keep the status
    if (status == EventStatus.completed) {
      return status;
    }

    // For instant events (no end time), complete if start time has passed
    if (effectiveEndTime == null) {
      if (now.isAfter(startTime.add(const Duration(hours: 1)))) {
        return EventStatus.completed;
      }
      return status;
    }

    // For events with end time:
    // 1. Complete if the end time has passed
    if (now.isAfter(effectiveEndTime!)) {
      return EventStatus.completed;
    }

    // 2. Mark as ongoing if current time is between start and end times
    if (now.isAfter(startTime) && now.isBefore(effectiveEndTime!)) {
      return EventStatus.ongoing;
    }

    // Keep as not started if none of the above conditions are met
    return status;
  }

  /// Determines if the event can be edited based on time proximity to start/end times
  /// Events cannot be edited if:
  /// - They are completed
  /// - They are ongoing (already started)
  /// - They start within 1 hour from now
  bool get canEdit {
    final now = DateTime.now();

    // Cannot edit completed events
    if (status == EventStatus.completed) {
      return false;
    }

    // Cannot edit ongoing events
    if (status == EventStatus.ongoing) {
      return false;
    }

    // Cannot edit events that start within 1 hour
    final timeUntilStart = startTime.difference(now);
    if (timeUntilStart.inHours < 1 && timeUntilStart.isNegative == false) {
      return false;
    }

    // Cannot edit events that have already started
    if (now.isAfter(startTime)) {
      return false;
    }

    return true;
  }
}
