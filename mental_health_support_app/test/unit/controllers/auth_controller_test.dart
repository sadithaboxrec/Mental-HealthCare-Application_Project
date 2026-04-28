import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/controllers/auth_controller.dart';
import 'package:mental_health_support_app/core/models/app_user.dart';
import 'package:mental_health_support_app/core/services/auth_service.dart';
import 'package:mental_health_support_app/core/state/auth_state.dart';

void main() {
  const patient = AppUser(
    uid: 'patient-1',
    name: 'Maya Perera',
    email: 'maya@example.com',
    phone: '0771234567',
    role: 'patient',
    createdAt: '2026-04-28T08:00:00Z',
  );

  const doctor = AppUser(
    uid: 'doctor-1',
    name: 'Dr Silva',
    email: 'doctor@example.com',
    phone: '0711234567',
    role: 'doctor',
    createdAt: '2026-04-28T08:00:00Z',
  );

  tearDown(AuthController.resetForTesting);

  test('login stores successful users in AuthState', () async {
    AuthController.configureForTesting(
      login: (_, _) async => AuthResult.success(doctor),
      saveToken: (_) async {},
    );

    final result = await AuthController.login('doctor@example.com', 'secret');

    expect(result.isSuccess, isTrue);
    expect(AuthState.currentUser, same(doctor));
  });

  test(
    'login saves notification token for patient and guardian roles',
    () async {
      final savedTokens = <String>[];
      AuthController.configureForTesting(
        login: (_, _) async => AuthResult.success(patient),
        saveToken: (uid) async => savedTokens.add(uid),
      );

      await AuthController.login('maya@example.com', 'secret');

      expect(savedTokens, ['patient-1']);
    },
  );

  test('login leaves AuthState unchanged on failure', () async {
    AuthController.configureForTesting(
      login: (_, _) async => AuthResult.failure('Invalid email or password.'),
      saveToken: (_) async {},
    );

    final result = await AuthController.login('bad@example.com', 'wrong');

    expect(result.isSuccess, isFalse);
    expect(AuthState.currentUser, isNull);
  });

  test('logout delegates to auth service and clears AuthState', () async {
    var loggedOut = false;
    AuthState.setUser(doctor);
    AuthController.configureForTesting(logout: () async => loggedOut = true);

    await AuthController.logout();

    expect(loggedOut, isTrue);
    expect(AuthState.currentUser, isNull);
  });

  test('restoreSession stores restored users', () async {
    AuthController.configureForTesting(restoreSession: () async => doctor);

    final restored = await AuthController.restoreSession();

    expect(restored, same(doctor));
    expect(AuthController.currentUser, same(doctor));
  });
}
