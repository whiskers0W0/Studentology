import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:studentology/models/task_model.dart';
import 'package:studentology/services/firestore_service.dart';
import 'package:studentology/services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirestoreService _db;

  StreamSubscription<List<TaskModel>>? _sub;
  String? _userId;

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  TaskProvider({FirestoreService? firestoreService})
      : _db = firestoreService ?? FirestoreService();

  // ── Computed getters ────────────────────────────────────────────────────

  List<TaskModel> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();

  List<TaskModel> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();

  List<TaskModel> get overdueTasks =>
      _tasks.where((t) => t.isOverdue).toList();

  List<TaskModel> get todayTasks {
    final now = DateTime.now();
    return _tasks.where((t) {
      return !t.isCompleted &&
          t.dueDate.year == now.year &&
          t.dueDate.month == now.month &&
          t.dueDate.day == now.day;
    }).toList();
  }

  // ── Initialisation ──────────────────────────────────────────────────────

  void init(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    _sub?.cancel();
    _sub = _db.streamTasks(userId).listen(
      (tasks) {
        // Firestore already orders by dueDate ascending, but re-sort locally
        // to handle any propagation delays cleanly.
        _tasks = tasks..sort((a, b) => a.dueDate.compareTo(b.dueDate));
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
    _tasks = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ── CRUD ────────────────────────────────────────────────────────────────

  Future<void> addTask(TaskModel task) async {
    try {
      _assertInit();
      await _db.addTask(_userId!, task.toMap());
      final reminderTime = task.dueDate.subtract(const Duration(hours: 24));
      await NotificationService.schedule(
        task.hashCode,
        '📚 Task Due Tomorrow!',
        '${task.title} is due tomorrow. Don\'t forget!',
        reminderTime,
      );
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      _assertInit();
      await _db.updateTask(_userId!, task.id, task.toMap());
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      _assertInit();
      await _db.deleteTask(_userId!, taskId);
    } catch (e) {
      _setError(e);
    }
  }

  /// Flips the [isCompleted] flag of the task identified by [taskId].
  /// Finds the task locally to avoid an extra Firestore read.
  Future<void> toggleComplete(String taskId) async {
    try {
      _assertInit();
      final task = _tasks.firstWhere((t) => t.id == taskId);
      // Send only the changed field — keeps Firestore writes minimal.
      await _db.updateTask(
        _userId!,
        taskId,
        {'isCompleted': !task.isCompleted},
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
      throw StateError('TaskProvider not initialized — call init(userId) first.');
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
