import 'package:flutter/material.dart';
import '../../../../core/models/appointment.dart';
import '../../../components/section_title.dart';
import 'common_card.dart';

class AppointmentSection extends StatelessWidget {
  final Appointment? appointment;

  const AppointmentSection({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Next Appointment', subtitle: 'Upcoming visit'),

          const SizedBox(height: 10),

          if (appointment == null)
            const Text('No upcoming appointment', style: TextStyle(color: Colors.grey))
          else
            Row(children: [
              const Icon(Icons.calendar_month, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment!.date,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${appointment!.time} • ${appointment!.status}',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ]),
        ],
      ),
    );
  }
}
//end of file mishara