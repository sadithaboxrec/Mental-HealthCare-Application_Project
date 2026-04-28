import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/models/medicine.dart';

void main() {
  group('Medicine', () {
    test('round-trips timing and meal fields', () {
      final medicine = Medicine.fromMap({
        'name': 'Sertraline',
        'dose': '50mg',
        'beforeMeal': true,
        'tabletCount': 2,
        'morning': true,
      });

      expect(medicine.toMap(), {
        'name': 'Sertraline',
        'dose': '50mg',
        'beforeMeal': true,
        'afterMeal': false,
        'tabletCount': 2,
        'morning': true,
        'afternoon': false,
        'night': false,
      });
    });
  });
}
