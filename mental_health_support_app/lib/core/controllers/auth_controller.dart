import '../services/auth_service.dart';
import '../state/auth_state.dart';
import '../models/app_user.dart';
import 'notification_controller.dart';

typedef AuthLoginDelegate =
    Future<AuthResult> Function(String email, String password);
typedef AuthLogoutDelegate = Future<void> Function();
typedef AuthRestoreDelegate = Future<AppUser?> Function();
typedef SaveNotificationTokenDelegate = Future<void> Function(String uid);

class AuthController {
  static AuthLoginDelegate _login = AuthService.login;
  static AuthLogoutDelegate _logout = AuthService.logout;
  static AuthRestoreDelegate _restoreSession = AuthService.getSessionUser;
  static SaveNotificationTokenDelegate _saveToken =
      NotificationController.saveToken;

  static void configureForTesting({
    AuthLoginDelegate? login,
    AuthLogoutDelegate? logout,
    AuthRestoreDelegate? restoreSession,
    SaveNotificationTokenDelegate? saveToken,
  }) {
    _login = login ?? _login;
    _logout = logout ?? _logout;
    _restoreSession = restoreSession ?? _restoreSession;
    _saveToken = saveToken ?? _saveToken;
  }

  static void resetForTesting() {
    _login = AuthService.login;
    _logout = AuthService.logout;
    _restoreSession = AuthService.getSessionUser;
    _saveToken = NotificationController.saveToken;
    AuthState.clearUser();
  }

  static Future<AuthResult> login(String email, String password) async {
    final result = await _login(email, password);

    if (result.isSuccess && result.user != null) {
      AuthState.setUser(result.user!);

      if (result.user!.role == 'patient' || result.user!.role == 'guardian') {
        await _saveToken(result.user!.uid);
      }
    }

    return result;
  }

  static Future<void> logout() async {
    await _logout();
    AuthState.clearUser();
  }

  static Future<AppUser?> restoreSession() async {
    final user = await _restoreSession();
    if (user != null) AuthState.setUser(user);
    return user;
  }

  static AppUser? get currentUser => AuthState.currentUser;
}
