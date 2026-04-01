import 'package:flutter/material.dart';

class TestMoodResponse extends StatelessWidget {
  final int mood;
  const TestMoodResponse({super.key, required this.mood});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('[TEST] Mood Response'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder — AI response goes here later
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(children: [
                  Text(_moodEmoji(mood),
                      style: const TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  Text('You selected: ${_moodLabel(mood)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                    'AI response will appear here based on mood.\n'
                        'This screen is a placeholder.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _moodEmoji(int m) {
    switch (m) {
      case 1: return '😞'; case 2: return '😟';
      case 3: return '😐'; case 4: return '🙂';
      case 5: return '😊'; default: return '😐';
    }
  }

  String _moodLabel(int m) {
    switch (m) {
      case 1: return 'Worse'; case 2: return 'Bad';
      case 3: return 'Okay'; case 4: return 'Good';
      case 5: return 'Happy'; default: return '';
    }
  }
}