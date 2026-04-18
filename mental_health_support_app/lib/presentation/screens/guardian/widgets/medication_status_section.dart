import 'package:flutter/material.dart';
import 'common_card.dart';

class MedicationStatusSection extends StatelessWidget {
  final bool? taken;
  final bool loading;
  final Function(bool) onToggle;

  const MedicationStatusSection({
    super.key,
    required this.taken,
    required this.loading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90D9).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medical_services_rounded, color: Color(0xFF4A90D9), size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient Take Medicine?',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                Text("Mark today's medication status",
                    style: TextStyle(fontSize: 11, color: Color(0xFF8A8A9A))),
              ],
            ),
          ]),

          const SizedBox(height: 16),

          Row(children: [
            const Expanded(child: Divider(color: Color(0xFFBDD7F8))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('Select status',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade300)),
            ),
            const Expanded(child: Divider(color: Color(0xFFBDD7F8))),
          ]),

          const SizedBox(height: 14),

          Row(children: [
            Expanded(child: _MedButton(
              label: 'Yes, Taken', icon: Icons.check_circle_rounded,
              color: const Color(0xFF2ECC71), selected: taken == true,
              loading: loading, onTap: () => onToggle(true),
            )),
            const SizedBox(width: 12),
            Expanded(child: _MedButton(
              label: 'Not Yet', icon: Icons.cancel_rounded,
              color: const Color(0xFFE74C3C), selected: taken == false,
              loading: loading, onTap: () => onToggle(false),
            )),
          ]),

          if (taken != null) ...[
            const SizedBox(height: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: taken!
                    ? const Color(0xFF2ECC71).withOpacity(0.10)
                    : const Color(0xFFE74C3C).withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: taken!
                      ? const Color(0xFF2ECC71).withOpacity(0.30)
                      : const Color(0xFFE74C3C).withOpacity(0.30),
                ),
              ),
              child: Row(children: [
                Icon(
                  taken! ? Icons.verified_rounded : Icons.info_rounded,
                  size: 16,
                  color: taken! ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    taken!
                        ? 'Great! Medication has been taken today ✓'
                        : 'Reminder: Please give the medication soon.',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: taken! ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _MedButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  const _MedButton({
    required this.label, required this.icon, required this.color,
    required this.selected, required this.loading, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : color.withOpacity(0.30), width: 1.5),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.30), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : color),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : color)),
          ],
        ),
      ),
    );
  }
}
//end of file mishara