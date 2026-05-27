import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// semestral = UP 1.00–5.00 scale (raw % input, converted to equivalent)
// trimestral = NU 1.0–4.0 scale (grade point input)
enum GradingSystem { percentage, semestral, trimestral }

@immutable
class GradeModel {
  final String id;
  final String userId;
  final String subjectName;
  final String subjectCode;
  final double units;
  final double grade;        // raw user input
  final bool isIncomplete;   // semestral only: Incomplete → 4.00 equivalent
  final GradingSystem gradingSystem;
  final String semester;
  final String schoolYear;
  final DateTime createdAt;

  const GradeModel({
    required this.id,
    required this.userId,
    required this.subjectName,
    required this.subjectCode,
    required this.units,
    required this.grade,
    this.isIncomplete = false,
    required this.gradingSystem,
    required this.semester,
    required this.schoolYear,
    required this.createdAt,
  });

  String get term => '$semester $schoolYear';

  // ── Color palette ────────────────────────────────────────────────────────

  static const _green  = Color(0xFF4CAF50);
  static const _teal   = Color(0xFF009688);
  static const _blue   = Color(0xFF2196F3);
  static const _indigo = Color(0xFF3F51B5);
  static const _orange = Color(0xFFFF9800);
  static const _amber  = Color(0xFFFFC107);
  static const _red    = Color(0xFFEF5350);

  // ── Trimestral (NU): raw % → equivalent point ───────────────────────────

  static double getNUEquivalent(double rawPercentage) {
    if (rawPercentage >= 96) return 4.0;
    if (rawPercentage >= 90) return 3.5;
    if (rawPercentage >= 84) return 3.0;
    if (rawPercentage >= 78) return 2.5;
    if (rawPercentage >= 72) return 2.0;
    if (rawPercentage >= 66) return 1.5;
    if (rawPercentage >= 60) return 1.0;
    return 0.0;
  }

  // ── Semestral: raw % → equivalent point ─────────────────────────────────

  static double getSemestralEquivalent(double rawPercentage) {
    if (rawPercentage >= 95) return 1.00;
    if (rawPercentage >= 90) return 1.25;
    if (rawPercentage >= 85) return 1.50;
    if (rawPercentage >= 80) return 1.75;
    if (rawPercentage >= 75) return 2.00;
    if (rawPercentage >= 70) return 2.50;
    if (rawPercentage >= 65) return 3.00;
    return 5.00;
  }

  // ── Labels ───────────────────────────────────────────────────────────────

  static String getEquivalentLabel(
    double rawGrade,
    String gradingSystem, {
    bool isIncomplete = false,
  }) {
    switch (gradingSystem) {
      case 'semestral':
        if (isIncomplete) return 'Conditional';
        final eq = getSemestralEquivalent(rawGrade);
        if (eq <= 1.25) return 'Excellent';
        if (eq <= 1.75) return 'Very Good';
        if (eq <= 2.00) return 'Good';
        if (eq <= 2.50) return 'Satisfactory';
        if (eq <= 3.00) return 'Passing';
        return 'Failed';
      case 'trimestral':
        final eq = getNUEquivalent(rawGrade);
        if (eq >= 3.5) return 'Excellent';
        if (eq >= 3.0) return 'Superior';
        if (eq >= 2.5) return 'Very Good';
        if (eq >= 2.0) return 'Good';
        if (eq >= 1.5) return 'Satisfactory';
        if (eq >= 1.0) return 'Passing';
        return 'Failed';
      default: // percentage
        if (rawGrade >= 96) return 'Excellent';
        if (rawGrade >= 90) return 'Very Good';
        if (rawGrade >= 84) return 'Good';
        if (rawGrade >= 78) return 'Satisfactory';
        if (rawGrade >= 72) return 'Passing';
        if (rawGrade >= 60) return 'Barely Passing';
        return 'Failed';
    }
  }

  static String getGWALabel(double gwa, String gradingSystem) {
    switch (gradingSystem) {
      case 'semestral': // gwa is already in equivalent-point units
        if (gwa <= 1.25) return 'Excellent';
        if (gwa <= 1.75) return 'Very Good';
        if (gwa <= 2.25) return 'Good';
        if (gwa <= 2.75) return 'Satisfactory';
        if (gwa <= 3.50) return 'Passing';
        if (gwa <= 4.50) return 'Conditional';
        return 'Failed';
      case 'trimestral':
        if (gwa >= 3.5) return 'Excellent';
        if (gwa >= 3.0) return 'Superior';
        if (gwa >= 2.5) return 'Very Good';
        if (gwa >= 2.0) return 'Good';
        if (gwa >= 1.5) return 'Satisfactory';
        if (gwa >= 1.0) return 'Passing';
        return 'Failed';
      default: // percentage
        if (gwa >= 96) return 'Excellent';
        if (gwa >= 90) return 'Very Good';
        if (gwa >= 84) return 'Good';
        if (gwa >= 78) return 'Satisfactory';
        if (gwa >= 72) return 'Passing';
        if (gwa >= 60) return 'Barely Passing';
        return 'Failed';
    }
  }

