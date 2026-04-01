import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/appointment.dart';
import '../../components/test_section_title.dart';
import 'test_patient_detail.dart';
import 'test_patient_analytics.dart';

class TestDoctorSchedule extends StatefulWidget {
  final AppUser user;
  const TestDoctorSchedule({super.key, required this.user});

  @override
  State<TestDoctorSchedule> createState() => _TestDoctorScheduleState();
}

class _TestDoctorScheduleState extends State<TestDoctorSchedule> {
  DateTime         _selectedDate = DateTime.now();
  List<Appointment> _appointments = [];
  bool             _loading      = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorUid', isEqualTo: widget.user.uid)
          .where('date', isEqualTo: _fmt(_selectedDate))
          .orderBy('time')
          .get();
      if (mounted) setState(() {
        _appointments = snap.docs
            .map((d) => Appointment.fromMap(
            d.id, d.data()))
            .toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Schedule load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate:   DateTime.now().subtract(const Duration(days: 365)),
      lastDate:    DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Date picker bar
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: Row(children: [
                const Icon(Icons.calendar_today,
                    color: Colors.blue, size: 20),
                const SizedBox(width: 10),
                Text(_fmt(_selectedDate),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Text('Tap to change',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _appointments.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_available,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text('No appointments on ${_fmt(_selectedDate)}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _appointments.length,
              itemBuilder: (ctx, i) {
                final apt = _appointments[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      _statusColor(apt.status).withOpacity(0.1),
                      child: Text(apt.time.substring(0,5),
                          style: TextStyle(
                              color:    _statusColor(apt.status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(apt.patientName),
                    subtitle: Text(apt.status.toUpperCase(),
                        style: TextStyle(
                            color:    _statusColor(apt.status),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    trailing: Row(mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.bar_chart,
                              color: Colors.teal, size: 20),
                          onPressed: () => Navigator.push(
                              context, MaterialPageRoute(
                            builder: (_) => TestPatientAnalytics(
                              doctorUser:  widget.user,
                              patientUid:  apt.patientUid,
                              patientName: apt.patientName,
                            ),
                          )),
                        ),
                        IconButton(
                          icon: const Icon(Icons.medication,
                              color: Colors.blue, size: 20),
                          onPressed: () => Navigator.push(
                              context, MaterialPageRoute(
                            builder: (_) => TestPatientDetail(
                              doctorUser:  widget.user,
                              patientUid:  apt.patientUid,
                              patientName: apt.patientName,
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':   return Colors.green;
      case 'absent':      return Colors.red;
      case 'rescheduled': return Colors.orange;
      default:            return Colors.blue;
    }
  }
}