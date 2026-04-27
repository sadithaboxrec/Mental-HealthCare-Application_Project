import 'dart:math';

class TypingCadenceTracker {
  DateTime? _lastKeystroke;
  final List<int> _ikis = []; // Inter-keystroke intervals in ms
  int _backspaceCount = 0;
  int _totalKeystrokes = 0;
  int _previousLength = 0;

  void onTextChanged(String text) {
    final now = DateTime.now();
    final newLength = text.length;

    if (newLength < _previousLength) {
      // Detected backspace or deletion
      _backspaceCount += (_previousLength - newLength);
    } else if (newLength > _previousLength) {
      // Detected typing or paste
      final addedChars = newLength - _previousLength;
      _totalKeystrokes += addedChars;

      // We only measure cadence for single character typing (not large pastes)
      if (addedChars == 1 && _lastKeystroke != null) {
        final iki = now.difference(_lastKeystroke!).inMilliseconds;
        // Ignore pauses longer than 5 seconds (likely stopping to think, not active continuous typing)
        if (iki < 5000) {
          _ikis.add(iki);
        }
      }
    }

    _lastKeystroke = now;
    _previousLength = newLength;
  }

  Map<String, dynamic>? generateMetrics() {
    // If not enough data, don't generate metrics
    if (_ikis.length < 5 || _totalKeystrokes == 0) {
      return null;
    }

    final avgIki = _ikis.reduce((a, b) => a + b) / _ikis.length;
    double variance = 0;
    if (_ikis.length > 1) {
      final sumSq = _ikis
          .map((iki) => pow(iki - avgIki, 2))
          .reduce((a, b) => a + b);
      variance = sumSq / (_ikis.length - 1);
    }

    return {
      'averageIkiMs': avgIki.round(),
      'varianceIki': variance.round(),
      'backspaceRatio': double.parse(
        (_backspaceCount / _totalKeystrokes).toStringAsFixed(2),
      ),
      'keystrokes': _totalKeystrokes,
    };
  }
}
