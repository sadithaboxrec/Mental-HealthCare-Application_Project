// import 'package:flutter/material.dart';
// import '../../../core/models/app_user.dart';
// import '../../../core/models/appointment.dart';
// import '../../../core/models/reschedule_request.dart';
// import '../../../core/controllers/auth_controller.dart';
// import '../../../core/controllers/doctor_controller.dart';
// import '../../../core/navigation/navigation_helper.dart';
// import '../../components/test_button.dart';
// import 'test_patient_detail.dart';
//
// class TestDoctorHome extends StatefulWidget {
//   final AppUser user;
//   const TestDoctorHome({super.key, required this.user});
//
//   @override
//   State<TestDoctorHome> createState() => _TestDoctorHomeState();
// }
//
// class _TestDoctorHomeState extends State<TestDoctorHome> {
//   List<Map<String, dynamic>> _newPatients       = [];
//   List<Appointment>          _todayAppointments  = [];
//   List<RescheduleRequest>    _rescheduleRequests = [];
//   bool _loading = true;
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
//       final results = await Future.wait([
//         DoctorController.getNewPatients(widget.user.uid),
//         DoctorController.getTodayAppointments(widget.user.uid),
//         DoctorController.getPendingReschedules(widget.user.uid),
//       ]);
//       if (mounted) setState(() {
//         _newPatients       = results[0] as List<Map<String, dynamic>>;
//         _todayAppointments  = results[1] as List<Appointment>;
//         _rescheduleRequests = results[2] as List<RescheduleRequest>;
//         _loading           = false;
//       });
//     } catch (e) {
//       debugPrint('Doctor home load error: $e');
//       if (mounted) setState(() => _loading = false);
//     }
//   }
//
//   Future<void> _goToPatient(
//       String patientUid, String patientName) async {
//     await Navigator.push(context, MaterialPageRoute(
//       builder: (_) => TestPatientDetail(
//         doctorUser:  widget.user,
//         patientUid:  patientUid,
//         patientName: patientName,
//       ),
//     ));
//     _load();
//   }
//
//   Future<void> _handleReschedule(RescheduleRequest req) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now().add(const Duration(days: 1)),
//       firstDate:   DateTime.now(),
//       lastDate:    DateTime.now().add(const Duration(days: 365)),
//     );
//     if (picked == null) return;
//     final newDate =
//         '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
//     await DoctorController.approveReschedule(req, newDate);
//     _load();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         title: Text('[TEST] Dr. ${widget.user.name}'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               await AuthController.logout();
//               if (context.mounted) NavigationHelper.goToLogin(context);
//             },
//           ),
//         ],
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//         onRefresh: _load,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//
//             // ── Reschedule Requests ───────────────
//             if (_rescheduleRequests.isNotEmpty) ...[
//               _tag('Reschedule Requests',
//                   Colors.orange, _rescheduleRequests.length),
//               const SizedBox(height: 8),
//               ..._rescheduleRequests.map((req) => Card(
//                 child: ListTile(
//                   leading: const Icon(Icons.schedule,
//                       color: Colors.orange),
//                   title: Text('Patient requested: ${req.requestedDate}'),
//                   subtitle: Text(req.reason.isEmpty
//                       ? 'No reason given' : req.reason),
//                   trailing: TextButton(
//                     onPressed: () => _handleReschedule(req),
//                     child: const Text('Approve'),
//                   ),
//                 ),
//               )),
//               const SizedBox(height: 16),
//               const Divider(),
//               const SizedBox(height: 8),
//             ],
//
//             // ── New Patients ──────────────────────
//             if (_newPatients.isNotEmpty) ...[
//               _tag('New Patients Assigned',
//                   Colors.green, _newPatients.length),
//               const SizedBox(height: 8),
//               ..._newPatients.map((p) => Card(
//                 child: ListTile(
//                   leading: const CircleAvatar(
//                     backgroundColor: Colors.green,
//                     child: Icon(Icons.person_add,
//                         color: Colors.white, size: 18),
//                   ),
//                   title: Text(p['name'] ?? ''),
//                   subtitle: Text(p['email'] ?? ''),
//                   trailing: const Chip(
//                     label: Text('New',
//                         style: TextStyle(fontSize: 11)),
//                     backgroundColor: Color(0xFFE8F5E9),
//                   ),
//                   onTap: () => _goToPatient(
//                       p['uid'] ?? '', p['name'] ?? ''),
//                 ),
//               )),
//               const SizedBox(height: 16),
//               const Divider(),
//               const SizedBox(height: 8),
//             ],
//
//             // ── Today's Appointments ──────────────
//             _tag("Today's Appointments",
//                 Colors.blue, _todayAppointments.length),
//             const SizedBox(height: 8),
//
//             if (_todayAppointments.isEmpty)
//               const Center(
//                 child: Padding(
//                   padding: EdgeInsets.all(24),
//                   child: Text('No appointments today',
//                       style: TextStyle(color: Colors.grey)),
//                 ),
//               )
//             else
//               ..._todayAppointments.map((apt) => Card(
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: _statusColor(apt.status),
//                     child: const Icon(Icons.access_time,
//                         color: Colors.white, size: 18),
//                   ),
//                   title: Text(apt.patientName),
//                   subtitle: Text(
//                       '${apt.time}  •  ${apt.status.toUpperCase()}'),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.check_circle,
//                             color: Colors.green),
//                         tooltip: 'Mark Completed',
//                         onPressed: () async {
//                           await DoctorController
//                               .markCompleted(apt.id);
//                           _load();
//                         },
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.cancel,
//                             color: Colors.red),
//                         tooltip: 'Mark Absent',
//                         onPressed: () async {
//                           await DoctorController.markAbsent(apt.id);
//                           _load();
//                         },
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.edit,
//                             color: Colors.blue),
//                         tooltip: 'Open',
//                         onPressed: () => _goToPatient(
//                             apt.patientUid, apt.patientName),
//                       ),
//                     ],
//                   ),
//                 ),
//               )),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _tag(String label, Color color, int count) => Row(children: [
//     Text(label,
//         style: TextStyle(
//             fontWeight: FontWeight.bold, color: color, fontSize: 14)),
//     const SizedBox(width: 8),
//     CircleAvatar(radius: 10, backgroundColor: color,
//         child: Text('$count',
//             style: const TextStyle(color: Colors.white, fontSize: 10))),
//   ]);
//
//   Color _statusColor(String status) {
//     switch (status) {
//       case 'completed':  return Colors.green;
//       case 'absent':     return Colors.red;
//       case 'rescheduled': return Colors.orange;
//       default:           return Colors.blue;
//     }
//   }
// }


