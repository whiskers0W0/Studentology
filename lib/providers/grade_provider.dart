import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:studentology/models/grade_model.dart';
import 'package:studentology/services/firestore_service.dart';

class GradeProvider extends ChangeNotifier {
  final FirestoreService _db;

  StreamSubscription<List<GradeModel>>? _sub;
  String? _userId;

  List<GradeModel> _grades = [];
  bool _isLoading = false;
  String? _errorMessage;

  // The grading system currently active in the UI. Defaults to 'percentage'
  // until the user's profile is loaded and sets it via setGradingSystem().
  String _gradingSystem = GradingSystem.percentage.name;

  // Selected term for grade display (e.g. "1st 2025-2026").
  String _selectedTerm = '';

  GradeProvider({FirestoreService? firestoreService})
      : _db = firestoreService ?? FirestoreService();

  // ── Getters ─────────────────────────────────────────────────────────────

  List<GradeModel> get grades => List.unmodifiable(_grades);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get gradingSystem => _gradingSystem;
  String get selectedTerm => _selectedTerm;

  /// Sorted unique list of term labels. "All" is always prepended.
  List<String> get availableTerms {
    final terms = _grades.map((g) => g.term).toSet().toList()..sort();
    return ['All', ...terms];
  }

  /// Returns all grades when "All" is selected, otherwise filters by [_selectedTerm].
  List<GradeModel> get gradesForSelectedTerm {
    if (_selectedTerm.isEmpty || _selectedTerm == 'All') {
      return List.unmodifiable(_grades);
    }
    return _grades.where((g) => g.term == _selectedTerm).toList();
  }

  /// Weighted GWA computed by [GradeModel.computeGWA] for the selected term.
  /// Returns null when there are no grades for the selection.
  double? get computedGWA =>
      GradeModel.computeGWA(gradesForSelectedTerm, _gradingSystem);

  // ── Initialisation ──────────────────────────────────────────────────────

  void init(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    _sub?.cancel();
    _sub = _db.streamGrades(userId).listen(
      (grades) {
        _grades = grades;
        // Default to "All" on first load.
        if (_selectedTerm.isEmpty) {
          _selectedTerm = 'All';
        }
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
    _grades = [];
    _isLoading = false;
    _errorMessage = null;
    _selectedTerm = '';
    notifyListeners();
  }

  // ── State setters ────────────────────────────────────────────────────────

  /// Updates the active grading system ('percentage', 'semestral', or 'trimestral').
  void setGradingSystem(String system) {
    if (_gradingSystem == system) return;
    _gradingSystem = system;
    notifyListeners();
  }

  void selectTerm(String term) {
    if (_selectedTerm == term) return;
    _selectedTerm = term;
    notifyListeners();
  }

  // ── CRUD ────────────────────────────────────────────────────────────────

  Future<void> addGrade(GradeModel grade) async {
    try {
      _assertInit();
      await _db.addGrade(_userId!, grade.toMap());
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> updateGrade(GradeModel grade) async {
    try {
      _assertInit();
      await _db.updateDocument('grades', _userId!, grade.id, grade.toMap());
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> deleteGrade(String gradeId) async {
    try {
      _assertInit();
      await _db.deleteGrade(_userId!, gradeId);
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
      throw StateError('GradeProvider not initialized — call init(userId) first.');
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
