import 'package:flutter/foundation.dart';

@immutable
class ScheduleModel {
  final String id;
  final String userId;
  final String name;
  final int colorIndex;
  final DateTime createdAt;

  const ScheduleModel({
    required this.id,
    required this.userId,
    required this.name,
    this.colorIndex = 0,
    required this.createdAt,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> map, String id) {
    return ScheduleModel(
      id: id,
      userId: map['userId'] as String,
      name: map['name'] as String? ?? '',
      colorIndex: map['colorIndex'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'colorIndex': colorIndex,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  ScheduleModel copyWith({String? name, int? colorIndex}) => ScheduleModel(
        id: id,
        userId: userId,
        name: name ?? this.name,
        colorIndex: colorIndex ?? this.colorIndex,
        createdAt: createdAt,
      );
}