import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/appointment.dart';
import '../../../core/models/reschedule_request.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/controllers/doctor_controller.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../components/test_section_title.dart';
import 'test_patient_detail.dart';
import 'test_patient_analytics.dart';

class TestDoctorHome extends StatefulWidget {
  final AppUser user;
  const TestDoctorHome({super.key, required this.user});

  @override
  State<TestDoctorHome> createState() => _TestDoctorHomeState();
}

class _TestDoctorHomeState extends State<TestDoctorHome> {
  List<Map<String,dynamic>> _newPatients       = [];
  List<Appointment>         _todayAppointments = [];
  List<RescheduleRequest>   _reschedules       = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        DoctorController.getNewPatients(widget.user.uid),
        DoctorController.getTodayAppointments(widget.user.uid),
        DoctorController.getPendingReschedules(widget.user.uid),
      ]);
      if (mounted) setState(() {
        _newPatients       = results[0] as List<Map<String,dynamic>>;
        _todayAppointments = results[1] as List<Appointment>;
        _reschedules       = results[2] as List<RescheduleRequest>;
        _loading           = false;
      });
    } catch (e) {
      debugPrint('Doctor home error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approveReschedule(RescheduleRequest req) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    final d =
        '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
    await DoctorController.approveReschedule(req, d);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Dr. ${widget.user.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthController.logout();
              if (context.mounted) NavigationHelper.goToLogin(context);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Summary box ───────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.today, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_todayAppointments.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                      const Text('Patients Today',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ]),
                const Spacer(),
                if (_reschedules.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:        Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_reschedules.length} reschedule'
                          '${_reschedules.length > 1 ? "s" : ""}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Reschedule Requests ───────────────
            if (_reschedules.isNotEmpty) ...[
              const TestSectionTitle(title: '🔔 Reschedule Requests'),
              ..._reschedules.map((req) => Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule,
                      color: Colors.orange),
                  title: Text('Requested: ${req.requestedDate}'),
                  subtitle: Text(req.reason.isEmpty
                      ? 'No reason given' : req.reason),
                  trailing: TextButton(
                    onPressed: () => _approveReschedule(req),
                    child: const Text('Approve'),
                  ),
                ),
              )),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
            ],

            // ── New Patients ──────────────────────
            if (_newPatients.isNotEmpty) ...[
              TestSectionTitle(
                title: '🆕 New Patients',
                subtitle: '${_newPatients.length} assigned',
              ),
              ..._newPatients.map((p) => _PatientCard(
                patientUid:   p['uid']  ?? '',
                patientName:  p['name'] ?? '',
                subtitle:     p['email'] ?? '',
                doctorUser:   widget.user,
                isNew:        true,
                onRefresh:    _load,
              )),
              const Divider(),
              const SizedBox(height: 8),
            ],

            // ── Today's Appointments ──────────────
            TestSectionTitle(
              title: "📋 Today's Appointments",
              subtitle: '${_todayAppointments.length} scheduled',
            ),
            if (_todayAppointments.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No appointments today',
                      style: TextStyle(color: Colors.grey))))
            else
              ..._todayAppointments.map((apt) => _PatientCard(
                patientUid:  apt.patientUid,
                patientName: apt.patientName,
                subtitle:    '${apt.time} • ${apt.status.toUpperCase()}',
                doctorUser:  widget.user,
                isNew:       false,
                onRefresh:   _load,
                appointmentId: apt.id,
                appointmentStatus: apt.status,
              )),
          ],
        ),
      ),
    );
  }
}


