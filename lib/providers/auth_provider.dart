import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:studentology/models/user_model.dart';
import 'package:studentology/services/auth_service.dart';
import 'package:studentology/services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  StreamSubscription? _authSub;

  // Holds the Firebase Auth UID directly — set immediately on sign-in,
  // before the async Firestore profile fetch completes or if it fails.
  String? _firebaseUid;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Prefer the raw Firebase Auth UID so providers can init even before
  // (or if) the Firestore profile fetch fails.
  String? get userId => _firebaseUid ?? _currentUser?.id;

  bool get isAuthenticated => _firebaseUid != null || _currentUser != null;

  AuthProvider({
    AuthService? authService,
    FirestoreService? firestoreService,
  })  : _authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService() {
    _listenToAuthState();
  }

  // ── Auth state listener ─────────────────────────────────────────────────

  void _listenToAuthState() {
    _authSub = _authService.authStateChanges.listen(
      (firebaseUser) async {
        if (firebaseUser == null) {
          _firebaseUid = null;
          _currentUser = null;
          notifyListeners();
        } else {
          // Store the UID immediately so providers can init without waiting
          // for the Firestore profile fetch.
          _firebaseUid = firebaseUser.uid;
          notifyListeners();
          await loadUser(firebaseUser.uid);
        }
      },
      onError: (e) {
        _errorMessage = _clean(e);
        notifyListeners();
      },
    );
  }

  // ── Public methods ──────────────────────────────────────────────────────

  /// Loads (or reloads) the [UserModel] from Firestore for [userId].
  /// On failure (missing doc or permission error) a minimal fallback UserModel
  /// is created from the Firebase Auth profile so the rest of the app still works.
  Future<void> loadUser(String userId) async {
    try {
      final user = await _firestoreService.getUser(userId);
      if (user != null) {
        _currentUser = user;
      } else {
        // Doc doesn't exist — build a minimal model so the UI can display
        // the user's name and the providers can write to the correct path.
        final fbUser = _authService.getCurrentUser();
        _currentUser = UserModel(
          id: userId,
          name: fbUser?.displayName ?? '',
          email: fbUser?.email ?? '',
          createdAt: DateTime.now(),
        );
      }
    } catch (_) {
      // Firestore unavailable / permission denied — still set a minimal model
      // so HomeScreen can call _initProviders(userId).
      final fbUser = _authService.getCurrentUser();
      _currentUser = UserModel(
        id: userId,
        name: fbUser?.displayName ?? '',
        email: fbUser?.email ?? '',
        createdAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  /// Returns true on success; false sets [errorMessage] for the UI to display.
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signIn(email, password);
      // _listenToAuthState will load UserModel automatically.
      return true;
    } catch (e) {
      _errorMessage = _clean(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Returns true on success; false sets [errorMessage].
  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.register(email, password, name);
      return true;
    } catch (e) {
      _errorMessage = _clean(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _firebaseUid = null;
    _currentUser = null;
    notifyListeners();
  }

  /// Persists changes to Firestore and refreshes [currentUser] locally.
  Future<void> updateProfile(UserModel updated) async {
    try {
      await _firestoreService.updateUser(updated.id, updated.toMap());
      _currentUser = updated;
      notifyListeners();
    } catch (e) {
      _errorMessage = _clean(e);
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordReset(email);
    } catch (e) {
      throw Exception(_clean(e));
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _authService.changePassword(currentPassword, newPassword);
    } catch (e) {
      throw Exception(_clean(e));
    }
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() => _errorMessage = null;

  // Strips the "Exception: " prefix added by Dart's Exception.toString().
  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
