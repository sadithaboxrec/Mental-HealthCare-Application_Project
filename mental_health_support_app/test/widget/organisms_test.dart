import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mental_health_support_app/presentation/components/organisms/confirmation_dialog.dart';
import 'package:mental_health_support_app/presentation/components/organisms/gradient_hero_header.dart';
import 'package:mental_health_support_app/presentation/components/organisms/mindcare_bottom_nav.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: SizedBox(width: 720, child: child)),
    );
  }

  testWidgets(
    'MindCareBottomNav marks current item and reports index changes',
    (tester) async {
      final tapped = <int>[];

      await tester.pumpWidget(
        wrap(
          MindCareBottomNav(
            currentIndex: 0,
            onTap: tapped.add,
            items: [
              MindCareNavItem(
                label: 'Home',
                icon: PhosphorIcons.house(PhosphorIconsStyle.regular),
                semanticLabel: 'Home tab',
              ),
              MindCareNavItem(
                label: 'Care',
                icon: PhosphorIcons.heart(PhosphorIconsStyle.regular),
                semanticLabel: 'Care tab',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Care'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Care tab'));

      expect(tapped, [1]);
    },
  );

  testWidgets(
    'GradientHeroHeader renders role greeting content and bottom area',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const GradientHeroHeader(
            name: 'Maya',
            role: 'patient',
            bottom: Text('Daily pulse'),
          ),
        ),
      );

      expect(find.textContaining('Good'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Daily pulse'), findsOneWidget);
    },
  );

  testWidgets(
    'ConfirmationDialog returns true for confirm and false for cancel',
    (tester) async {
      bool? firstResult;
      bool? secondResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () async {
                    firstResult = await ConfirmationDialog.show(
                      context,
                      icon: PhosphorIcons.warning(PhosphorIconsStyle.regular),
                      title: 'Delete entry?',
                      message: 'This cannot be undone.',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                  },
                  child: const Text('Open confirm'),
                ),
                TextButton(
                  onPressed: () async {
                    secondResult = await ConfirmationDialog.show(
                      context,
                      icon: PhosphorIcons.info(PhosphorIconsStyle.regular),
                      title: 'Leave screen?',
                      message: 'Unsaved changes may be lost.',
                      confirmLabel: 'Leave',
                    );
                  },
                  child: const Text('Open cancel'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(firstResult, isTrue);
      expect(secondResult, isFalse);
    },
  );
}
