import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/models/app_user.dart';
import 'package:mental_health_support_app/core/state/auth_state.dart';

void main() {
  tearDown(AuthState.clearUser);

  test('starts logged out until a user is set', () {
    AuthState.clearUser();

    expect(AuthState.currentUser, isNull);
    expect(AuthState.isLoggedIn, isFalse);
  });

  test('stores the active user in memory', () {
    const user = AppUser(
      uid: 'doctor-1',
      name: 'Dr. Silva',
      email: 'doctor@example.com',
      phone: '0711234567',
      role: 'doctor',
      createdAt: '2026-04-20T10:00:00Z',
    );

    AuthState.setUser(user);

    expect(AuthState.currentUser, same(user));
    expect(AuthState.isLoggedIn, isTrue);
  });

  test('clearUser removes the active user', () {
    AuthState.setUser(
      const AppUser(
        uid: 'guardian-1',
        name: 'Nimal',
        email: 'guardian@example.com',
        phone: '0701234567',
        role: 'guardian',
        createdAt: '2026-04-20T10:00:00Z',
      ),
    );

    AuthState.clearUser();

    expect(AuthState.currentUser, isNull);
    expect(AuthState.isLoggedIn, isFalse);
  });
}
