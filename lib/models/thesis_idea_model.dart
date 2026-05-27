import 'package:flutter/foundation.dart';

@immutable
class ThesisIdeaModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String course;       // student's course when the idea was generated
  final List<String> keywords;
  final bool isSaved;
  final DateTime generatedAt;

  const ThesisIdeaModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.course,
    this.keywords = const [],
    this.isSaved = false,
    required this.generatedAt,
  });

  // ── Serialization ───────────────────────────────────────────────────────

  factory ThesisIdeaModel.fromMap(Map<String, dynamic> map, String id) {
    return ThesisIdeaModel(
      id: id,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      course: map['course'] as String? ?? '',
      keywords: List<String>.from(map['keywords'] as List<dynamic>? ?? []),
      isSaved: map['isSaved'] as bool? ?? false,
      generatedAt: DateTime.parse(map['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'description': description,
        'course': course,
        'keywords': keywords,
        'isSaved': isSaved,
        'generatedAt': generatedAt.toIso8601String(),
      };

  // ── copyWith ────────────────────────────────────────────────────────────

  ThesisIdeaModel copyWith({
    String? title,
    String? description,
    String? course,
    List<String>? keywords,
    bool? isSaved,
  }) =>
      ThesisIdeaModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        course: course ?? this.course,
        keywords: keywords ?? this.keywords,
        isSaved: isSaved ?? this.isSaved,
        generatedAt: generatedAt,
      );
}
