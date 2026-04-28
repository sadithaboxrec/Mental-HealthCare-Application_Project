import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mental_health_support_app/presentation/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'login flow validates empty credentials before auth service call',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(390, 844)),
              child: LoginScreen(),
            ),
          ),
        ),
      );

      expect(find.text('MindCare'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter email and password.'), findsOneWidget);
    },
  );
}
