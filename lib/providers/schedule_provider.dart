import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:studentology/models/schedule_model.dart';
import 'package:studentology/services/firestore_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final FirestoreService _db;

  StreamSubscription<List<ScheduleModel>>? _sub;
  String? _userId;

  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ScheduleModel> get schedules => List.unmodifiable(_schedules);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ScheduleProvider({FirestoreService? firestoreService})
      : _db = firestoreService ?? FirestoreService();

  void init(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    _sub?.cancel();
    _sub = _db.streamSchedules(userId).listen(
      (schedules) {
        _schedules = schedules;
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
    _schedules = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> addSchedule(String name, int colorIndex, String userId) async {
    try {
      await _db.addSchedule(userId, {
        'userId': userId,
        'name': name,
        'colorIndex': colorIndex,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      _errorMessage = _clean(e);
      notifyListeners();
    }
  }

  Future<void> updateSchedule(String scheduleId, String newName) async {
    try {
      _assertInit();
      await _db.updateSchedule(_userId!, scheduleId, {'name': newName});
    } catch (e) {
      _errorMessage = _clean(e);
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      _assertInit();
      final db = FirebaseFirestore.instance;
      final subjectsSnap = await db
          .collection('users')
          .doc(_userId!)
          .collection('subjects')
          .where('scheduleId', isEqualTo: scheduleId)
          .get();
      for (final doc in subjectsSnap.docs) {
        await doc.reference.delete();
      }
      await _db.deleteSchedule(_userId!, scheduleId);
    } catch (e) {
      _errorMessage = _clean(e);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _assertInit() {
    if (_userId == null) {
      throw StateError('ScheduleProvider not initialized — call init() first.');
    }
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
