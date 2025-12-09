import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 9)
enum NoteStatus {
  @HiveField(0)
  notStarted,
  @HiveField(1)
  active,
  @HiveField(2)
  done,
  @HiveField(3)
  urgent,
}

extension NoteStatusExtension on NoteStatus {
  String get displayName {
    switch (this) {
      case NoteStatus.notStarted:
        return 'Not Started';
      case NoteStatus.active:
        return 'Active';
      case NoteStatus.done:
        return 'Done';
      case NoteStatus.urgent:
        return 'Urgent';
    }
  }

  String get emoji {
    switch (this) {
      case NoteStatus.notStarted:
        return '🟡';
      case NoteStatus.active:
        return '🔵';
      case NoteStatus.done:
        return '🟢';
      case NoteStatus.urgent:
        return '🔴';
    }
  }
}

@HiveType(typeId: 2)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? category;

  @HiveField(5)
  List<String>? tags;

  @HiveField(6)
  bool isPinned;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  NoteStatus? _status;

  // Getter that provides a default value for existing data
  NoteStatus get status => _status ?? NoteStatus.notStarted;

  // Setter that updates the internal field
  set status(NoteStatus value) => _status = value;

  @HiveField(10)
  String? ratingId;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.category,
    this.tags,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
    NoteStatus? status,
    this.ratingId,
  }) : _status = status ?? NoteStatus.notStarted;

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    String? category,
    List<String>? tags,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    NoteStatus? status,
    String? ratingId,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      ratingId: ratingId ?? this.ratingId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'category': category,
      'tags': tags,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.index,
      'ratingId': ratingId,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isPinned: json['isPinned'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: json['status'] != null
          ? NoteStatus.values[json['status']]
          : NoteStatus.notStarted,
      ratingId: json['ratingId'],
    );
  }
}
