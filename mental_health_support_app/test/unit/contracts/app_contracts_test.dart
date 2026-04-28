import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/assets/app_assets.dart';
import 'package:mental_health_support_app/core/services/api_service.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';

void main() {
  group('AppAssets', () {
    test('uses stable asset paths declared by pubspec asset directories', () {
      expect(AppAssets.logo, 'assets/brand/mindcare_logo.png');
      expect(AppAssets.loginHero, startsWith('assets/onboarding/'));
      expect(AppAssets.patientHomeHeader, startsWith('assets/illustrations/'));
      expect(AppAssets.emptyReports, startsWith('assets/states/'));
      expect(AppAssets.errorState, startsWith('assets/states/'));
    });
  });

  group('ApiException', () {
    test('includes status code and response body in diagnostic string', () {
      const exception = ApiException(404, '{"error":"Not found"}');

      expect(exception.toString(), 'ApiException(404): {"error":"Not found"}');
    });
  });

  group('AppColors', () {
    test('maps unknown clinical severities to stable colors', () {
      expect(AppColors.severityColor('unknown'), AppColors.stable);
      expect(AppColors.severityDeepColor('unknown'), AppColors.stableDeep);
    });

    test('maps roles to their primary UI colors', () {
      expect(AppColors.rolePrimary('doctor'), AppColors.sky);
      expect(AppColors.rolePrimary('guardian'), AppColors.mint);
      expect(AppColors.rolePrimary('counselor'), AppColors.amber);
      expect(AppColors.rolePrimary('patient'), AppColors.lavender);
      expect(AppColors.rolePrimary('unknown'), AppColors.lavender);
    });

    test('clamps mood colors to neutral when level is outside 1 to 5', () {
      expect(AppColors.moodColor(0), AppColors.mood3);
      expect(AppColors.moodColor(6), AppColors.mood3);
      expect(AppColors.moodColor(5), AppColors.mood5);
    });
  });
}
