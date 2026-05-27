import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:studentology/models/exam_model.dart';
import 'package:studentology/services/firestore_service.dart';
import 'package:studentology/services/notification_service.dart';

class ExamProvider extends ChangeNotifier {
  final FirestoreService _db;

  StreamSubscription<List<ExamModel>>? _sub;
  String? _userId;

  List<ExamModel> _exams = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ExamModel> get exams => List.unmodifiable(_exams);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ExamProvider({FirestoreService? firestoreService})
      : _db = firestoreService ?? FirestoreService();

  // ── Computed getters ────────────────────────────────────────────────────

  List<ExamModel> get upcomingExams =>
      _exams.where((e) => !e.isPast).toList();

  List<ExamModel> get pastExams =>
      _exams.where((e) => e.isPast).toList();

  /// Exams within the next 7 days — used by the home dashboard.
  List<ExamModel> get nearingExams {
    final cutoff = DateTime.now().add(const Duration(days: 7));
    return upcomingExams
        .where((e) => e.examDate.isBefore(cutoff))
        .toList();
  }

  // ── Initialisation ──────────────────────────────────────────────────────

  void init(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    _sub?.cancel();
    _sub = _db.streamExams(userId).listen(
      (exams) {
        // Firestore orders by examDate ascending; keep local list in sync.
        _exams = exams..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
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

  void reset() {
    _sub?.cancel();
    _sub = null;
    _userId = null;
    _exams = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ── CRUD ────────────────────────────────────────────────────────────────

  Future<void> addExam(ExamModel exam) async {
    try {
      _assertInit();
      await _db.addExam(_userId!, exam.toMap());
      final reminderTime = exam.examDate.subtract(const Duration(days: 1));
      await NotificationService.schedule(
        exam.hashCode,
        '📝 Exam Tomorrow!',
        '${exam.title} — ${exam.subjectName} is tomorrow. Study hard!',
        reminderTime,
      );
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> updateExam(ExamModel exam) async {
    try {
      _assertInit();
      await _db.updateExam(_userId!, exam.id, exam.toMap());
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> deleteExam(String examId) async {
    try {
      _assertInit();
      await _db.deleteExam(_userId!, examId);
    } catch (e) {
      _setError(e);
    }
  }

  /// Records [score] out of [total] for the exam identified by [examId].
  /// Sends only the two changed fields to Firestore.
  Future<void> addScore(String examId, double score, double total) async {
    try {
      _assertInit();
      await _db.updateExam(
        _userId!,
        examId,
        {'score': score, 'totalScore': total},
      );
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
      throw StateError('ExamProvider not initialized — call init(userId) first.');
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
