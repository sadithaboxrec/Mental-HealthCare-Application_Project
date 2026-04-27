import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

// communicate with firebase

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // ── Login
  static Future<AuthResult> login(String email, String password) async {
    try {
      // firebase login
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // fetch user from firestore
      final user = await _fetchUser(credential.user!.uid);

      // AuthResult returns a clean objects

      // validations
      if (user == null) {
        await _auth.signOut();
        return AuthResult.failure('Account data not found. Contact admin.');
      }

      if (user.role.isEmpty) {
        await _auth.signOut();
        return AuthResult.failure('No role assigned. Contact admin.');
      }
      // return the user
      return AuthResult.success(user);
      // or failed to find the user
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapError(e.code));
    } catch (e) {
      return AuthResult.failure('Unexpected error. Please try again.');
    }
  }

  // ── Logout
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Auth state stream ─────────────────────────────────
  // Listen to this in main.dart to react to login/logout instantly
  static Stream<User?> get authStateStream => _auth.authStateChanges();

  // ── Session check on app open ─────────────────────────
  static Future<AppUser?> getSessionUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      await firebaseUser.reload();
    } catch (_) {
      await _auth.signOut();
      return null;
    }

    return await _fetchUser(firebaseUser.uid);
  }

  // ── Fetch user document from Firestore ────────────────
  static Future<AppUser?> _fetchUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  // ── Friendly error messages ───────────────────────────
  static String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Login failed. Please try again.';
    }
  }
}

// ── Result wrapper ────────────────────────────────────────
// Controller reads this, never raw exceptions
class AuthResult {
  final bool isSuccess;
  final AppUser? user;
  final String? error;

  const AuthResult._({required this.isSuccess, this.user, this.error});

  factory AuthResult.success(AppUser user) =>
      AuthResult._(isSuccess: true, user: user);

  factory AuthResult.failure(String error) =>
      AuthResult._(isSuccess: false, error: error);
}
