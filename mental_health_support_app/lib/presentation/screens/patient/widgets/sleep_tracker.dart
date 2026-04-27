// import 'package:flutter/material.dart';
// import '../../../components2/section_title.dart';

// class SleepTracker extends StatelessWidget {
//   final String selectedSleep;
//   final Function(String) onSelect;
//   final Color primaryBlue;
//   final Color primaryBlueDeep;

//   const SleepTracker({
//     super.key,
//     required this.selectedSleep,
//     required this.onSelect,
//     required this.primaryBlue,
//     required this.primaryBlueDeep,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final sleepOptions = [
//       {'val': 'less5', 'lbl': '< 5h'},
//       {'val': '6', 'lbl': '6h'},
//       {'val': '7', 'lbl': '7h'},
//       {'val': '8', 'lbl': '8h'},
//       {'val': 'more8', 'lbl': '8h+'},
//     ];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(top: 6, right: 10),
//               child: Icon(
//                 Icons.bedtime_rounded,
//                 size: 34,
//                 color: primaryBlueDeep,
//               ),
//             ),
//             const Expanded(child: SectionTitle(title: 'Sleep Quality')),
//           ],
//         ),
//         SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: Row(
//             children: sleepOptions
//                 .map((opt) => _sleepChip(opt['val']!, opt['lbl']!))
//                 .toList(),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _sleepChip(String val, String label) {
//     bool isSel = selectedSleep == val;
//     return GestureDetector(
//       onTap: () => onSelect(val),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 220),
//         curve: Curves.easeOutCubic,
//         margin: const EdgeInsets.only(right: 8),
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
//         decoration: BoxDecoration(
//           gradient: isSel
//               ? LinearGradient(colors: [primaryBlueDeep, primaryBlue])
//               : null,
//           color: isSel ? null : Colors.white.withOpacity(0.55),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isSel
//                 ? Colors.white.withOpacity(0.55)
//                 : Colors.white.withOpacity(0.9),
//           ),
//           boxShadow: [
//             if (isSel)
//               BoxShadow(
//                 color: primaryBlueDeep.withOpacity(0.28),
//                 blurRadius: 12,
//                 offset: const Offset(0, 6),
//               )
//             else
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.04),
//                 blurRadius: 8,
//                 offset: const Offset(0, 3),
//               ),
//           ],
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: isSel ? Colors.white : const Color(0xFF2C3A4D),
//             fontWeight: FontWeight.w600,
//             fontSize: 13,
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:math' as math;

class SleepTracker extends StatelessWidget {
  final String selectedSleep;
  final Function(String) onSelect;
  final Color primaryBlue;
  final Color primaryBlueDeep;

  const SleepTracker({
    super.key,
    required this.selectedSleep,
    required this.onSelect,
    required this.primaryBlue,
    required this.primaryBlueDeep,
  });

  static const _sleepOptions = [
    {'val': 'less5', 'lbl': '<5h', 'emoji': '😵', 'hours': 0},
    {'val': '6', 'lbl': '6h', 'emoji': '🌙', 'hours': 6},
    {'val': '7', 'lbl': '7h', 'emoji': '⭐', 'hours': 7},
    {'val': '8', 'lbl': '8h', 'emoji': '✨', 'hours': 8},
    {'val': 'more8', 'lbl': '8h+', 'emoji': '☀️', 'hours': 8},
  ];

  String get _qualityLabel {
    switch (selectedSleep) {
      case 'less5':
        return 'Poor';
      case '6':
        return 'Fair';
      case '7':
        return 'Good';
      case '8':
        return 'Great';
      case 'more8':
        return 'Excellent';
      default:
        return '—';
    }
  }

  Color get _qualityColor {
    switch (selectedSleep) {
      case 'less5':
        return const Color(0xFFEF5350);
      case '6':
        return const Color(0xFFFF9800);
      case '7':
        return const Color(0xFF66BB6A);
      case '8':
        return const Color(0xFF29B6F6);
      case 'more8':
        return const Color(0xFF7E57C2);
      default:
        return Colors.grey;
    }
  }

  int get _selectedHours {
    switch (selectedSleep) {
      case 'less5':
        return 4;
      case '6':
        return 6;
      case '7':
        return 7;
      case '8':
        return 8;
      case 'more8':
        return 9;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with title and circular hours badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.bedtime_rounded,
                color: Color(0xFF7E57C2),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sleep Quality',
                    style: TextStyle(
                      color: Color(0xFF1A2744),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _qualityLabel,
                    style: TextStyle(
                      color: _qualityColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Circular progress timer badge
            _CircularTimerBadge(hours: _selectedHours, color: primaryBlueDeep),
          ],
        ),
        const SizedBox(height: 16),
        // Sleep option chips with emojis
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _sleepOptions
                .map(
                  (opt) => _sleepChip(
                    val: opt['val'] as String,
                    label: opt['lbl'] as String,
                    emoji: opt['emoji'] as String,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _sleepChip({
    required String val,
    required String label,
    required String emoji,
  }) {
    final isSel = selectedSleep == val;
    return GestureDetector(
      onTap: () => onSelect(val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSel
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryBlue, primaryBlueDeep],
                )
              : null,
          color: isSel ? null : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSel ? Colors.white.withOpacity(0.4) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: primaryBlueDeep.withOpacity(0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSel ? Colors.white : const Color(0xFF2C3A4D),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularTimerBadge extends StatelessWidget {
  final int hours;
  final Color color;

  const _CircularTimerBadge({required this.hours, required this.color});

  @override
  Widget build(BuildContext context) {
    final progress = hours == 0 ? 0.0 : (hours / 9.0).clamp(0.0, 1.0);
    return SizedBox(
      width: 54,
      height: 54,
      child: CustomPaint(
        painter: _ArcPainter(progress: progress, color: color),
        child: Center(
          child: hours == 0
              ? Icon(Icons.bedtime_outlined, color: color, size: 18)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$hours',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        height: 1,
                      ),
                    ),
                    Text(
                      'hrs',
                      style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;
    const strokeWidth = 4.0;

    // Background arc
    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}
