import 'package:flutter/material.dart';
import '../../../components2/section_title.dart';

class MoodTracker extends StatelessWidget {
  final int currentMood;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onSave;
  final List<Color> emojiColors;
  final Color primaryBlue;
  final Color primaryBlueDeep;

  const MoodTracker({
    super.key,
    required this.currentMood,
    required this.onChanged,
    required this.onSave,
    required this.emojiColors,
    required this.primaryBlue,
    required this.primaryBlueDeep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTitle(
          title: 'Current Mood',
          subtitle: 'Slide the bar — your chosen face grows bigger',
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F8FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryBlue.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 88,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _moodIcon(
                      1,
                      Icons.sentiment_very_dissatisfied_rounded,
                      emojiColors[0],
                    ),
                    _moodIcon(
                      2,
                      Icons.sentiment_dissatisfied_rounded,
                      emojiColors[1],
                    ),
                    _moodIcon(
                      3,
                      Icons.sentiment_neutral_rounded,
                      emojiColors[2],
                    ),
                    _moodIcon(
                      4,
                      Icons.sentiment_satisfied_rounded,
                      emojiColors[3],
                    ),
                    _moodIcon(
                      5,
                      Icons.sentiment_very_satisfied_rounded,
                      emojiColors[4],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 7,
                  activeTrackColor: primaryBlueDeep,
                  inactiveTrackColor: primaryBlue.withOpacity(0.22),
                  thumbColor: Colors.white,
                  overlayColor: primaryBlueDeep.withOpacity(0.18),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 14,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 26,
                  ),
                ),
                child: Slider(
                  value: currentMood.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (v) => onChanged(v.round()),
                  onChangeEnd: (v) => onSave(v.round()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _moodIcon(int index, IconData icon, Color moodColor) {
    final active = currentMood == index;
    return AnimatedScale(
      scale: active ? 1.92 : 0.62,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: active ? 1.0 : 0.5,
        child: Icon(
          icon,
          color: active ? moodColor : moodColor.withOpacity(0.42),
          size: 42,
        ),
      ),
    );
  }
}
