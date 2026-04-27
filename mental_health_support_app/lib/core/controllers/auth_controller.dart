import '../services/auth_service.dart';
import '../state/auth_state.dart';
import '../models/app_user.dart';
import 'notification_controller.dart';

// connect user with services

class AuthController {
  // ── Login
  static Future<AuthResult> login(String email, String password) async {
    final result = await AuthService.login(email, password);
    // Calls service , Stores user in state
    if (result.isSuccess && result.user != null) {
      AuthState.setUser(result.user!);

      if (result.user!.role == 'patient' || result.user!.role == 'guardian') {
        await NotificationController.saveToken(result.user!.uid);
      }
    }

    return result;
  }

  // ── Logout
  static Future<void> logout() async {
    await AuthService.logout();
    AuthState.clearUser();
  }

  // ── Session restore on app open
  static Future<AppUser?> restoreSession() async {
    final user = await AuthService.getSessionUser();
    if (user != null) AuthState.setUser(user);
    return user;
  }

  // ── Current user shortcut ─────────────────────────────
  static AppUser? get currentUser => AuthState.currentUser;
}
