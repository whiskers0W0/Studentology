import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:studentology/services/notification_service.dart';

class TimerProvider extends ChangeNotifier {
  // ── Configuration ────────────────────────────────────────────────────────

  int _focusMinutes = 25;
  int _breakMinutes = 5;

  int get focusMinutes => _focusMinutes;
  int get breakMinutes => _breakMinutes;

  // ── Runtime state ────────────────────────────────────────────────────────

  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  bool _isFocusMode = true;
  int _completedSessions = 0;
  // True when the UI should show the "take a long break" dialog.
  bool _pendingLongBreakPrompt = false;

  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  bool get isFocusMode => _isFocusMode;
  int get completedSessions => _completedSessions;
  bool get pendingLongBreakPrompt => _pendingLongBreakPrompt;

  Timer? _ticker;
  final _audioPlayer = AudioPlayer();

  // ── Derived getters ──────────────────────────────────────────────────────

  String get formattedTime {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// 0.0 (start) → 1.0 (complete). Drives the circular progress ring.
  double get progress {
    final total = _totalSeconds;
    if (total == 0) return 0;
    return 1 - (_secondsRemaining / total);
  }

  int get _totalSeconds =>
      (_isFocusMode ? _focusMinutes : _breakMinutes) * 60;

  // ── Timer control ────────────────────────────────────────────────────────

  void startTimer() {
    if (_isRunning) return;
    if (_secondsRemaining == 0) _secondsRemaining = _totalSeconds;
    _startCountdown();
    notifyListeners();
  }

  void pauseTimer() {
    if (!_isRunning) return;
    _ticker?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    _ticker?.cancel();
    _isRunning = false;
    _secondsRemaining = _totalSeconds;
    notifyListeners();
  }

  void switchMode() {
    _ticker?.cancel();
    _isRunning = false;
    _isFocusMode = !_isFocusMode;
    _secondsRemaining = _totalSeconds;
    notifyListeners();
  }

  /// Skips the current phase: increments session count if in focus, switches
  /// to the next phase, and auto-starts the countdown.
  void skipPhase() {
    _ticker?.cancel();
    _isRunning = false;

    if (_isFocusMode) {
      _completedSessions++;
      _isFocusMode = false;
    } else {
      _isFocusMode = true;
    }

    _secondsRemaining = _totalSeconds;
    _startCountdown();
    notifyListeners();
  }

  /// Called by the UI once it has consumed the long-break prompt.
  void clearLongBreakPrompt() {
    _pendingLongBreakPrompt = false;
    notifyListeners();
  }

  /// Resets the session counter to 0 (display wraps back to "Session 1 of 4").
  void resetSessions() {
    _completedSessions = 0;
    notifyListeners();
  }

  // ── Configuration setters ────────────────────────────────────────────────

  void setFocusDuration(int minutes) {
    assert(minutes > 0);
    _focusMinutes = minutes;
    if (_isFocusMode) {
      _ticker?.cancel();
      _isRunning = false;
      _secondsRemaining = _totalSeconds;
    }
    notifyListeners();
  }

  void setBreakDuration(int minutes) {
    assert(minutes > 0);
    _breakMinutes = minutes;
    if (!_isFocusMode) {
      _ticker?.cancel();
      _isRunning = false;
      _secondsRemaining = _totalSeconds;
    }
    notifyListeners();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  void _startCountdown() {
    _isRunning = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_secondsRemaining > 0) {
      _secondsRemaining--;
      notifyListeners();
    } else {
      _onComplete();
    }
  }

  void _onComplete() {
    _ticker?.cancel();
    _isRunning = false;

    if (_isFocusMode) {
      _completedSessions++;
      _isFocusMode = false;
      _secondsRemaining = _totalSeconds;
      _audioPlayer.play(UrlSource(
          'https://www.soundjay.com/buttons/sounds/button-09a.mp3'));
      NotificationService.show(1, '⏰ Focus Complete!',
          'Great work! Take a $_breakMinutes-minute break.');

      if (_completedSessions % 4 == 0) {
        // Pause and prompt the user for a long break.
        // The UI must call startTimer() after dismissing the dialog.
        _pendingLongBreakPrompt = true;
      } else {
        _startCountdown(); // auto-start break
      }
    } else {
      // Break finished → return to focus and auto-start.
      _isFocusMode = true;
      _secondsRemaining = _totalSeconds;
      _audioPlayer.play(UrlSource(
          'https://www.soundjay.com/buttons/sounds/button-10.mp3'));
      NotificationService.show(2, '☕ Break Over!',
          'Ready for Session ${_completedSessions + 1}? Let\'s focus!');
      _startCountdown();
    }

    notifyListeners();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _ticker?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
