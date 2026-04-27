// import 'package:flutter/material.dart';
// import '../../../core/models/app_user.dart';
// import '../../../core/controllers/auth_controller.dart';
// import '../../../core/controllers/guardian_controller.dart';
// import '../../../core/navigation/navigation_helper.dart';
// import '../../components/test_button.dart';
// import '../../components/test_section_title.dart';
//
// class TestGuardianHome extends StatefulWidget {
//   final AppUser user;
//   const TestGuardianHome({super.key, required this.user});
//
//   @override
//   State<TestGuardianHome> createState() => _TestGuardianHomeState();
// }
//
// class _TestGuardianHomeState extends State<TestGuardianHome> {
//   String?              _patientUid;
//   Map<String,dynamic>? _todayLog;
//   bool   _loading       = true;
//   int    _selectedMood  = 1;
//   bool   _savingMood    = false;
//   bool   _savingWater   = false;
//   bool   _savingObs     = false;
//   final  _obsCtrl       = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }
//
//   @override
//   void dispose() {
//     _obsCtrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       _patientUid = await GuardianController
//           .getPatientUid(widget.user.uid);
//       _todayLog   = await GuardianController
//           .getTodayLog(widget.user.uid);
//       if (_todayLog != null) {
//         _selectedMood = _todayLog!['mood'] as int? ?? 1;
//         _obsCtrl.text = _todayLog!['observations'] as String? ?? '';
//       }
//     } catch (e) {
//       debugPrint('Guardian load error: $e');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }
//
//   Future<void> _saveMood() async {
//     if (_patientUid == null) return;
//     setState(() => _savingMood = true);
//     await GuardianController.updateMood(
//         widget.user.uid, _patientUid!, _selectedMood);
//     await _load();
//     if (mounted) setState(() => _savingMood = false);
//     _snack('Mood saved');
//   }
//
//   Future<void> _addWater(int glasses) async {
//     if (_patientUid == null) return;
//     setState(() => _savingWater = true);
//     await GuardianController.addWater(
//         widget.user.uid, _patientUid!, glasses);
//     await _load();
//     if (mounted) setState(() => _savingWater = false);
//     _snack('💧 +$glasses glasses added');
//   }
//
//   Future<void> _saveObservations() async {
//     if (_patientUid == null) return;
//     setState(() => _savingObs = true);
//     await GuardianController.updateObservations(
//         widget.user.uid, _patientUid!, _obsCtrl.text.trim());
//     await _load();
//     if (mounted) setState(() => _savingObs = false);
//     _snack('Observations saved');
//   }
//
//   void _snack(String msg) => ScaffoldMessenger.of(context)
//       .showSnackBar(SnackBar(content: Text(msg)));
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         title: Text('[TEST] Guardian — ${widget.user.name}'),
//         backgroundColor: Colors.orange,
//         foregroundColor: Colors.white,
//         actions: [
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
//             if (_patientUid == null)
//               const Center(child: Text('No patient linked.',
//                   style: TextStyle(color: Colors.grey)))
//             else ...[
//
//               // ── Mood ──────────────────────────────
//               TestSectionTitle(
//                 title: 'Patient Mood',
//                 subtitle: 'Today: ${_todayLog != null
//                     ? _moodLabel(_todayLog!['mood'] as int? ?? 0)
//                     : "Not recorded"}',
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: ['😞','😟','😐','🙂','😊']
//                     .asMap().entries.map((e) => GestureDetector(
//                   onTap: () =>
//                       setState(() => _selectedMood = e.key + 1),
//                   child: Text(e.value,
//                       style: TextStyle(
//                           fontSize: _selectedMood == e.key + 1
//                               ? 32 : 22)),
//                 )).toList(),
//               ),
//               const SizedBox(height: 8),
//               TestButton(
//                 label:     'Save Mood',
//                 onPressed: _saveMood,
//                 isLoading: _savingMood,
//                 color:     Colors.orange,
//               ),
//
//               const SizedBox(height: 24),
//
//               // ── Water ─────────────────────────────
//               Row(children: [
//                 const TestSectionTitle(title: '💧 Water'),
//                 const Spacer(),
//                 Text('Today: ${_todayLog?['waterIntake'] ?? 0}g',
//                     style: TextStyle(
//                         color: Colors.blue.shade700,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12)),
//               ]),
//               const SizedBox(height: 8),
//               Row(children: [1,2,3,5].map((g) => Expanded(
//                 child: GestureDetector(
//                   onTap: _savingWater ? null : () => _addWater(g),
//                   child: Container(
//                     margin: const EdgeInsets.only(right: 6),
//                     padding:
//                     const EdgeInsets.symmetric(vertical: 10),
//                     decoration: BoxDecoration(
//                       color:        Colors.blue.shade50,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                           color: Colors.blue.shade200),
//                     ),
//                     child: Text('+$g',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                             color:      Colors.blue.shade700,
//                             fontWeight: FontWeight.bold)),
//                   ),
//                 ),
//               )).toList()),
//
//               const SizedBox(height: 24),
//
//               // ── Observations ──────────────────────
//               const TestSectionTitle(
//                 title: 'Observations',
//                 subtitle: 'Notes about patient behaviour today',
//               ),
//               TextField(
//                 controller: _obsCtrl,
//                 maxLines:   5,
//                 decoration: InputDecoration(
//                   hintText:  'Enter observations...',
//                   filled:    true,
//                   fillColor: Colors.white,
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               TestButton(
//                 label:     'Save Observations',
//                 onPressed: _saveObservations,
//                 isLoading: _savingObs,
//                 color:     Colors.orange,
//               ),
//             ],
//
//             const SizedBox(height: 32),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _moodLabel(int m) {
//     switch (m) {
//       case 1: return 'Worse'; case 2: return 'Bad';
//       case 3: return 'Okay'; case 4: return 'Good';
//       case 5: return 'Happy'; default: return '—';
//     }
//   }
// }



import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/prescription.dart';
import '../../../core/models/appointment.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/controllers/guardian_controller.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../components/test_button.dart';
import '../../components/test_section_title.dart';



// for notifications
import '../../../core/controllers/notification_controller.dart';
import '../../components/test_notification_trigger.dart';


class TestGuardianHome extends StatefulWidget {
  final AppUser user;
  const TestGuardianHome({super.key, required this.user});

  @override
  State<TestGuardianHome> createState() => _TestGuardianHomeState();
}

class _TestGuardianHomeState extends State<TestGuardianHome> {
  String?              _patientUid;
  Map<String,dynamic>? _todayLog;
  Prescription?        _prescription;
  Appointment?         _nextAppointment;
  bool   _loading       = true;
  bool _savingMed = false;
  int    _selectedMood  = 1;
  final  _obsCtrl       = TextEditingController();


  String _patientName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _patientUid = await GuardianController.getPatientUid(widget.user.uid);
      if (_patientUid != null) {
        final results = await Future.wait([
          GuardianController.getTodayLog(widget.user.uid),
          GuardianController.getPatientPrescription(_patientUid!),
          GuardianController.getPatientNextAppointment(_patientUid!),


          GuardianController.fetchNameByUid(_patientUid!),


        ]);
        _todayLog        = results[0] as Map<String,dynamic>?;
        _prescription    = results[1] as Prescription?;
        _nextAppointment = results[2] as Appointment?;
        if (_todayLog != null) {
          _selectedMood = _todayLog!['mood'] as int? ?? 1;
          _obsCtrl.text = _todayLog!['observations'] as String? ?? '';
        }
      }
    } catch (e) {
      debugPrint('Guardian load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveMood() async {
    if (_patientUid == null) return;
    await GuardianController.updateMood(
        widget.user.uid, _patientUid!, _selectedMood);
    await _load();
    _snack('Mood saved');
  }

  Future<void> _addWater(int glasses) async {
    if (_patientUid == null) return;
    await GuardianController.addWater(
        widget.user.uid, _patientUid!, glasses);
    await _load();
    _showWaterFeedback((_todayLog?['waterIntake'] as int? ?? 0));
  }

  // to mark whether the patient tooks meds or not
  Future<void> _toggleMedication(bool taken) async {
    setState(() => _savingMed = true);
    await GuardianController.updateMedication(
        widget.user.uid, _patientUid!, taken);
    await _load();
    if (mounted) setState(() => _savingMed = false);
    _snack(taken ? '✅ Medication marked as taken' : '❌ Marked as not taken');
  }

  Future<void> _saveObservations() async {
    if (_patientUid == null) return;
    await GuardianController.updateObservations(
        widget.user.uid, _patientUid!, _obsCtrl.text.trim());
    await _load();
    _snack('Observations saved');
  }

  void _showWaterFeedback(int total) {
    String msg;
    Color  color;
    if (total < 3)      { msg = '💧 Keep drinking! Aim for 8+ glasses.'; color = Colors.red; }
    else if (total < 6) { msg = '💧 Good progress! Keep it up.';          color = Colors.orange; }
    else if (total < 8) { msg = '💧 Almost there! Great hydration.';      color = Colors.lightGreen; }
    else                { msg = '💧 Excellent! Fully hydrated today.';     color = Colors.green; }

    showDialog(context: context, builder: (ctx) => AlertDialog(
      content: Text(msg, style: TextStyle(color: color, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'))],
    ));
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('[TEST] Guardian — ${widget.user.name}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
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
            if (_patientUid == null)
              const Center(child: Text('No patient linked.',
                  style: TextStyle(color: Colors.grey)))
            else ...[

              // ── Next Appointment ──────────────────
              const TestSectionTitle(title: '📅 Patient Next Appointment'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: _nextAppointment != null
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${_nextAppointment!.date}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Time: ${_nextAppointment!.time}'),
                      Text('Status: ${_nextAppointment!.status}'),
                    ])
                    : const Text('No upcoming appointment',
                    style: TextStyle(color: Colors.grey)),
              ),




              //  for notifications


              const SizedBox(height: 16),
              TestNotificationTrigger(
                patientName:     _patientName,
                prescription:    _prescription,
                nextAppointment: _nextAppointment,
                isGuardian:      true,
              ),



              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => NotificationController.testAlarm(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Test Alarm',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => NotificationController.testGeneral(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('Test General',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ]),
              //  test ends
















              const SizedBox(height: 20),

              // ── Medicines ─────────────────────────
              const TestSectionTitle(title: '💊 Patient Medicines'),
              if (_prescription == null ||
                  _prescription!.medicines.isEmpty)
                const Text('No active prescription',
                    style: TextStyle(color: Colors.grey))
              else
                ..._prescription!.medicines.map((med) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.medication,
                            color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Text(med.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(med.dose,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ]),
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, children: [
                        if (med.morning)
                          _chip('🌅 Morning'),
                        if (med.afternoon)
                          _chip('☀️ Afternoon'),
                        if (med.night)
                          _chip('🌙 Night'),
                        _chip(med.beforeMeal
                            ? 'Before meal' : 'After meal'),
                      ]),
                    ],
                  ),
                )),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // ── Guardian Mood ─────────────────────
              TestSectionTitle(
                title: 'Patient Mood (Your Observation)',
                subtitle: _todayLog != null
                    ? 'Recorded: ${_moodLabel(_todayLog!["mood"] as int? ?? 0)}'
                    : 'Not recorded today',
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['😞','😟','😐','🙂','😊']
                    .asMap().entries.map((e) => GestureDetector(
                  onTap: () => setState(() =>
                  _selectedMood = e.key + 1),
                  child: Text(e.value,
                      style: TextStyle(
                          fontSize: _selectedMood == e.key + 1
                              ? 32 : 22)),
                )).toList(),
              ),
              const SizedBox(height: 8),
              TestButton(
                label:     'Save Mood',
                onPressed: _saveMood,
                color:     Colors.orange,
              ),

              const SizedBox(height: 20),

              // ── Water ─────────────────────────────
              Row(children: [
                const TestSectionTitle(title: '💧 Water Intake'),
                const Spacer(),
                Text('Today: ${_todayLog?["waterIntake"] ?? 0}g',
                    style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              Row(children: [1,2,3,5].map((g) => Expanded(
                child: GestureDetector(
                  onTap: () => _addWater(g),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text('+$g',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              )).toList()),

              const SizedBox(height: 20),



              const SizedBox(height: 20),

// ── Medication section to check whether the patient taking them ────────────────────────────────
              const TestSectionTitle(
                title: '💊 Patient Medication Today',
                subtitle: 'Mark whether patient took their medicine',
              ),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _savingMed ? null : () => _toggleMedication(true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _todayLog?['medicationTaken'] == true
                            ? Colors.green : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text('✅ Taken',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _todayLog?['medicationTaken'] == true
                                ? Colors.white : Colors.green,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _savingMed ? null : () => _toggleMedication(false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _todayLog?['medicationTaken'] == false &&
                            _todayLog?['medicationTaken'] != null
                            ? Colors.red : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text('❌ Not Taken',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _todayLog?['medicationTaken'] == false &&
                                _todayLog?['medicationTaken'] != null
                                ? Colors.white : Colors.red,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ),
                ),
              ]),


              // end of update medicine section

              // ── Observations ──────────────────────
              const TestSectionTitle(title: 'Observations'),
              TextField(
                controller: _obsCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter observations...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 8),
              TestButton(
                label:     'Save Observations',
                onPressed: _saveObservations,
                color:     Colors.orange,
              ),

              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.orange.shade200),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11)),
  );

  String _moodLabel(int m) {
    switch (m) {
      case 1: return 'Worse'; case 2: return 'Bad';
      case 3: return 'Okay';  case 4: return 'Good';
      case 5: return 'Happy'; default: return '—';
    }
  }
}


