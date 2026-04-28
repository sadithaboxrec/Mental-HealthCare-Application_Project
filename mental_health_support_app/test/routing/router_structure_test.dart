import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/router/app_router.dart';

void main() {
  group('app router module', () {
    test('exposes a router provider for composition at app startup', () {
      expect(routerProvider.name, isNull);
    });
  });
}
