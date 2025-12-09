import 'package:cloud_firestore/cloud_firestore.dart';

enum Mood { veryHappy, happy, neutral, sad, verySad }

extension MoodExtension on Mood {
  String get displayName {
    switch (this) {
      case Mood.veryHappy:
        return 'Very Happy';
      case Mood.happy:
        return 'Happy';
      case Mood.neutral:
        return 'Neutral';
      case Mood.sad:
        return 'Sad';
      case Mood.verySad:
        return 'Very Sad';
    }
  }

  String get emoji {
    switch (this) {
      case Mood.veryHappy:
        return '😄';
      case Mood.happy:
        return '😊';
      case Mood.neutral:
        return '😐';
      case Mood.sad:
        return '😢';
      case Mood.verySad:
        return '😭';
    }
  }

  static Mood fromString(String moodString) {
    return Mood.values.firstWhere(
      (mood) => mood.toString() == moodString,
      orElse: () => Mood.neutral,
    );
  }
}

class JournalEntry {
  final String id;
  final String title;
  final String content;
  final Mood mood;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory JournalEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return JournalEntry(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      mood: MoodExtension.fromString(data['mood'] ?? 'Mood.neutral'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'mood': mood.toString(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Convert to Firestore document for updates (only updatedAt timestamp)
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'title': title,
      'content': content,
      'mood': mood.toString(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'mood': mood.toString(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create from JSON from local storage
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      mood: MoodExtension.fromString(json['mood'] ?? 'Mood.neutral'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
    );
  }

  // Create a copy with updated fields
  JournalEntry copyWith({
    String? id,
    String? title,
    String? content,
    Mood? mood,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'JournalEntry{id: $id, title: $title, mood: $mood, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntry &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.mood == mood &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, content, mood, createdAt, updatedAt);
  }
}
