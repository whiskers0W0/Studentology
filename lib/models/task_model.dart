import 'package:flutter/foundation.dart';

enum TaskPriority { low, medium, high }

@immutable
class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? subjectId;
  final String? subjectName;
  final DateTime dueDate;
  final bool isCompleted;
  final TaskPriority priority;
  final String? notes;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.subjectId,
    this.subjectName,
    required this.dueDate,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.notes,
    required this.createdAt,
  });

  // ── Computed getters ────────────────────────────────────────────────────

  /// True when the task is past its due date and still incomplete.
  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());

  /// True when the task is due today (regardless of completion status).
  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  // ── Serialization ───────────────────────────────────────────────────────

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      userId: map['userId'] as String,
      title: map['title'] as String,
      subjectId: map['subjectId'] as String?,
      subjectName: map['subjectName'] as String?,
      dueDate: DateTime.parse(map['dueDate'] as String),
      isCompleted: map['isCompleted'] as bool? ?? false,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == (map['priority'] as String? ?? 'medium'),
        orElse: () => TaskPriority.medium,
      ),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': isCompleted,
        'priority': priority.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  // ── copyWith ────────────────────────────────────────────────────────────

  TaskModel copyWith({
    String? title,
    String? subjectId,
    String? subjectName,
    DateTime? dueDate,
    bool? isCompleted,
    TaskPriority? priority,
    String? notes,
  }) =>
      TaskModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        subjectId: subjectId ?? this.subjectId,
        subjectName: subjectName ?? this.subjectName,
        dueDate: dueDate ?? this.dueDate,
        isCompleted: isCompleted ?? this.isCompleted,
        priority: priority ?? this.priority,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}
