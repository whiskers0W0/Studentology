import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Auth state ──────────────────────────────────────────────────────────

  /// Emits a [User] whenever auth state changes (sign-in, sign-out, token refresh).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the currently signed-in Firebase user, or null if signed out.
  User? getCurrentUser() => _auth.currentUser;

  // ── Sign in ─────────────────────────────────────────────────────────────

  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  // ── Register ────────────────────────────────────────────────────────────

  /// Creates a Firebase Auth account, updates the display name, and writes the
  /// initial user document to Firestore under `users/{uid}`.
  Future<UserCredential> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // Update Firebase Auth display name in parallel with Firestore write.
      await Future.wait([
        credential.user!.updateDisplayName(name.trim()),
        _db.collection('users').doc(uid).set({
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'gradingSystem': 'percentage',
          'course': '',
          'isDarkMode': true,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      ]);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  // ── Sign out ────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Password reset ──────────────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  // ── Change password ─────────────────────────────────────────────────────

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  // ── Error mapping ───────────────────────────────────────────────────────

  // Maps Firebase error codes to student-friendly messages.
  // 'invalid-credential' is the consolidated code for wrong email/password
  // in newer Firebase SDK versions (replaces 'user-not-found' + 'wrong-password').
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'user-not-found':
        return 'No account found with that email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
}
