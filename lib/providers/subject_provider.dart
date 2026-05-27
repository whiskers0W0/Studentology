import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:studentology/models/subject_model.dart';
import 'package:studentology/services/firestore_service.dart';

class SubjectProvider extends ChangeNotifier {
  final FirestoreService _db;

  StreamSubscription<List<SubjectModel>>? _sub;
  String? _userId;

  List<SubjectModel> _subjects = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SubjectModel> get subjects => List.unmodifiable(_subjects);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SubjectProvider({FirestoreService? firestoreService})
      : _db = firestoreService ?? FirestoreService();

  // ── Initialisation ──────────────────────────────────────────────────────

  /// Starts streaming subjects for [userId]. Safe to call multiple times — will
  /// cancel the previous subscription first and skip if userId hasn't changed.
  void init(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    _sub?.cancel();
    _sub = _db.streamSubjects(userId).listen(
      (subjects) {
        final seen = <String>{};
        _subjects = subjects.where((s) => seen.add(s.id)).toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = _clean(e);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Clears all state and cancels the stream (call on sign-out).
  void reset() {
    _sub?.cancel();
    _sub = null;
    _userId = null;
    _subjects = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Computed filters ────────────────────────────────────────────────────

  /// Returns subjects scheduled on [day] (1=Mon … 7=Sun) under [currentWeek],
  /// sorted by start time ascending.
  List<SubjectModel> getSubjectsForDay(int day, WeekType currentWeek) {
    return _subjects
        .where((s) => s.isScheduledOn(day, currentWeek))
        .toList()
      ..sort((a, b) {
          final aMin = a.startTime.hour * 60 + a.startTime.minute;
          final bMin = b.startTime.hour * 60 + b.startTime.minute;
          return aMin.compareTo(bMin);
        });
  }

  /// Returns subjects that belong to [scheduleId], sorted by day then start time.
  List<SubjectModel> getSubjectsForSchedule(String scheduleId) {
    return _subjects
        .where((s) => s.scheduleId == scheduleId)
        .toList()
      ..sort((a, b) {
          if (a.dayOfWeek != b.dayOfWeek) {
            return a.dayOfWeek.compareTo(b.dayOfWeek);
          }
          final aMin = a.startTime.hour * 60 + a.startTime.minute;
          final bMin = b.startTime.hour * 60 + b.startTime.minute;
          return aMin.compareTo(bMin);
        });
  }

  /// Deletes all subjects belonging to [scheduleId].
  Future<void> deleteSubjectsForSchedule(String scheduleId) async {
    try {
      _assertInit();
      final toDelete = _subjects
          .where((s) => s.scheduleId == scheduleId)
          .map((s) => s.id)
          .toList();
      for (final id in toDelete) {
        await _db.deleteSubject(_userId!, id);
      }
    } catch (e) {
      _setError(e);
    }
  }

  /// Returns all subjects that appear in [weekType]
  /// (includes [WeekType.both] subjects in every week).
  List<SubjectModel> getSubjectsForWeek(String weekType) {
    final type = WeekType.values.firstWhere(
      (w) => w.name == weekType,
      orElse: () => WeekType.both,
    );
    return _subjects
        .where((s) => s.weekType == WeekType.both || s.weekType == type)
        .toList();
  }

  // ── CRUD ────────────────────────────────────────────────────────────────

  Future<void> addSubject(SubjectModel subject) async {
    try {
      _assertInit();
      await _db.addSubject(_userId!, subject.toMap());
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> updateSubject(SubjectModel subject) async {
    try {
      _assertInit();
      await _db.updateSubject(_userId!, subject.id, subject.toMap());
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      _assertInit();
      await _db.deleteSubject(_userId!, subjectId);

      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(_userId!);

      final taskSnap = await userRef
          .collection('tasks')
          .where('subjectId', isEqualTo: subjectId)
          .get();
      for (final doc in taskSnap.docs) {
        await doc.reference.update({
          'subjectId': FieldValue.delete(),
          'subjectName': FieldValue.delete(),
        });
      }

      final examSnap = await userRef
          .collection('exams')
          .where('subjectId', isEqualTo: subjectId)
          .get();
      for (final doc in examSnap.docs) {
        await doc.reference.update({
          'subjectId': FieldValue.delete(),
          'subjectName': FieldValue.delete(),
        });
      }
    } catch (e) {
      _setError(e);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  void _assertInit() {
    if (_userId == null) {
      throw StateError('SubjectProvider not initialized — call init(userId) first.');
    }
  }

  void _setError(Object e) {
    _errorMessage = _clean(e);
    notifyListeners();
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
