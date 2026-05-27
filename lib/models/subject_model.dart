import 'package:flutter/material.dart';

// weekA / weekB support rotating A/B schedules common in Filipino universities.
// Use [both] for subjects that meet every week regardless of rotation.
enum WeekType { weekA, weekB, both }

@immutable
class SubjectModel {
  final String id;
  final String userId;
  final String scheduleId; // links subject to a ScheduleModel; empty for legacy subjects
  final String name;
  final String code;       // e.g. "CS 401", "IT 101"
  final int color;         // stored as ARGB int; use [displayColor] to get Color
  final WeekType weekType;
  final int dayOfWeek;     // 1 = Monday … 7 = Sunday (matches DateTime.weekday)
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String room;

  const SubjectModel({
    required this.id,
    required this.userId,
    this.scheduleId = '',
    required this.name,
    required this.code,
    required this.color,
    this.weekType = WeekType.both,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room = '',
  });

  // ── Computed helpers ────────────────────────────────────────────────────

  Color get displayColor => Color(color);

  /// Duration of the class in minutes.
  int get durationMinutes {
    final startMins = startTime.hour * 60 + startTime.minute;
    final endMins = endTime.hour * 60 + endTime.minute;
    return endMins - startMins;
  }

  /// True if this subject runs on [day] under [currentWeek].
  bool isScheduledOn(int day, WeekType currentWeek) {
    if (dayOfWeek != day) return false;
    if (weekType == WeekType.both) return true;
    return weekType == currentWeek;
  }

  // ── Serialization ───────────────────────────────────────────────────────

  factory SubjectModel.fromMap(Map<String, dynamic> map, String id) {
    return SubjectModel(
      id: id,
      userId: map['userId'] as String,
      scheduleId: map['scheduleId'] as String? ?? '',
      name: map['name'] as String,
      code: map['code'] as String? ?? '',
      color: map['color'] as int,
      weekType: WeekType.values.firstWhere(
        (w) => w.name == (map['weekType'] as String? ?? 'both'),
        orElse: () => WeekType.both,
      ),
      dayOfWeek: map['dayOfWeek'] as int,
      startTime: TimeOfDay(
        hour: map['startHour'] as int,
        minute: map['startMinute'] as int,
      ),
      endTime: TimeOfDay(
        hour: map['endHour'] as int,
        minute: map['endMinute'] as int,
      ),
      room: map['room'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'scheduleId': scheduleId,
        'name': name,
        'code': code,
        'color': color,
        'weekType': weekType.name,
        'dayOfWeek': dayOfWeek,
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'endHour': endTime.hour,
        'endMinute': endTime.minute,
        'room': room,
      };

  // ── copyWith ────────────────────────────────────────────────────────────

  SubjectModel copyWith({
    String? scheduleId,
    String? name,
    String? code,
    int? color,
    WeekType? weekType,
    int? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? room,
  }) =>
      SubjectModel(
        id: id,
        userId: userId,
        scheduleId: scheduleId ?? this.scheduleId,
        name: name ?? this.name,
        code: code ?? this.code,
        color: color ?? this.color,
        weekType: weekType ?? this.weekType,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        room: room ?? this.room,
      );
}
