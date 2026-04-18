import 'package:flutter/material.dart';
import '../../../components/section_title.dart';
import 'common_card.dart';
import 'save_indicator.dart';

class MoodSection extends StatelessWidget {
  final double moodValue;
  final Function(double) onChanged;
  final bool saving;
  final bool saved;

  const MoodSection({
    super.key,
    required this.moodValue,
    required this.onChanged,
    required this.saving,
    required this.saved,
  });

  @override
  Widget build(BuildContext context) {
    final moods = [
      _Mood(Icons.sentiment_very_dissatisfied, Colors.red.shade400,    'Very Bad'),
      _Mood(Icons.sentiment_dissatisfied,      Colors.orange.shade400, 'Bad'),
      _Mood(Icons.sentiment_neutral,           Colors.amber.shade600,  'Neutral'),
      _Mood(Icons.sentiment_satisfied,         Colors.green.shade400,  'Happy'),
      _Mood(Icons.sentiment_very_satisfied,    Colors.teal.shade400,   'Very Happy'),
    ];

    final index = (moodValue.round() - 1).clamp(0, 4);
    final mood  = moods[index];

    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Patient Mood',
            trailing: SaveIndicator(saving: saving, saved: saved),
          ),

          const SizedBox(height: 16),

          // Mood icon strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: moods.asMap().entries.map((entry) {
              final i      = entry.key;
              final m      = entry.value;
              final active = i == index;

              return GestureDetector(
                onTap: () => onChanged(i + 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: active ? m.color.withOpacity(0.15) : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [BoxShadow(color: m.color.withOpacity(0.4), blurRadius: 12, spreadRadius: 1)]
                        : [],
                  ),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: active ? 1.4 : 1.0,
                    child: Icon(m.icon,
                        size: active ? 28 : 20,
                        color: active ? m.color : Colors.grey.shade400),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(mood.icon, key: ValueKey(mood.icon), size: 58, color: mood.color),
            ),
          ),

          const SizedBox(height: 6),

          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                mood.label,
                key: ValueKey(mood.label),
                style: TextStyle(color: mood.color, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Slider(
            value: moodValue,
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: mood.color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Mood {
  final IconData icon;
  final Color    color;
  final String   label;
  _Mood(this.icon, this.color, this.label);
}

//end of file mishara