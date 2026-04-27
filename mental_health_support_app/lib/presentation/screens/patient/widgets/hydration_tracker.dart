// import 'package:flutter/material.dart';
// import 'dart:ui' show ImageFilter;
// import '../../../components2/section_title.dart';

// class HydrationTracker extends StatelessWidget {
//   final int count;
//   final Function(int) onAdd;
//   final Color primaryBlue;
//   final Color primaryBlueDeep;

//   const HydrationTracker({
//     super.key,
//     required this.count,
//     required this.onAdd,
//     required this.primaryBlue,
//     required this.primaryBlueDeep,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(top: 6, right: 10),
//               child: Icon(
//                 Icons.water_drop_rounded,
//                 size: 34,
//                 color: primaryBlueDeep,
//               ),
//             ),
//             const Expanded(
//               child: SectionTitle(
//                 title: 'Stay Hydrated',
//                 subtitle: 'Daily Goal: 8 Glasses',
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     primaryBlue.withOpacity(0.45),
//                     primaryBlueDeep.withOpacity(0.35),
//                   ],
//                 ),
//                 border: Border.all(color: Colors.white, width: 2.5),
//                 boxShadow: [
//                   BoxShadow(
//                     color: primaryBlueDeep.withOpacity(0.45),
//                     blurRadius: 18,
//                     offset: const Offset(0, 6),
//                   ),
//                   BoxShadow(
//                     color: Colors.white.withOpacity(0.9),
//                     blurRadius: 0,
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               child: Text(
//                 '$count',
//                 style: TextStyle(
//                   color: primaryBlueDeep,
//                   fontWeight: FontWeight.w900,
//                   fontSize: 24,
//                   height: 1,
//                   letterSpacing: -0.5,
//                   shadows: [
//                     Shadow(
//                       color: Colors.white.withOpacity(0.85),
//                       blurRadius: 2,
//                       offset: const Offset(0, 1),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 18),
//         Row(
//           children: [1, 2, 3, 5]
//               .map(
//                 (amt) => Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 4),
//                     child: _glassButton(
//                       label: '+$amt',
//                       onPressed: () => onAdd(amt),
//                     ),
//                   ),
//                 ),
//               )
//               .toList(),
//         ),
//       ],
//     );
//   }

//   Widget _glassButton({
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     final r = BorderRadius.circular(14);
//     return ClipRRect(
//       borderRadius: r,
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: onPressed,
//             borderRadius: r,
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 borderRadius: r,
//                 color: Colors.white.withOpacity(0.55),
//                 border: Border.all(color: primaryBlue.withOpacity(0.22)),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.local_drink_rounded,
//                     size: 18,
//                     color: primaryBlueDeep.withOpacity(0.92),
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     label,
//                     style: TextStyle(
//                       color: primaryBlueDeep,
//                       fontWeight: FontWeight.w700,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'dart:math' as math;

class HydrationTracker extends StatelessWidget {
  final int count;
  final Function(int) onAdd;
  final Color primaryBlue;
  final Color primaryBlueDeep;

  const HydrationTracker({
    super.key,
    required this.count,
    required this.onAdd,
    required this.primaryBlue,
    required this.primaryBlueDeep,
  });

  static const int _goal = 8;

  @override
  Widget build(BuildContext context) {
    final progress = (count / _goal).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon box
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.water_drop_rounded,
                size: 24,
                color: primaryBlueDeep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stay Hydrated',
                    style: TextStyle(
                      color: Color(0xFF1A2744),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Daily goal: $_goal glasses',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Circular progress badge
            _CircularProgressBadge(
              current: count,
              goal: _goal,
              progress: progress,
              color: primaryBlueDeep,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: primaryBlue.withOpacity(0.18),
            valueColor: AlwaysStoppedAnimation<Color>(primaryBlueDeep),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [1, 2, 3, 5]
              .map(
                (amt) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _glassButton(
                      label: '+$amt',
                      onPressed: () => onAdd(amt),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _glassButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    final r = BorderRadius.circular(14);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: r,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: r,
                color: Colors.white.withOpacity(0.55),
                border: Border.all(color: primaryBlue.withOpacity(0.22)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    size: 16,
                    color: primaryBlueDeep.withOpacity(0.92),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: primaryBlueDeep,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularProgressBadge extends StatelessWidget {
  final int current;
  final int goal;
  final double progress;
  final Color color;

  const _CircularProgressBadge({
    required this.current,
    required this.goal,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: CustomPaint(
        painter: _ArcPainter(progress: progress, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$current',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  height: 1,
                ),
              ),
              Text(
                '$goal',
                style: TextStyle(
                  color: color.withOpacity(0.5),
                  fontSize: 10,
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
    const strokeWidth = 4.5;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

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
