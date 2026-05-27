import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'isDarkMode';

  bool _isDarkMode = false; // default light until SharedPreferences loads

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    loadTheme();
  }

  // ── Public methods ──────────────────────────────────────────────────────

  /// Reads the persisted theme preference on startup.
  /// Called automatically in the constructor; safe to call again to re-sync.
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefKey);
    // Only update if the stored value differs from the current value to avoid
    // a redundant notifyListeners() call on first launch.
    if (saved != null && saved != _isDarkMode) {
      _isDarkMode = saved;
      notifyListeners();
    }
  }

  /// Flips the current theme and persists the new value.
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _persist();
  }

  /// Sets the theme explicitly (e.g. when syncing from a user profile).
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    notifyListeners();
    await _persist();
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _isDarkMode);
  }
}
