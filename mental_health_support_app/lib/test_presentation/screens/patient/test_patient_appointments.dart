// import 'package:flutter/material.dart';
// import '../../../core/models/app_user.dart';
// import '../../../core/models/appointment.dart';
// import '../../../core/controllers/patient_controller.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../components/test_section_title.dart';
//
// class TestPatientAppointments extends StatefulWidget {
//   final AppUser user;
//   const TestPatientAppointments({super.key, required this.user});
//
//   @override
//   State<TestPatientAppointments> createState() =>
//       _TestPatientAppointmentsState();
// }
//
// class _TestPatientAppointmentsState
//     extends State<TestPatientAppointments> {
//   Appointment?       _next;
//   List<Appointment>  _past     = [];
//   bool               _loading  = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }
//
//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       final today = DateTime.now();
//       final todayStr =
//           '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
//
//       final results = await Future.wait([
//         PatientController.getNextAppointment(widget.user.uid),
//         // Past appointments
//         FirebaseFirestore.instance
//             .collection('appointments')
//             .where('patientUid', isEqualTo: widget.user.uid)
//             .where('date', isLessThan: todayStr)
//             .orderBy('date', descending: true)
//             .get(),
//       ]);
//
//       if (mounted) setState(() {
//         _next    = results[0] as Appointment?;
//         final snap = results[1] as QuerySnapshot;
//         _past    = snap.docs
//             .map((d) => Appointment.fromMap(
//             d.id, d.data() as Map<String,dynamic>))
//             .toList();
//         _loading = false;
//       });
//     } catch (e) {
//       debugPrint('Appointments load error: $e');
//       if (mounted) setState(() => _loading = false);
//     }
//   }
//
//   Future<void> _requestReschedule() async {
//     if (_next == null) return;
//
//     final reasonCtrl = TextEditingController();
//     String? newDate;
//
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now().add(const Duration(days: 1)),
//       firstDate:   DateTime.now(),
//       lastDate:    DateTime.now().add(const Duration(days: 365)),
//     );
//     if (picked == null) return;
//     newDate =
//     '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
//
//     if (!mounted) return;
//     await showDialog(context: context, builder: (ctx) => AlertDialog(
//       title: const Text('Reason (Optional)'),
//       content: TextField(
//         controller: reasonCtrl,
//         decoration: const InputDecoration(
//             hintText: 'Why do you need to reschedule?'),
//       ),
//       actions: [
//         TextButton(onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel')),
//         ElevatedButton(
//           onPressed: () => Navigator.pop(ctx),
//           child: const Text('Submit'),
//         ),
//       ],
//     ));
//
//     await PatientController.requestReschedule(
//       patientUid:    widget.user.uid,
//       doctorUid:     _next!.doctorUid,
//       appointmentId: _next!.id,
//       requestedDate: newDate,
//       reason:        reasonCtrl.text.trim(),
//     );
//
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Reschedule request sent to doctor')));
//       _load();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         title: const Text('Appointments'),
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//         automaticallyImplyLeading: false,
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//
//           // ── Next Appointment ──────────────────
//           const TestSectionTitle(title: '📅 Next Appointment'),
//           if (_next != null) ...[
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color:        Colors.green.shade50,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.green.shade300),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(children: [
//                     const Icon(Icons.calendar_today,
//                         color: Colors.green, size: 18),
//                     const SizedBox(width: 8),
//                     Text(_next!.date,
//                         style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16)),
//                   ]),
//                   const SizedBox(height: 6),
//                   Text('Time: ${_next!.time}'),
//                   const SizedBox(height: 4),
//                   _statusBadge(_next!.status),
//                   const SizedBox(height: 12),
//                   // Hospital placeholder
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color:        Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Row(children: [
//                       Icon(Icons.local_hospital,
//                           color: Colors.grey, size: 16),
//                       SizedBox(width: 8),
//                       Text('Hospital details here',
//                           style: TextStyle(
//                               color: Colors.grey, fontSize: 12)),
//                     ]),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 8),
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton.icon(
//                 icon: const Icon(Icons.schedule),
//                 label: const Text('Request Reschedule'),
//                 onPressed: _requestReschedule,
//                 style: OutlinedButton.styleFrom(
//                     foregroundColor: Colors.orange),
//               ),
//             ),
//           ] else
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color:        Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: const Text('No upcoming appointment',
//                   style: TextStyle(color: Colors.grey)),
//             ),
//
//           const SizedBox(height: 24),
//
//           // ── Past Appointments ─────────────────
//           const TestSectionTitle(title: '📋 Past Appointments'),
//           if (_past.isEmpty)
//             const Text('No past appointments',
//                 style: TextStyle(color: Colors.grey))
//           else
//             ..._past.map((apt) => Container(
//               margin: const EdgeInsets.only(bottom: 8),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color:        Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey.shade200),
//               ),
//               child: Row(children: [
//                 Expanded(child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(apt.date,
//                         style: const TextStyle(
//                             fontWeight: FontWeight.bold)),
//                     Text('Time: ${apt.time}',
//                         style: const TextStyle(fontSize: 12)),
//                   ],
//                 )),
//                 _statusBadge(apt.status),
//               ]),
//             )),
//
//           const SizedBox(height: 32),
//         ],
//       ),
//     );
//   }
//
//   Widget _statusBadge(String status) {
//     Color color;
//     switch (status) {
//       case 'completed':   color = Colors.green;  break;
//       case 'absent':      color = Colors.red;    break;
//       case 'rescheduled': color = Colors.orange; break;
//       default:            color = Colors.blue;
//     }
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//       decoration: BoxDecoration(
//         color:        color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(6),
//         border:       Border.all(color: color.withOpacity(0.4)),
//       ),
//       child: Text(status.toUpperCase(),
//           style: TextStyle(
//               color:      color,
//               fontSize:   10,
//               fontWeight: FontWeight.bold)),
//     );
//   }
// }

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/appointment.dart';
import '../../../core/controllers/patient_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../presentation/components2/section_title.dart';

class TestPatientAppointments extends StatefulWidget {
  final AppUser user;
  const TestPatientAppointments({super.key, required this.user});

  @override
  State<TestPatientAppointments> createState() =>
      _TestPatientAppointmentsState();
}

class _TestPatientAppointmentsState extends State<TestPatientAppointments> {
  Appointment? _next;
  List<Appointment> _past = [];
  bool _loading = true;

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
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        PatientController.getNextAppointment(widget.user.uid),
        FirebaseFirestore.instance
            .collection('appointments')
            .where('patientUid', isEqualTo: widget.user.uid)
            .where('date', isLessThan: todayStr)
            .orderBy('date', descending: true)
            .get(),
      ]);

      if (mounted) {
        setState(() {
          _next = results[0] as Appointment?;
          final snap = results[1] as QuerySnapshot;
          _past = snap.docs
              .map(
                (d) =>
                    Appointment.fromMap(d.id, d.data() as Map<String, dynamic>),
              )
              .toList();
          _loading = false;
        });
      }
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
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    newDate =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reason (Optional)'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            hintText: 'Why do you need to reschedule?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    await PatientController.requestReschedule(
      patientUid: widget.user.uid,
      doctorUid: _next!.doctorUid,
      appointmentId: _next!.id,
      requestedDate: newDate,
      reason: reasonCtrl.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reschedule request sent to doctor')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: Colors.white.withOpacity(0.82),
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF0F4FA)],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionContainer(
                    highlighted: true,
                    child: Column(
                      children: [
                        _sectionCard(
                          child: const Row(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: Color(0xFF5DADE3),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: SectionTitle(title: 'Next Appointment'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_next != null) ...[
                          _glassCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Color(0xFF5DADE3),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _next!.date,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Spacer(),
                                      _statusBadge(_next!.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 15,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 6),
                                      Text('Time: ${_next!.time}'),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.72),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.local_hospital,
                                          color: Colors.black54,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Colombo National Hospital',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.schedule),
                              label: const Text('Request Reschedule'),
                              onPressed: _requestReschedule,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF5DADE3),
                                side: const BorderSide(
                                  color: Color(0xFF5DADE3),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ] else
                          _glassCard(
                            child: const Padding(
                              padding: EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event_busy_outlined,
                                    color: Colors.black54,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'No upcoming appointment',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _sectionContainer(
                    highlighted: false,
                    child: Column(
                      children: [
                        _sectionCard(
                          child: const Row(
                            children: [
                              Icon(
                                Icons.history,
                                color: Color(0xFF5DADE3),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: SectionTitle(title: 'Past Appointments'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_past.isEmpty)
                          _glassCard(
                            child: const Padding(
                              padding: EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.folder_open,
                                    color: Colors.black54,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'No past appointments',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._past.map(
                            (apt) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _glassCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              apt.date,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Time: ${apt.time}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _statusBadge(apt.status),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: child,
      ),
    );
  }

  Widget _sectionContainer({required Widget child, required bool highlighted}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFF5DADE3).withOpacity(0.12)
            : Colors.black.withOpacity(0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF5DADE3).withOpacity(0.25)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: child,
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.88)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'scheduled':
        color = const Color(0xFF1E88E5);
        break;
      case 'completed':
        color = const Color(0xFF2E7D32);
        break;
      case 'cancelled':
        color = const Color(0xFFE53935);
        break;
      case 'rescheduled':
        color = const Color(0xFFFF9800);
        break;
      case 'absent':
        color = const Color(0xFF8E24AA);
        break;
      default:
        color = const Color(0xFF1E88E5);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
