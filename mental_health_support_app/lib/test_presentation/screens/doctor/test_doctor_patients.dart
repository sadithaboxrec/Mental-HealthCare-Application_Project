import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/appointment.dart';
import '../../../core/controllers/doctor_controller.dart';
import '../../components/test_section_title.dart';
import 'test_patient_detail.dart';
import 'test_patient_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestDoctorPatients extends StatefulWidget {
  final AppUser user;
  const TestDoctorPatients({super.key, required this.user});

  @override
  State<TestDoctorPatients> createState() => _TestDoctorPatientsState();
}

class _TestDoctorPatientsState extends State<TestDoctorPatients> {
  List<Map<String,dynamic>> _patients = [];
  // Cache next appointment per patient
  Map<String, Appointment?> _nextApts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final patients =
      await DoctorController.getAllPatients(widget.user.uid);

      // Fetch next appointment for each patient
      final Map<String, Appointment?> apts = {};
      for (final p in patients) {
        final uid = p['uid'] as String? ?? '';
        if (uid.isNotEmpty) {
          try {
            final snap = await _nextApt(uid);
            apts[uid] = snap;
          } catch (_) {
            apts[uid] = null;
          }
        }
      }

      if (mounted) setState(() {
        _patients = patients;
        _nextApts = apts;
        _loading  = false;
      });
    } catch (e) {
      debugPrint('Patients list error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Appointment?> _nextApt(String patientUid) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    // import 'package:cloud_firestore/cloud_firestore.dart';
    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('patientUid', isEqualTo: patientUid)
        .where('date', isGreaterThanOrEqualTo: todayStr)
        .where('status', whereIn: ['scheduled','rescheduled'])
        .orderBy('date')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Appointment.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('All Patients (${_patients.length})'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
          ? const Center(child: Text('No patients assigned yet',
          style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _patients.length,
        itemBuilder: (ctx, i) {
          final p    = _patients[i];
          final uid  = p['uid']  as String? ?? '';
          final name = p['name'] as String? ?? '';
          final apt  = _nextApts[uid];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(p['email'] ?? '',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    )),
                  ]),

                  // Next appointment
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:        apt != null
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today,
                          size: 13,
                          color: apt != null
                              ? Colors.blue : Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        apt != null
                            ? 'Next: ${apt.date} at ${apt.time}'
                            : 'No upcoming appointment',
                        style: TextStyle(
                            fontSize: 12,
                            color: apt != null
                                ? Colors.blue.shade700
                                : Colors.grey),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      icon: const Icon(Icons.bar_chart, size: 14),
                      label: const Text('Analytics',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(
                        builder: (_) => TestPatientAnalytics(
                          doctorUser:  widget.user,
                          patientUid:  uid,
                          patientName: name,
                        ),
                      )),
                    )),
                    const SizedBox(width: 6),
                    Expanded(child: ElevatedButton.icon(
                      icon: const Icon(Icons.medication, size: 14),
                      label: const Text('Prescribe',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white),
                      onPressed: () async {
                        await Navigator.push(
                            context, MaterialPageRoute(
                          builder: (_) => TestPatientDetail(
                            doctorUser:  widget.user,
                            patientUid:  uid,
                            patientName: name,
                          ),
                        ));
                        _load();
                      },
                    )),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}