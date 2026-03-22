import '../models/app_user.dart';


//  stores the currently logged-in user in RAM.

// static AppUser? _currentUser;
// don’t pass user everywhere

// Global access: AuthState.currentUser

class AuthState {
  static AppUser? _currentUser;

  static AppUser? get currentUser => _currentUser;

  static bool get isLoggedIn => _currentUser != null;

  static void setUser(AppUser user) {
    _currentUser = user;
  }

  static void clearUser() {
    _currentUser = null;
  }
}