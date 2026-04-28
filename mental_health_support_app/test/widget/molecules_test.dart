import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mental_health_support_app/presentation/components/molecules/appointment_tile.dart';
import 'package:mental_health_support_app/presentation/components/molecules/daily_pulse_row.dart';
import 'package:mental_health_support_app/presentation/components/molecules/diary_entry_card.dart';
import 'package:mental_health_support_app/presentation/components/molecules/medicine_card.dart';
import 'package:mental_health_support_app/presentation/components/molecules/patient_card.dart';
import 'package:mental_health_support_app/presentation/components/molecules/waiting_patient_bubble.dart';
import 'package:mental_health_support_app/presentation/components/molecules/xai_insight_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 700, child: child)),
      ),
    );
  }

  testWidgets('AppointmentTile formats date, time, status, and handles taps', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      wrap(
        AppointmentTile(
          date: '2026-04-28',
          time: '14:30',
          doctorOrPatientName: 'Dr. Silva',
          status: 'completed',
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.text('28'), findsOneWidget);
    expect(find.text('Apr'), findsOneWidget);
    expect(find.text('2:30 PM'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    await tester.tap(find.text('Dr. Silva'));
    expect(taps, 1);
  });

  testWidgets('DailyPulseRow renders patient daily metric labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const DailyPulseRow(
          moodLevel: 5,
          sleepHours: '7.5',
          waterGlasses: '6',
          medicationTaken: true,
        ),
      ),
    );

    expect(find.text('Great'), findsOneWidget);
    expect(find.text('Mood'), findsOneWidget);
    expect(find.text('7.5'), findsOneWidget);
    expect(find.text('Taken'), findsOneWidget);
  });

  testWidgets(
    'DiaryEntryCard previews content and exposes edit/delete actions',
    (tester) async {
      var edited = false;
      var deleted = false;

      await tester.pumpWidget(
        wrap(
          DiaryEntryCard(
            id: 'entry-1',
            content: 'Today I felt calmer after journaling.',
            createdAt: DateTime(2026, 4, 28),
            onEdit: () => edited = true,
            onDelete: () => deleted = true,
          ),
        ),
      );

      expect(find.text('28 Apr 2026'), findsOneWidget);
      expect(
        find.text('Today I felt calmer after journaling.'),
        findsOneWidget,
      );

      await tester.tap(find.bySemanticsLabel('Edit'));
      await tester.tap(find.bySemanticsLabel('Delete'));

      expect(edited, isTrue);
      expect(deleted, isTrue);
    },
  );

  testWidgets('MedicineCard shows dose, slots, and meal timing', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const MedicineCard(
          name: 'Sertraline',
          dose: '50mg',
          morning: true,
          night: true,
          beforeMeal: true,
        ),
      ),
    );

    expect(find.text('Sertraline'), findsOneWidget);
    expect(find.text('50mg'), findsOneWidget);
    expect(find.text('Morning'), findsOneWidget);
    expect(find.text('Night'), findsOneWidget);
    expect(find.text('Before meal'), findsOneWidget);
  });

  testWidgets('PatientCard renders clinical summary and action buttons', (
    tester,
  ) async {
    var messages = 0;
    var reports = 0;

    await tester.pumpWidget(
      wrap(
        PatientCard(
          patientId: 'patient-1',
          name: 'Maya Perera',
          severity: 'critical',
          xaiScore: 8,
          lastActive: DateTime.now().subtract(const Duration(hours: 2)),
          onMessage: () => messages++,
          onViewReport: () => reports++,
        ),
      ),
    );

    expect(find.text('Maya Perera'), findsOneWidget);
    expect(find.text('Critical'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Message'));
    await tester.tap(find.bySemanticsLabel('View report'));

    expect(messages, 1);
    expect(reports, 1);
  });

  testWidgets('WaitingPatientBubble displays wait state and actions', (
    tester,
  ) async {
    var accepted = 0;
    var declined = 0;

    await tester.pumpWidget(
      wrap(
        WaitingPatientBubble(
          patientName: 'Maya Perera',
          waitingSince: DateTime.now().subtract(const Duration(minutes: 5)),
          onAccept: () => accepted++,
          onDecline: () => declined++,
        ),
      ),
    );

    expect(find.text('Maya Perera'), findsOneWidget);
    expect(find.text('5 mins'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pump();
    await tester.tap(find.text('Decline'));

    expect(accepted, 1);
    expect(declined, 1);
  });

  testWidgets('XaiInsightCard renders drivers and view-more action', (
    tester,
  ) async {
    var viewMore = 0;

    await tester.pumpWidget(
      wrap(
        XaiInsightCard(
          score: 7,
          severity: 'warning',
          confidence: 0.8,
          primaryDrivers: const ['Low mood', 'Missed medication'],
          screeningNote: 'Same-day clinician review recommended.',
          onViewMore: () => viewMore++,
        ),
      ),
    );

    expect(find.text('Wellness Insight'), findsOneWidget);
    expect(find.text('Needs Review'), findsOneWidget);
    expect(find.text('Low mood'), findsOneWidget);
    expect(find.text('Missed medication'), findsOneWidget);

    await tester.tap(find.text('View Full Analysis'));
    expect(viewMore, 1);
  });
}
