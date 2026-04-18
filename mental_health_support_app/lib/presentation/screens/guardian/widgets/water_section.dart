import 'package:flutter/material.dart';
import 'common_card.dart';

class WaterSection extends StatelessWidget {
  final int intake;
  final Function(int) onAdd;

  const WaterSection({super.key, required this.intake, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final progress = (intake / 8).clamp(0.0, 1.0);
    final progressColor = progress < 0.4
        ? Colors.redAccent
        : progress < 0.7
            ? Colors.orange
            : const Color(0xFF2ECC71);

    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.water_drop_rounded, color: Color(0xFF4A90D9)),
            SizedBox(width: 8),
            Text('Water Intake',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          ]),

          const SizedBox(height: 6),
          Text('$intake / 8 glasses today',
              style: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 12)),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFBDD7F8),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [1, 2, 3, 5].map((g) => InkWell(
              onTap: () => onAdd(g),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEEDFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF4A90D9).withOpacity(0.40)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_drink_rounded, size: 16, color: Color(0xFF4A90D9)),
                  const SizedBox(width: 6),
                  Text('+$g',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4A90D9))),
                ]),
              ),
            )).toList(),
          ),

          const SizedBox(height: 10),
          Text(
            progress < 1 ? 'Keep going! Stay hydrated 💧' : 'Great job! You reached your goal 🎉',
            style: TextStyle(fontSize: 12, color: progressColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
//end of file mishara