// ── Patient Card ──────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final String   patientUid;
  final String   patientName;
  final String   subtitle;
  final AppUser  doctorUser;
  final bool     isNew;
  final VoidCallback onRefresh;
  final String?  appointmentId;
  final String?  appointmentStatus;

  const _PatientCard({
    required this.patientUid,
    required this.patientName,
    required this.subtitle,
    required this.doctorUser,
    required this.isNew,
    required this.onRefresh,
    this.appointmentId,
    this.appointmentStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor:
                isNew ? Colors.green.shade100 : Colors.blue.shade100,
                child: Icon(Icons.person,
                    color: isNew ? Colors.green : Colors.blue, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              )),
              if (isNew)
                const Chip(
                  label: Text('NEW',
                      style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  backgroundColor: Color(0xFFE8F5E9),
                  padding: EdgeInsets.zero,
                ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              // Analytics
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.bar_chart, size: 14),
                label: const Text('Analytics', style: TextStyle(fontSize: 12)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TestPatientAnalytics(
                    doctorUser:  doctorUser,
                    patientUid:  patientUid,
                    patientName: patientName,
                  ),
                )),
              )),
              const SizedBox(width: 6),
              // Prescription
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.medication, size: 14),
                label: const Text('Prescribe',
                    style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TestPatientDetail(
                      doctorUser:  doctorUser,
                      patientUid:  patientUid,
                      patientName: patientName,
                    ),
                  ));
                  onRefresh();
                },
              )),
              // Mark Absent
              if (appointmentId != null &&
                  appointmentStatus == 'scheduled') ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.person_off,
                      color: Colors.red, size: 20),
                  tooltip: 'Mark Absent',
                  onPressed: () async {
                    await DoctorController.markAbsent(appointmentId!);
                    onRefresh();
                  },
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}