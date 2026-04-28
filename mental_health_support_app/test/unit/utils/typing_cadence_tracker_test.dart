import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/utils/typing_cadence_tracker.dart';

void main() {
  group('TypingCadenceTracker', () {
    test('does not generate metrics until enough cadence samples exist', () {
      final tracker = TypingCadenceTracker();

      tracker.onTextChanged('h');
      tracker.onTextChanged('he');

      expect(tracker.generateMetrics(), isNull);
    });

    test('generates cadence metrics after continuous typing', () async {
      final tracker = TypingCadenceTracker();

      for (final text in [
        'a',
        'ab',
        'abc',
        'abcd',
        'abcde',
        'abcdef',
        'abcdefg',
      ]) {
        tracker.onTextChanged(text);
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }

      final metrics = tracker.generateMetrics();

      expect(metrics, isNotNull);
      expect(metrics!['keystrokes'], 7);
      expect(metrics['averageIkiMs'], isA<int>());
      expect(metrics['varianceIki'], isA<int>());
      expect(metrics['backspaceRatio'], 0.0);
    });

    test('tracks deletion pressure as a backspace ratio', () async {
      final tracker = TypingCadenceTracker();

      for (final text in [
        'a',
        'ab',
        'abc',
        'abcd',
        'abcde',
        'abcdef',
        'abcdefg',
      ]) {
        tracker.onTextChanged(text);
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      tracker.onTextChanged('abcde');

      final metrics = tracker.generateMetrics();

      expect(metrics, isNotNull);
      expect(metrics!['backspaceRatio'], 0.29);
    });
  });
}
