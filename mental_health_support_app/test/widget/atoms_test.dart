import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/presentation/components/atoms/metric_pill.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_pill_button.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_text_field.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mood_orb.dart';
import 'package:mental_health_support_app/presentation/components/atoms/severity_badge.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('SeverityBadge renders the normalized severity label', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SeverityBadge(severity: 'warning')));

    expect(find.text('Needs Review'), findsOneWidget);
  });

  testWidgets('MindCarePillButton invokes onPressed when enabled', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      wrap(MindCarePillButton(label: 'Continue', onPressed: () => taps++)),
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('MindCarePillButton ignores taps while loading', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      wrap(
        MindCarePillButton(
          label: 'Save',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byType(MindCarePillButton));
    await tester.pump();

    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('MindCareTextField toggles password visibility', (tester) async {
    await tester.pumpWidget(
      wrap(
        const MindCareTextField(
          label: 'Password',
          hint: 'Enter password',
          isPassword: true,
        ),
      ),
    );

    expect(find.text('Password'), findsOneWidget);
    expect(find.byTooltip('Show password'), findsOneWidget);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('MetricPill renders values and invokes taps', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      wrap(
        MetricPill(
          icon: PhosphorIcons.drop(PhosphorIconsStyle.duotone),
          value: '6',
          label: 'glasses',
          color: AppColors.skyDeep,
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.text('6'), findsOneWidget);
    expect(find.text('glasses'), findsOneWidget);

    await tester.tap(find.byType(MetricPill));
    expect(taps, 1);
  });

  testWidgets('MetricPill shows progress indicator while loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MetricPill(
          icon: PhosphorIcons.drop(PhosphorIconsStyle.duotone),
          value: '6',
          label: 'glasses',
          color: AppColors.skyDeep,
          isLoading: true,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('6'), findsNothing);
  });

  testWidgets('MoodOrb clamps labels and calls tap callback', (tester) async {
    var selected = false;

    await tester.pumpWidget(
      wrap(
        MoodOrb(
          level: 7,
          showLabel: true,
          selected: true,
          onTap: () => selected = true,
        ),
      ),
    );

    expect(find.text('Great'), findsOneWidget);

    await tester.tap(find.byType(MoodOrb));
    expect(selected, isTrue);
  });
}
