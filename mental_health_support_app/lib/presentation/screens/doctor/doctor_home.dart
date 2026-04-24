import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/appointment.dart';
import '../../../core/models/reschedule_request.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/controllers/doctor_controller.dart';
import '../../../core/navigation/navigation_helper.dart';
import 'patient_detail.dart';
// import 'patient_analytics.dart';
import 'doctor_analytics.dart';
import '../../components/app_button.dart';
import '../../components/section_title.dart';
import '../../components/app_text_field.dart';

class DoctorHome extends StatefulWidget {
  final AppUser user;
  const DoctorHome({super.key, required this.user});
 
  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}
 
class _DoctorHomeState extends State<DoctorHome> {
  List<Map<String, dynamic>> _newPatients      = [];
  List<Appointment>          _todayAppointments = [];
  List<Appointment>          _emergencyPatients = [];
  List<RescheduleRequest>    _reschedules       = [];
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
 
      if (mounted) {
        final allAppointments = results[1] as List<Appointment>;
 
        setState(() {
          _newPatients       = results[0] as List<Map<String, dynamic>>;
          _todayAppointments = allAppointments
              .where((a) => !a.status.toLowerCase().contains('emergency'))
              .toList();
          _emergencyPatients = allAppointments
              .where((a) => a.status.toLowerCase().contains('emergency'))
              .toList();
          _reschedules = results[2] as List<RescheduleRequest>;
          _loading     = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _loading = false);
    }
  }
 
  // ── Bottom sheet: Emergency patients ──────────────
  void _showEmergencySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.3,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Emergency Patients',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const Divider(height: 24),
              Expanded(
                child: _emergencyPatients.isEmpty
                    ? const Center(
                        child: Text('No emergency patients right now', style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _emergencyPatients.length,
                        itemBuilder: (_, i) {
                          final apt = _emergencyPatients[i];
                          return _PatientCard(
                            patientUid:    apt.patientUid,
                            patientName:   apt.patientName,
                            subtitle:      '${apt.time} • ${apt.status}',
                            doctorUser:    widget.user,
                            onRefresh:     _load,
                            appointmentId: apt.id,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  // ── Bottom sheet: All today's appointments ─────────
  void _showAppointmentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Today's Appointments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              Expanded(
                child: _todayAppointments.isEmpty
                    ? const Center(
                        child: Text('No appointments today', style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _todayAppointments.length,
                        itemBuilder: (_, i) {
                          final apt = _todayAppointments[i];
                          return _PatientCard(
                            patientUid:    apt.patientUid,
                            patientName:   apt.patientName,
                            subtitle:      '${apt.time} • ${apt.status}',
                            doctorUser:    widget.user,
                            onRefresh:     _load,
                            appointmentId: apt.id,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(""),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await AuthController.logout();
              if (context.mounted) NavigationHelper.goToLogin(context);
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
 
                  // ── Header ───────────────────────────
                  Text("hey ! Dr.",
                      style: TextStyle(fontSize: 20, color: const Color.fromARGB(255, 17, 17, 17))),
                  Text(widget.user.name,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    "Your sanctuary for patient care and data insights.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
 
                  // ── Emergency card (TAPPABLE) ─────────
                  GestureDetector(
                    onTap: _showEmergencySheet,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5D6D6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${_emergencyPatients.length} Emergency Cases",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text("Need your immediate attention", style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                        ],
                      ),
                    ),
                  ),




// adding to get the new patients who are assigned by the administration


                  // ── New Patients
                  if (_newPatients.isNotEmpty) ...[
                    const Text(
                      "New Patients",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    ..._newPatients.map((p) => _PatientCard(
                      patientUid:  p['uid'] ?? '',
                      patientName: p['name'] ?? 'Unknown',
                      subtitle:    p['email'] ?? 'No email',
                      doctorUser:  widget.user,
                      onRefresh:   _load,

                      // against the defined isNew false in constructor
                      isNew:       true,
                    )),

                    const SizedBox(height: 20),
                  ],


 
                  const SizedBox(height: 16),
 
                  // ── Today appointments card (TAPPABLE) ─
                  GestureDetector(
                    onTap: _showAppointmentsSheet,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCE6F1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Today"),
                              Text(
                                "${_todayAppointments.length}",
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              const Text("Appointments"),
                            ],
                          ),
                          Row(
                            children: const [
                              Icon(Icons.calendar_month, size: 40),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blueGrey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
 
                  const SizedBox(height: 20),
 
                  // ── Patient condition (static) ─────────
                  const Text("Patients Condition",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE6F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        _ConditionBox("18", "STABLE",   Colors.green),
                        _ConditionBox("5",  "WARNING",  Colors.orange),
                        _ConditionBox("3",  "CRITICAL", Colors.red),
                      ],
                    ),
                  ),
 
                  const SizedBox(height: 20),
 
                  // ── Reschedule requests ───────────────
                  if (_reschedules.isNotEmpty) ...[
                    const Text("Reschedule Requests",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._reschedules.map((req) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.schedule, color: Colors.orange),
                            title: Text("Requested: ${req.requestedDate}"),
                            subtitle: Text(req.reason.isEmpty ? "No reason" : req.reason),
                            trailing: TextButton(
                              onPressed: () async {
                                await DoctorController.approveReschedule(req, req.requestedDate);
                                _load();
                              },
                              child: const Text("Approve"),
                            ),
                          ),
                        )),
                  ],
 
                  const SizedBox(height: 10),
 
                  // ── Today's appointment list ──────────
                  const Text("Today's Appointments",
                      style: TextStyle(fontWeight: FontWeight.bold)),
 
                  if (_todayAppointments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text("No appointments")),
                    )
                  else
                    ..._todayAppointments.map((apt) => _PatientCard(
                          patientUid:    apt.patientUid,
                          patientName:   apt.patientName,
                          subtitle:      "${apt.time} • ${apt.status}",
                          doctorUser:    widget.user,
                          onRefresh:     _load,
                          appointmentId: apt.id,
                        )),
                ],
              ),
            ),
    );
  }
}
 
// ── Condition box ─────────────────────────────────────
class _ConditionBox extends StatelessWidget {
  final String count;
  final String label;
  final Color  color;
 
