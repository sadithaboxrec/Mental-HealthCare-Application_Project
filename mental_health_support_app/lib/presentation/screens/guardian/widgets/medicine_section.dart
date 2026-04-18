import 'package:flutter/material.dart';
import '../../../../core/models/prescription.dart';
import '../../../components/section_title.dart';
import 'common_card.dart';

class MedicineSection extends StatelessWidget {
  final Prescription? prescription;

  const MedicineSection({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    final meds = prescription?.medicines ?? [];

    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Patient Medicines', subtitle: "Today's prescription"),

          const SizedBox(height: 10),

          if (meds.isEmpty)
            const Text('No active prescription', style: TextStyle(color: Colors.grey))
          else
            ...meds.map((med) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDEEDFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBDD7F8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.medication, color: Color(0xFF4A90D9)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(med.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text(med.dose, style: const TextStyle(color: Colors.grey)),
                  ]),

                  const SizedBox(height: 6),

                  Wrap(
                    spacing: 6,
                    children: [
                      if (med.morning)   _chip('Morning',   Icons.wb_sunny,    Colors.orange),
                      if (med.afternoon) _chip('Afternoon', Icons.wb_cloudy,   Colors.blue),
                      if (med.night)     _chip('Night',     Icons.nights_stay, Colors.indigo),
                      _chip(
                        med.beforeMeal ? 'Before Meal' : 'After Meal',
                        Icons.restaurant, Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _chip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
//end of file mishara