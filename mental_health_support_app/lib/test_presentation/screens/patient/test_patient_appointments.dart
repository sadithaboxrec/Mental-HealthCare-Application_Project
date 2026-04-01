import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/appointment.dart';
import '../../../core/controllers/patient_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../components/test_section_title.dart';

class TestPatientAppointments extends StatefulWidget {
  final AppUser user;
  const TestPatientAppointments({super.key, required this.user});

  @override
  State<TestPatientAppointments> createState() =>
      _TestPatientAppointmentsState();
}

class _TestPatientAppointmentsState
    extends State<TestPatientAppointments> {
  Appointment?       _next;
  List<Appointment>  _past     = [];
  bool               _loading  = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';

      final results = await Future.wait([
        PatientController.getNextAppointment(widget.user.uid),
        // Past appointments
        FirebaseFirestore.instance
            .collection('appointments')
            .where('patientUid', isEqualTo: widget.user.uid)
            .where('date', isLessThan: todayStr)
            .orderBy('date', descending: true)
            .get(),
      ]);

      if (mounted) setState(() {
        _next    = results[0] as Appointment?;
        final snap = results[1] as QuerySnapshot;
        _past    = snap.docs
            .map((d) => Appointment.fromMap(
            d.id, d.data() as Map<String,dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Appointments load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestReschedule() async {
    if (_next == null) return;

    final reasonCtrl = TextEditingController();
    String? newDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    newDate =
    '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';

    if (!mounted) return;
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Reason (Optional)'),
      content: TextField(
        controller: reasonCtrl,
        decoration: const InputDecoration(
            hintText: 'Why do you need to reschedule?'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Submit'),
        ),
      ],
    ));

    await PatientController.requestReschedule(
      patientUid:    widget.user.uid,
      doctorUid:     _next!.doctorUid,
      appointmentId: _next!.id,
      requestedDate: newDate,
      reason:        reasonCtrl.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reschedule request sent to doctor')));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Next Appointment ──────────────────
          const TestSectionTitle(title: '📅 Next Appointment'),
          if (_next != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(_next!.date,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ]),
                  const SizedBox(height: 6),
                  Text('Time: ${_next!.time}'),
                  const SizedBox(height: 4),
                  _statusBadge(_next!.status),
                  const SizedBox(height: 12),
                  // Hospital placeholder
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(children: [
                      Icon(Icons.local_hospital,
                          color: Colors.grey, size: 16),
                      SizedBox(width: 8),
                      Text('Hospital details here',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.schedule),
                label: const Text('Request Reschedule'),
                onPressed: _requestReschedule,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text('No upcoming appointment',
                  style: TextStyle(color: Colors.grey)),
            ),

          const SizedBox(height: 24),

          // ── Past Appointments ─────────────────
          const TestSectionTitle(title: '📋 Past Appointments'),
          if (_past.isEmpty)
            const Text('No past appointments',
                style: TextStyle(color: Colors.grey))
          else
            ..._past.map((apt) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(apt.date,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    Text('Time: ${apt.time}',
                        style: const TextStyle(fontSize: 12)),
                  ],
                )),
                _statusBadge(apt.status),
              ]),
            )),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'completed':   color = Colors.green;  break;
      case 'absent':      color = Colors.red;    break;
      case 'rescheduled': color = Colors.orange; break;
      default:            color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color:      color,
              fontSize:   10,
              fontWeight: FontWeight.bold)),
    );
  }
}