import 'package:hive/hive.dart';

part 'rating.g.dart';

@HiveType(typeId: 11)
enum RatingValue {
  @HiveField(0)
  veryPoor,
  @HiveField(1)
  poor,
  @HiveField(2)
  average,
  @HiveField(3)
  good,
  @HiveField(4)
  excellent,
}

extension RatingValueExtension on RatingValue {
  String get displayName {
    switch (this) {
      case RatingValue.veryPoor:
        return 'Very Poor';
      case RatingValue.poor:
        return 'Poor';
      case RatingValue.average:
        return 'Average';
      case RatingValue.good:
        return 'Good';
      case RatingValue.excellent:
        return 'Excellent';
    }
  }

  String get emoji {
    switch (this) {
      case RatingValue.veryPoor:
        return '😞';
      case RatingValue.poor:
        return '🙁';
      case RatingValue.average:
        return '😐';
      case RatingValue.good:
        return '🙂';
      case RatingValue.excellent:
        return '😊';
    }
  }

  int get numericValue {
    switch (this) {
      case RatingValue.veryPoor:
        return 1;
      case RatingValue.poor:
        return 2;
      case RatingValue.average:
        return 3;
      case RatingValue.good:
        return 4;
      case RatingValue.excellent:
        return 5;
    }
  }

  static RatingValue fromNumericValue(int value) {
    switch (value) {
      case 1:
        return RatingValue.veryPoor;
      case 2:
        return RatingValue.poor;
      case 3:
        return RatingValue.average;
      case 4:
        return RatingValue.good;
      case 5:
        return RatingValue.excellent;
      default:
        return RatingValue.average;
    }
  }
}

@HiveType(typeId: 12)
enum ItemType {
  @HiveField(0)
  event,
  @HiveField(1)
  task,
  @HiveField(2)
  appointment,
  @HiveField(3)
  note,
  @HiveField(4)
  transaction,
}

extension ItemTypeExtension on ItemType {
  String get displayName {
    switch (this) {
      case ItemType.event:
        return 'Event';
      case ItemType.task:
        return 'Task';
      case ItemType.appointment:
        return 'Appointment';
      case ItemType.note:
        return 'Note';
      case ItemType.transaction:
        return 'Transaction';
    }
  }

  String get pluralDisplayName {
    switch (this) {
      case ItemType.event:
        return 'Events';
      case ItemType.task:
        return 'Tasks';
      case ItemType.appointment:
        return 'Appointments';
      case ItemType.note:
        return 'Notes';
      case ItemType.transaction:
        return 'Transactions';
    }
  }
}

@HiveType(typeId: 6)
class Rating extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String itemId;

  @HiveField(2)
  ItemType itemType;

  @HiveField(3)
  RatingValue rating;

  @HiveField(4)
  String? comment;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime? updatedAt;

  Rating({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  Rating copyWith({
    String? id,
    String? itemId,
    ItemType? itemType,
    RatingValue? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Rating(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemType': itemType.name,
      'rating': rating.name,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'],
      itemId: json['itemId'],
      itemType: ItemType.values.firstWhere((e) => e.name == json['itemType']),
      rating: RatingValue.values.firstWhere((e) => e.name == json['rating']),
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Helper methods
  double get numericRating => rating.numericValue.toDouble();

  bool get hasComment => comment != null && comment!.isNotEmpty;

  String get formattedRating => '${rating.emoji} ${rating.displayName}';

  Duration get age => DateTime.now().difference(createdAt);

  String get timeAgo {
    final duration = age;
    if (duration.inDays > 365) {
      return '${(duration.inDays / 365).floor()} year${(duration.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (duration.inDays > 30) {
      return '${(duration.inDays / 30).floor()} month${(duration.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'} ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'} ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