  // ── Colors ───────────────────────────────────────────────────────────────

  // getGWAColor: for semestral, gwa is an equivalent point (1.00–5.00).
  // For percentage/trimestral, gwa is the raw value in those units.
  static Color getGWAColor(double gwa, String gradingSystem) {
    switch (gradingSystem) {
      case 'semestral':
        if (gwa <= 1.50) return _green;
        if (gwa <= 2.00) return _teal;
        if (gwa <= 2.50) return _blue;
        if (gwa <= 3.00) return _orange;
        if (gwa <= 4.00) return _amber;
        return _red;
      case 'trimestral':
        if (gwa >= 3.5) return _green;
        if (gwa >= 3.0) return _teal;
        if (gwa >= 2.5) return _blue;
        if (gwa >= 2.0) return _indigo;
        if (gwa >= 1.5) return _orange;
        if (gwa >= 1.0) return _amber;
        return _red;
      default: // percentage
        if (gwa >= 96) return _green;
        if (gwa >= 90) return _teal;
        if (gwa >= 84) return _blue;
        if (gwa >= 78) return _indigo;
        if (gwa >= 72) return _orange;
        if (gwa >= 60) return _amber;
        return _red;
    }
  }

  // getGradeColor: rawGrade is the user-entered value.
  // For semestral it gets converted to equivalent first.
  static Color getGradeColor(
    double rawGrade,
    String gradingSystem,
    BuildContext context, {
    bool isIncomplete = false,
  }) {
    if (gradingSystem == 'semestral') {
      if (isIncomplete) return _amber;
      return getGWAColor(getSemestralEquivalent(rawGrade), 'semestral');
    }
    if (gradingSystem == 'trimestral') {
      return getGWAColor(getNUEquivalent(rawGrade), 'trimestral');
    }
    return getGWAColor(rawGrade, gradingSystem);
  }

  // ── GWA computation ──────────────────────────────────────────────────────

  // For semestral: uses equivalent points (weighted).
  // For percentage/trimestral: uses raw grade values (weighted).
  static double? computeGWA(List<GradeModel> grades, String gradingSystem) {
    if (grades.isEmpty) return null;
    final totalUnits = grades.fold<double>(0, (s, g) => s + g.units);
    if (totalUnits == 0) return null;
    final weightedSum = grades.fold<double>(0, (s, g) {
      if (gradingSystem == 'semestral') {
        final eq = g.isIncomplete ? 4.0 : getSemestralEquivalent(g.grade);
        return s + eq * g.units;
      }
      if (gradingSystem == 'trimestral') {
        return s + getNUEquivalent(g.grade) * g.units;
      }
      return s + g.grade * g.units;
    });
    return weightedSum / totalUnits;
  }

  // ── Serialization ────────────────────────────────────────────────────────

  factory GradeModel.fromMap(Map<String, dynamic> map, String id) {
    return GradeModel(
      id: id,
      userId: map['userId'] as String,
      subjectName: map['subjectName'] as String,
      subjectCode: map['subjectCode'] as String? ?? '',
      units: (map['units'] as num).toDouble(),
      grade: (map['grade'] as num).toDouble(),
      isIncomplete: map['isIncomplete'] as bool? ?? false,
      gradingSystem: _parseGradingSystem(map['gradingSystem'] as String?),
      semester: map['semester'] as String,
      schoolYear: map['schoolYear'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  static GradingSystem _parseGradingSystem(String? s) {
    if (s == 'semestral' || s == 'filipino') return GradingSystem.semestral;
    if (s == 'trimestral') return GradingSystem.trimestral;
    return GradingSystem.percentage;
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'subjectName': subjectName,
        'subjectCode': subjectCode,
        'units': units,
        'grade': grade,
        'isIncomplete': isIncomplete,
        'gradingSystem': gradingSystem.name,
        'semester': semester,
        'schoolYear': schoolYear,
        'createdAt': createdAt.toIso8601String(),
      };

  // ── copyWith ─────────────────────────────────────────────────────────────

  GradeModel copyWith({
    String? subjectName,
    String? subjectCode,
    double? units,
    double? grade,
    bool? isIncomplete,
    GradingSystem? gradingSystem,
    String? semester,
    String? schoolYear,
  }) =>
      GradeModel(
        id: id,
        userId: userId,
        subjectName: subjectName ?? this.subjectName,
        subjectCode: subjectCode ?? this.subjectCode,
        units: units ?? this.units,
        grade: grade ?? this.grade,
        isIncomplete: isIncomplete ?? this.isIncomplete,
        gradingSystem: gradingSystem ?? this.gradingSystem,
        semester: semester ?? this.semester,
        schoolYear: schoolYear ?? this.schoolYear,
        createdAt: createdAt,
      );
}
