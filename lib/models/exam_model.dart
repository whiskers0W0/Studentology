import 'package:flutter/material.dart';

@immutable
class ExamModel {
  final String id;
  final String userId;
  final String? subjectId;
  final String subjectName;
  final String title;
  final DateTime examDate;   // date-only; time comes from [startTime]
  final TimeOfDay startTime;
  final String room;
  final String seatNumber;
  final String? notes;
  final double? score;       // actual score after the exam
  final double? totalScore;  // maximum possible score
  final DateTime createdAt;

  const ExamModel({
    required this.id,
    required this.userId,
    this.subjectId,
    required this.subjectName,
    required this.title,
    required this.examDate,
    required this.startTime,
    this.room = '',
    this.seatNumber = '',
    this.notes,
    this.score,
    this.totalScore,
    required this.createdAt,
  });

  // ── Computed getters ────────────────────────────────────────────────────

  /// Combined DateTime of the exam day + start time for sorting / display.
  DateTime get scheduledAt => DateTime(
        examDate.year,
        examDate.month,
        examDate.day,
        startTime.hour,
        startTime.minute,
      );

  bool get isPast => scheduledAt.isBefore(DateTime.now());

  bool get hasScore => score != null && totalScore != null;

  /// Score expressed as a percentage (0–100), or null if not yet recorded.
  double? get percentage =>
      hasScore ? (score! / totalScore!) * 100 : null;

  /// Days until the exam from now. Negative when the exam has passed.
  int get daysUntil => examDate
      .difference(DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ))
      .inDays;

  // ── Serialization ───────────────────────────────────────────────────────

  factory ExamModel.fromMap(Map<String, dynamic> map, String id) {
    return ExamModel(
      id: id,
      userId: map['userId'] as String,
      subjectId: map['subjectId'] as String?,
      subjectName: map['subjectName'] as String? ?? '',
      title: map['title'] as String,
      examDate: DateTime.parse(map['examDate'] as String),
      startTime: TimeOfDay(
        hour: map['startHour'] as int,
        minute: map['startMinute'] as int,
      ),
      room: map['room'] as String? ?? '',
      seatNumber: map['seatNumber'] as String? ?? '',
      notes: map['notes'] as String?,
      score: (map['score'] as num?)?.toDouble(),
      totalScore: (map['totalScore'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'title': title,
        // Store date without time component; time is in startHour/startMinute
        'examDate': DateTime(examDate.year, examDate.month, examDate.day)
            .toIso8601String(),
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'room': room,
        'seatNumber': seatNumber,
        'notes': notes,
        'score': score,
        'totalScore': totalScore,
        'createdAt': createdAt.toIso8601String(),
      };

  // ── copyWith ────────────────────────────────────────────────────────────

  ExamModel copyWith({
    String? subjectId,
    String? subjectName,
    String? title,
    DateTime? examDate,
    TimeOfDay? startTime,
    String? room,
    String? seatNumber,
    String? notes,
    // Use a sentinel to allow explicitly clearing score/totalScore back to null
    double? score,
    double? totalScore,
    bool clearScore = false,
  }) =>
      ExamModel(
        id: id,
        userId: userId,
        subjectId: subjectId ?? this.subjectId,
        subjectName: subjectName ?? this.subjectName,
        title: title ?? this.title,
        examDate: examDate ?? this.examDate,
        startTime: startTime ?? this.startTime,
        room: room ?? this.room,
        seatNumber: seatNumber ?? this.seatNumber,
        notes: notes ?? this.notes,
        score: clearScore ? null : (score ?? this.score),
        totalScore: clearScore ? null : (totalScore ?? this.totalScore),
        createdAt: createdAt,
      );
}