  const _ConditionBox(this.count, this.label, this.color);
 
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(height: 6),
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
 
// ── Patient card ──────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final String    patientUid;
  final String    patientName;
  final String    subtitle;
  final AppUser   doctorUser;
  final VoidCallback onRefresh;
  final String?   appointmentId;

// for get newly assigned patients
  final bool isNew;

 
  const _PatientCard({
    required this.patientUid,
    required this.patientName,
    required this.subtitle,
    required this.doctorUser,
    required this.onRefresh,
    this.appointmentId,


    // for get newly assigned patients
    this.isNew = false,
  });
 
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
 
            // Row(
            //   children: [
            //     const CircleAvatar(radius: 20, child: Icon(Icons.person, size: 20)),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Text(patientName,
            //               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            //           Text(subtitle,
            //               style: const TextStyle(fontSize: 12, color: Colors.grey)),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),


    // adding for newly assigned patients
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isNew ? Colors.green.shade100 : null,
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: isNew ? Colors.green : null,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(subtitle,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),

                if (isNew)
                  const Chip(
                    label: Text("NEW",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    backgroundColor: Color(0xFFE8F5E9),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),



            const SizedBox(height: 12),
 
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.bar_chart, size: 16),
                      label: const Text("Analytics", style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PatientAnalytics(
                            doctorUser:  doctorUser,
                            patientUid:  patientUid,
                            patientName: patientName,
                          ),
                        ));
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.medication, size: 16),
                      label: const Text("Prescribe", style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4FC3F7),
                        side: const BorderSide(color: Color(0xFF4FC3F7), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PatientDetail(
                            doctorUser:  doctorUser,
                            patientUid:  patientUid,
                            patientName: patientName,
                          ),
                        ));
                        onRefresh();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
 