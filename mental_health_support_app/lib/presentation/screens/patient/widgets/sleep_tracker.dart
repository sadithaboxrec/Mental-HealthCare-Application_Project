import 'package:flutter/material.dart';
import '../../../components2/section_title.dart';

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

  @override
  Widget build(BuildContext context) {
    final sleepOptions = [
      {'val': 'less5', 'lbl': '< 5h'},
      {'val': '6', 'lbl': '6h'},
      {'val': '7', 'lbl': '7h'},
      {'val': '8', 'lbl': '8h'},
      {'val': 'more8', 'lbl': '8h+'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 10),
              child: Icon(
                Icons.bedtime_rounded,
                size: 34,
                color: primaryBlueDeep,
              ),
            ),
            const Expanded(child: SectionTitle(title: 'Sleep Quality')),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: sleepOptions
                .map((opt) => _sleepChip(opt['val']!, opt['lbl']!))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _sleepChip(String val, String label) {
    bool isSel = selectedSleep == val;
    return GestureDetector(
      onTap: () => onSelect(val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSel
              ? LinearGradient(colors: [primaryBlueDeep, primaryBlue])
              : null,
          color: isSel ? null : Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel
                ? Colors.white.withOpacity(0.55)
                : Colors.white.withOpacity(0.9),
          ),
          boxShadow: [
            if (isSel)
              BoxShadow(
                color: primaryBlueDeep.withOpacity(0.28),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : const Color(0xFF2C3A4D),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
