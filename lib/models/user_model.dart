import 'package:flutter/foundation.dart';
import 'package:studentology/models/grade_model.dart';

@immutable
class UserModel {
  final String id;         // == Firebase Auth uid (used as Firestore doc ID)
  final String name;
  final String email;
  final GradingSystem gradingSystem;
  final DateTime createdAt;

  // Optional profile fields used by ProfileScreen and ThesisScreen.
  // Not in the base spec but kept to avoid breaking existing screen scaffolds.
  final String course;
  final bool isDarkMode;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.gradingSystem = GradingSystem.percentage,
    required this.createdAt,
    this.course = '',
    this.isDarkMode = true,
  });

  // ── Serialization ───────────────────────────────────────────────────────

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      gradingSystem: _parseGradingSystem(
          map['gradingSystem'] as String?),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      course: map['course'] as String? ?? '',
      isDarkMode: map['isDarkMode'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'gradingSystem': gradingSystem.name,
        'createdAt': createdAt.toIso8601String(),
        'course': course,
        'isDarkMode': isDarkMode,
      };

  static GradingSystem _parseGradingSystem(String? s) {
    if (s == 'semestral' || s == 'filipino') return GradingSystem.semestral;
    if (s == 'trimestral') return GradingSystem.trimestral;
    return GradingSystem.percentage;
  }

  // ── copyWith ────────────────────────────────────────────────────────────

  UserModel copyWith({
    String? name,
    String? email,
    GradingSystem? gradingSystem,
    String? course,
    bool? isDarkMode,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        gradingSystem: gradingSystem ?? this.gradingSystem,
        createdAt: createdAt,
        course: course ?? this.course,
        isDarkMode: isDarkMode ?? this.isDarkMode,
      );
}
