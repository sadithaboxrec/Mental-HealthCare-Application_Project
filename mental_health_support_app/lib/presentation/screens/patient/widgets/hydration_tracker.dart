import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import '../../../components2/section_title.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 10),
              child: Icon(
                Icons.water_drop_rounded,
                size: 34,
                color: primaryBlueDeep,
              ),
            ),
            const Expanded(
              child: SectionTitle(
                title: 'Stay Hydrated',
                subtitle: 'Daily Goal: 8 Glasses',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryBlue.withOpacity(0.45),
                    primaryBlueDeep.withOpacity(0.35),
                  ],
                ),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlueDeep.withOpacity(0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.9),
                    blurRadius: 0,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: primaryBlueDeep,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  height: 1,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: Colors.white.withOpacity(0.85),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
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
                    Icons.local_drink_rounded,
                    size: 18,
                    color: primaryBlueDeep.withOpacity(0.92),
                  ),
                  const SizedBox(width: 6),
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
