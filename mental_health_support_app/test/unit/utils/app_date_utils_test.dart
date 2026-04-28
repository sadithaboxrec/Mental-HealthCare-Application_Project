import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/utils/app_date_utils.dart';

void main() {
  group('AppDateUtils', () {
    test('formats long and short dates for display', () {
      final date = DateTime(2026, 4, 28);

      expect(AppDateUtils.formatDate(date), 'Tuesday, 28 April');
      expect(AppDateUtils.formatShortDate(date), '28 Apr 2026');
    });

    test('formats 24-hour time strings as 12-hour display values', () {
      expect(AppDateUtils.formatTime('00:05'), '12:05 AM');
      expect(AppDateUtils.formatTime('09:30'), '9:30 AM');
      expect(AppDateUtils.formatTime('18:45'), '6:45 PM');
    });

    test('returns the original value when time parsing fails', () {
      expect(AppDateUtils.formatTime('not-a-time'), 'not-a-time');
    });

    test('formats recent timestamps into relative labels', () {
      expect(AppDateUtils.timeAgo(DateTime.now()), 'Just now');
      expect(
        AppDateUtils.timeAgo(
          DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        '5m ago',
      );
      expect(
        AppDateUtils.timeAgo(DateTime.now().subtract(const Duration(hours: 3))),
        '3h ago',
      );
      expect(
        AppDateUtils.timeAgo(DateTime.now().subtract(const Duration(days: 1))),
        'Yesterday',
      );
    });

    test('formats wait durations for queues', () {
      expect(AppDateUtils.waitTime(DateTime.now()), '< 1 min');
      expect(
        AppDateUtils.waitTime(
          DateTime.now().subtract(const Duration(minutes: 1)),
        ),
        '1 min',
      );
      expect(
        AppDateUtils.waitTime(
          DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
        ),
        '2h 15m',
      );
    });

    test('identifies today keys and rejects invalid date strings', () {
      expect(AppDateUtils.isToday(AppDateUtils.todayKey()), isTrue);
      expect(AppDateUtils.isToday('2020-01-01'), isFalse);
      expect(AppDateUtils.isToday('not-a-date'), isFalse);
    });
  });
}
