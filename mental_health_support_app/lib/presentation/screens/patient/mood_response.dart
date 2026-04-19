import 'package:flutter/material.dart';

class _MoodAction {
  final String emoji;
  final String label;
  const _MoodAction(this.emoji, this.label);
}

class _MoodConfig {
  final String title;
  final Color tileColor;
  final Color tileBorder;
  final List<_MoodAction> actions;
  const _MoodConfig({
    required this.title,
    required this.tileColor,
    required this.tileBorder,
    required this.actions,
  });
}

_MoodConfig getMoodConfig(int m) {
  switch (m) {
    case 5:
      return const _MoodConfig(
        title: "You're feeling great today! 🤩",
        tileColor: Color(0xFFEAF3FB),
        tileBorder: Color(0xFFB5D4F4),
        actions: [
          _MoodAction('🧘', 'Meditate for 10 minutes'),
          _MoodAction('🚶', 'Go for a walk'),
          _MoodAction('📔', 'Write a gratitude note'),
        ],
      );
    case 4:
      return const _MoodConfig(
        title: "Feeling okay? Let's stay balanced 🌿",
        tileColor: Color(0xFFEAF3FB),
        tileBorder: Color(0xFFB5D4F4),
        actions: [
          _MoodAction('🧘', 'Take a mindful break'),
          _MoodAction('🎵', 'Listen to calm music'),
          _MoodAction('💬', 'Chat with a friend'),
        ],
      );
    case 3:
      return const _MoodConfig(
        title: "You're in a neutral zone 😐",
        tileColor: Color(0xFFEAF3FB),
        tileBorder: Color(0xFFB5D4F4),
        actions: [
          _MoodAction('💬', 'Share your thoughts with your doctor'),
          _MoodAction('🌳', 'Step outside for fresh air'),
          _MoodAction('🎨', 'Try a creative activity'),
        ],
      );
    case 2:
      return const _MoodConfig(
        title: "Feeling bit down? It's okay 💛",
        tileColor: Color(0xFFEAF3FB),
        tileBorder: Color(0xFFB5D4F4),
        actions: [
          _MoodAction('🧘', 'Breathing 2 minutes'),
          _MoodAction('🎵', 'Listen relax music'),
          _MoodAction('👤', 'Talk with counselor'),
        ],
      );
    default:
      return const _MoodConfig(
        title: "We're here for you ❤️",
        tileColor: Color(0xFFFEF0EF),
        tileBorder: Color(0xFFF7C1C1),
        actions: [
          _MoodAction('🔔', 'Emergency'),
          _MoodAction('📞', 'Connect doctor now'),
          _MoodAction('📔', "Write you're feeling"),
        ],
      );
  }
}

class _ActionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final Color bgColor;
  final Color borderColor;

  const _ActionTile({
    required this.emoji,
    required this.label,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MoodResponse extends StatelessWidget {
  final int mood;
  const MoodResponse({super.key, required this.mood});

  @override
  Widget build(BuildContext context) {
    final config = getMoodConfig(mood);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                config.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 28),
              ...config.actions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ActionTile(
                    emoji: action.emoji,
                    label: action.label,
                    bgColor: config.tileColor,
                    borderColor: config.tileBorder,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.black87, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text(
                    'Save my mood',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
