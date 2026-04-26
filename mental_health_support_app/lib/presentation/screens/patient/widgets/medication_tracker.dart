// import 'package:flutter/material.dart';

// class MedicationTracker extends StatelessWidget {
//   final bool? medicationTaken;
//   final Function(bool) onToggle;
//   final Color primaryBlueDeep;

//   const MedicationTracker({
//     super.key,
//     required this.medicationTaken,
//     required this.onToggle,
//     required this.primaryBlueDeep,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Icons.medication_rounded, size: 30, color: primaryBlueDeep),
//             const SizedBox(width: 10),
//             const Text(
//               'Have you take your medicines?',
//               style: TextStyle(
//                 color: Color(0xFF1A2744),
//                 fontSize: 18,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 18),
//         Row(
//           children: [
//             _medToggleBtn(true, 'Taken', Icons.done_all, Colors.green),
//             const SizedBox(width: 12),
//             _medToggleBtn(false, 'Missed', Icons.close, Colors.redAccent),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _medToggleBtn(bool taken, String label, IconData icon, Color color) {
//     final active = medicationTaken == taken;
//     return Expanded(
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () => onToggle(taken),
//           borderRadius: BorderRadius.circular(20),
//           splashColor: color.withOpacity(0.12),
//           highlightColor: color.withOpacity(0.08),
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 220),
//             curve: Curves.easeOutCubic,
//             padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
//             decoration: BoxDecoration(
//               color: active ? color : const Color(0xFFF3F6FA),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: active
//                     ? color.withOpacity(0.95)
//                     : const Color(0xFFD8DEE6),
//                 width: active ? 2.0 : 1.25,
//               ),
//               boxShadow: [
//                 if (active)
//                   BoxShadow(
//                     color: color.withOpacity(0.38),
//                     blurRadius: 16,
//                     offset: const Offset(0, 8),
//                   )
//                 else
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.04),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(icon, color: active ? Colors.white : color, size: 22),
//                 const SizedBox(width: 10),
//                 Text(
//                   label,
//                   style: TextStyle(
//                     color: active ? Colors.white : color.withOpacity(0.92),
//                     fontWeight: FontWeight.w800,
//                     fontSize: 16,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class MedicationTracker extends StatelessWidget {
  final bool? medicationTaken;
  final Function(bool) onToggle;
  final Color primaryBlueDeep;

  const MedicationTracker({
    super.key,
    required this.medicationTaken,
    required this.onToggle,
    required this.primaryBlueDeep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with icon box
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: Color(0xFF5C6BC0),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medication',
                    style: TextStyle(
                      color: Color(0xFF1A2744),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Have you taken your medicines today?',
                    style: TextStyle(color: Color(0xFF8896A8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _medToggleBtn(
              true,
              'Taken',
              Icons.check_rounded,
              'All good!',
              const Color(0xFF26A69A),
            ),
            const SizedBox(width: 12),
            _medToggleBtn(
              false,
              'Missed',
              Icons.close_rounded,
              'Take it soon',
              const Color(0xFFEF5350),
            ),
          ],
        ),
      ],
    );
  }

  Widget _medToggleBtn(
    bool taken,
    String label,
    IconData icon,
    String subtitle,
    Color color,
  ) {
    final active = medicationTaken == taken;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onToggle(taken),
          borderRadius: BorderRadius.circular(18),
          splashColor: color.withOpacity(0.12),
          highlightColor: color.withOpacity(0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: active ? color : const Color(0xFFF3F6FA),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active
                    ? color.withOpacity(0.85)
                    : const Color(0xFFE0E6EF),
                width: active ? 1.8 : 1.2,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.35),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? Colors.white.withOpacity(0.25)
                            : color.withOpacity(0.12),
                      ),
                      child: Icon(
                        icon,
                        color: active ? Colors.white : color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: active ? Colors.white : color,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: active
                        ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF8896A8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
