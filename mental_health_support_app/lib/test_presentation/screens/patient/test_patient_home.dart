// import 'package:flutter/material.dart';
// import '../../../core/models/app_user.dart';
// import '../../../core/models/daily_log.dart';
// import '../../../core/models/prescription.dart';
// import '../../../core/models/appointment.dart';
// import '../../../core/controllers/auth_controller.dart';
// import '../../../core/controllers/patient_controller.dart';
// import '../../../core/navigation/navigation_helper.dart';
// import '../../components/test_button.dart';
// import '../../components/test_section_title.dart';
// import 'test_mood_response.dart';
// import 'test_diary_screen.dart';
//
// class TestPatientHome extends StatefulWidget {
//   final AppUser user;
//   const TestPatientHome({super.key, required this.user});
//
//   @override
//   State<TestPatientHome> createState() => _TestPatientHomeState();
// }
//
// class _TestPatientHomeState extends State<TestPatientHome> {
//   DailyLog?    _todayLog;
//   Prescription? _prescription;
//   Appointment?  _nextAppointment;
//   bool         _loading        = true;
//
//   int    _moodSlider    = 1;
//   bool   _savingMood    = false;
//   bool   _savingWater   = false;
//   bool   _savingSleep   = false;
//   bool   _savingMed     = false;
//   String _selectedSleep = '';
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
//         PatientController.getTodayLog(widget.user.uid),
//         PatientController.getActivePrescription(widget.user.uid),
//         PatientController.getNextAppointment(widget.user.uid),
//       ]);
//       if (mounted) setState(() {
//         _todayLog        = results[0] as DailyLog?;
//         _prescription    = results[1] as Prescription?;
//         _nextAppointment = results[2] as Appointment?;
//         if (_todayLog != null) {
//           _moodSlider    = _todayLog!.mood > 0 ? _todayLog!.mood : 1;
//           _selectedSleep = _todayLog!.sleepHours;
//         }
//         _loading = false;
//       });
//     } catch (e) {
//       debugPrint('Patient home error: $e');
//       if (mounted) setState(() => _loading = false);
//     }
//   }
//
//   Future<void> _saveMood() async {
//     setState(() => _savingMood = true);
//     await PatientController.updateMood(widget.user.uid, _moodSlider);
//     await _load();
//     if (mounted) {
//       setState(() => _savingMood = false);
//       // Navigate to mood response screen
//       Navigator.push(context, MaterialPageRoute(
//         builder: (_) => TestMoodResponse(mood: _moodSlider),
//       ));
//     }
//   }
//
//   Future<void> _addWater(int glasses) async {
//     setState(() => _savingWater = true);
//     await PatientController.addWater(widget.user.uid, glasses);
//     await _load();
//     if (mounted) setState(() => _savingWater = false);
//     _snack('💧 +$glasses glasses added');
//   }
//
//   Future<void> _saveSleep(String val) async {
//     setState(() { _selectedSleep = val; _savingSleep = true; });
//     await PatientController.updateSleep(widget.user.uid, val);
//     await _load();
//     if (mounted) setState(() => _savingSleep = false);
//   }
//
//   Future<void> _toggleMedication(bool taken) async {
//     setState(() => _savingMed = true);
//     await PatientController.updateMedication(widget.user.uid, taken);
//     await _load();
//     if (mounted) setState(() => _savingMed = false);
//   }
//
//   Future<void> _requestReschedule() async {
//     if (_nextAppointment == null) {
//       _snack('No upcoming appointment to reschedule');
//       return;
//     }
//
//     String reason = '';
//     final reasonCtrl = TextEditingController();
//
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now().add(const Duration(days: 1)),
//       firstDate:   DateTime.now(),
//       lastDate:    DateTime.now().add(const Duration(days: 365)),
//     );
//     if (picked == null) return;
//
//     final newDate =
//         '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
//
//     if (!mounted) return;
//     await showDialog(context: context, builder: (ctx) => AlertDialog(
//       title: const Text('Reason for Reschedule'),
//       content: TextField(
//         controller: reasonCtrl,
//         decoration: const InputDecoration(hintText: 'Optional reason...'),
//       ),
//       actions: [
//         TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
//         TextButton(
//           onPressed: () {
//             reason = reasonCtrl.text;
//             Navigator.pop(ctx);
//           },
//           child: const Text('Submit'),
//         ),
//       ],
//     ));
//
//     await PatientController.requestReschedule(
//       patientUid:    widget.user.uid,
//       doctorUid:     _nextAppointment!.doctorUid,
//       appointmentId: _nextAppointment!.id,
//       requestedDate: newDate,
//       reason:        reason,
//     );
//     _snack('Reschedule request sent to doctor');
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
//         title: Text('[TEST] ${widget.user.name}'),
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(icon: const Icon(Icons.book),
//               onPressed: () => Navigator.push(context, MaterialPageRoute(
//                 builder: (_) => TestDiaryScreen(user: widget.user),
//               ))),
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
//             _tag('[TEST UI]', Colors.orange),
//             const SizedBox(height: 16),
//
//             // ── Mood Slider ───────────────────────
//             const TestSectionTitle(
//               title: 'How are you feeling?',
//               subtitle: 'Last entry overwrites previous',
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: ['😞','😟','😐','🙂','😊']
//                   .asMap().entries.map((e) => Text(
//                 e.value,
//                 style: TextStyle(
//                     fontSize: _moodSlider == e.key + 1 ? 32 : 22),
//               )).toList(),
//             ),
//             Slider(
//               value:    _moodSlider.toDouble(),
//               min:      1, max: 5,
//               divisions: 4,
//               activeColor: Colors.green,
//               label: _moodLabel(_moodSlider),
//               onChanged: (v) =>
//                   setState(() => _moodSlider = v.round()),
//             ),
//             Center(child: Text(_moodLabel(_moodSlider),
//                 style: const TextStyle(fontWeight: FontWeight.bold))),
//             const SizedBox(height: 8),
//             if (_todayLog?.mood != null && _todayLog!.mood > 0)
//               Text('Last recorded: ${_moodLabel(_todayLog!.mood)}',
//                   style: const TextStyle(
//                       color: Colors.grey, fontSize: 12)),
//             const SizedBox(height: 8),
//             TestButton(
//               label:     'Save Mood',
//               onPressed: _saveMood,
//               isLoading: _savingMood,
//               color:     Colors.green,
//             ),
//
//             const SizedBox(height: 24),
//
//             // ── Sleep ─────────────────────────────
//             const TestSectionTitle(
//                 title: 'How many hours did you sleep?'),
//             Wrap(
//               spacing: 8,
//               children: [
//                 {'v': 'less5', 'l': '< 5 hrs'},
//                 {'v': '6',     'l': '6 hrs'},
//                 {'v': '7',     'l': '7 hrs'},
//                 {'v': '8',     'l': '8 hrs'},
//                 {'v': 'more8', 'l': '> 8 hrs'},
//               ].map((opt) {
//                 final isSelected = _selectedSleep == opt['v'];
//                 return GestureDetector(
//                   onTap: () => _saveSleep(opt['v']!),
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 200),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 8),
//                     margin: const EdgeInsets.only(bottom: 8),
//                     decoration: BoxDecoration(
//                       color:        isSelected
//                           ? Colors.green : Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                           color: isSelected
//                               ? Colors.green : Colors.grey.shade300),
//                     ),
//                     child: Text(opt['l']!,
//                         style: TextStyle(
//                           color:      isSelected
//                               ? Colors.white : Colors.black,
//                           fontWeight: isSelected
//                               ? FontWeight.bold : FontWeight.normal,
//                         )),
//                   ),
//                 );
//               }).toList(),
//             ),
//
//             const SizedBox(height: 24),
//
//             // ── Water Intake ──────────────────────
//             Row(children: [
//               const TestSectionTitle(title: '💧 Water Intake'),
//               const Spacer(),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 10, vertical: 4),
//                 decoration: BoxDecoration(
//                   color:        Colors.blue.shade50,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(
//                   'Today: ${_todayLog?.waterIntake ?? 0} glasses',
//                   style: TextStyle(
//                       color:      Colors.blue.shade700,
//                       fontWeight: FontWeight.bold,
//                       fontSize:   12),
//                 ),
//               ),
//             ]),
//             const SizedBox(height: 8),
//             Row(children: [1,2,3,5].map((g) => Expanded(
//               child: GestureDetector(
//                 onTap: _savingWater ? null : () => _addWater(g),
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 6),
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   decoration: BoxDecoration(
//                     color:        Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.blue.shade200),
//                   ),
//                   child: Text('+$g',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                           color:      Colors.blue.shade700,
//                           fontWeight: FontWeight.bold)),
//                 ),
//               ),
//             )).toList()),
//
//             const SizedBox(height: 24),
//
//             // ── Medication ────────────────────────
//             if (_prescription != null) ...[
//               const TestSectionTitle(title: '💊 Medication Today'),
//               Row(children: [
//                 Expanded(
//                   child: TestButton(
//                     label:     '✅ Taken',
//                     onPressed: _savingMed
//                         ? null : () => _toggleMedication(true),
//                     color:     Colors.green,
//                     outlined:  _todayLog?.medicationTaken != true,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: TestButton(
//                     label:     '❌ Not Taken',
//                     onPressed: _savingMed
//                         ? null : () => _toggleMedication(false),
//                     color:     Colors.red,
//                     outlined:  _todayLog?.medicationTaken != false,
//                   ),
//                 ),
//               ]),
//               const SizedBox(height: 8),
//               // Show today's medicines
//               ..._prescription!.medicines
//                   .where((m) => _isCurrentSlot(m))
//                   .map((m) => ListTile(
//                 dense: true,
//                 leading: const Icon(Icons.medication,
//                     color: Colors.green, size: 18),
//                 title: Text(m.name,
//                     style: const TextStyle(fontSize: 13)),
//                 subtitle: Text('${m.dose}  •  '
//                     '${m.beforeMeal ? "Before meal" : "After meal"}',
//                     style: const TextStyle(fontSize: 11)),
//               )),
//               const SizedBox(height: 24),
//             ],
//
//             // ── Doctor Suggestions ────────────────
//             if (_prescription?.suggestions.isNotEmpty ?? false) ...[
//               const TestSectionTitle(title: "Doctor's Suggestions"),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color:        Colors.amber.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.amber.shade200),
//                 ),
//                 child: Text(_prescription!.suggestions,
//                     style: const TextStyle(fontSize: 13)),
//               ),
//               const SizedBox(height: 24),
//             ],
//
//             // ── Next Appointment ──────────────────
//             const Divider(),
//             const SizedBox(height: 12),
//             const TestSectionTitle(title: '📅 Next Appointment'),
//             if (_nextAppointment != null) ...[
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color:        Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.green.shade200),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Date: ${_nextAppointment!.date}',
//                         style: const TextStyle(
//                             fontWeight: FontWeight.bold)),
//                     Text('Time: ${_nextAppointment!.time}'),
//                     Text('Status: ${_nextAppointment!.status}'),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 8),
//               TestButton(
//                 label:    'Request Reschedule',
//                 onPressed: _requestReschedule,
//                 color:    Colors.orange,
//                 outlined: true,
//               ),
//             ] else
//               const Text('No upcoming appointment',
//                   style: TextStyle(color: Colors.grey)),
//
//             const SizedBox(height: 32),
//           ],
//         ),
//       ),
//     );
//   }
//
//   bool _isCurrentSlot(m) {
//     final h = DateTime.now().hour;
//     if (h >= 5  && h < 12) return m.morning;
//     if (h >= 12 && h < 17) return m.afternoon;
//     return m.night;
//   }
//
//   String _moodLabel(int mood) {
//     switch (mood) {
//       case 1: return 'Worse 😞';
//       case 2: return 'Bad 😟';
//       case 3: return 'Okay 😐';
//       case 4: return 'Good 🙂';
//       case 5: return 'Happy 😊';
//       default: return '';
//     }
//   }
//
//   Widget _tag(String label, Color color) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
//     decoration: BoxDecoration(
//       color:        color.withOpacity(0.1),
//       borderRadius: BorderRadius.circular(4),
//       border: Border.all(color: color.withOpacity(0.4)),
//     ),
//     child: Text(label,
//         style: TextStyle(
//             color:      color,
//             fontSize:   11,
//             fontWeight: FontWeight.bold)),
//   );
// }


import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/models/prescription.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/controllers/patient_controller.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../components/test_section_title.dart';
import 'test_mood_response.dart';
import 'test_diary_screen.dart';



import '../../../core/models/appointment.dart';
import '../../../core/controllers/notification_controller.dart';
import '../../components/test_notification_trigger.dart';

class TestPatientHome extends StatefulWidget {
  final AppUser user;
  const TestPatientHome({super.key, required this.user});

  @override
  State<TestPatientHome> createState() => _TestPatientHomeState();
}

class _TestPatientHomeState extends State<TestPatientHome> {
  DailyLog?    _todayLog;
  Prescription? _prescription;
  bool         _loading     = true;
  int          _moodSlider  = 3;
  String       _selectedSleep = '';

  // for appointments
  Appointment? _nextAppointment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        PatientController.getTodayLog(widget.user.uid),
        PatientController.getActivePrescription(widget.user.uid),


    // for appointments
       PatientController.getNextAppointment(widget.user.uid),



      ]);
      if (mounted) setState(() {
        _todayLog     = results[0] as DailyLog?;
        _prescription = results[1] as Prescription?;
        if (_todayLog != null) {
          if (_todayLog!.mood > 0) _moodSlider = _todayLog!.mood;
          _selectedSleep = _todayLog!.sleepHours;
        }
        _loading = false;
      });
    } catch (e) {
      debugPrint('Patient home error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // No loading state — fire and forget, update local state instantly
  Future<void> _saveMood() async {
    await PatientController.updateMood(widget.user.uid, _moodSlider);
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => TestMoodResponse(mood: _moodSlider),
      ));
    }
  }

  Future<void> _addWater(int glasses) async {
    final prev = _todayLog?.waterIntake ?? 0;
    // Update local state instantly — no spinner
    setState(() {
      if (_todayLog != null) {
        _todayLog = DailyLog(
          id: _todayLog!.id, patientUid: _todayLog!.patientUid,
          date: _todayLog!.date, mood: _todayLog!.mood,
          moodUpdatedAt: _todayLog!.moodUpdatedAt,
          waterIntake: prev + glasses,
          sleepHours: _todayLog!.sleepHours,
          medicationTaken: _todayLog!.medicationTaken,
          createdAt: _todayLog!.createdAt, updatedAt: '',
        );
      }
    });
    await PatientController.addWater(widget.user.uid, glasses);
    _showWaterFeedback(prev + glasses);
  }

  Future<void> _saveSleep(String val) async {
    setState(() => _selectedSleep = val);
    await PatientController.updateSleep(widget.user.uid, val);
  }

  Future<void> _toggleMedication(bool taken) async {
    setState(() {
      if (_todayLog != null) {
        _todayLog = DailyLog(
          id: _todayLog!.id, patientUid: _todayLog!.patientUid,
          date: _todayLog!.date, mood: _todayLog!.mood,
          moodUpdatedAt: _todayLog!.moodUpdatedAt,
          waterIntake: _todayLog!.waterIntake,
          sleepHours: _todayLog!.sleepHours,
          medicationTaken: taken,
          createdAt: _todayLog!.createdAt, updatedAt: '',
        );
      }
    });
    await PatientController.updateMedication(widget.user.uid, taken);
  }

  void _showWaterFeedback(int total) {
    String msg; Color color;
    if (total < 3)      { msg = '💧 Keep drinking! Aim for 8+ glasses.'; color = Colors.red; }
    else if (total < 6) { msg = '💧 Good progress! Keep it up.';          color = Colors.orange; }
    else if (total < 8) { msg = '💧 Almost there! Great hydration.';      color = Colors.lightGreen; }
    else                { msg = '💧 Excellent! Fully hydrated today.';     color = Colors.green; }

    showDialog(context: context, builder: (ctx) => AlertDialog(
      content: Text(msg,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      actions: [TextButton(
          onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Hi, ${widget.user.name} 👋'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.book_outlined),
            tooltip: 'Diary',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => TestDiaryScreen(user: widget.user),
            )),
          ),
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

            // ── Mood Slider ───────────────────────
            const TestSectionTitle(
              title: 'How are you feeling?',
              subtitle: 'Last entry of the day is saved',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['😞','😟','😐','🙂','😊']
                  .asMap().entries.map((e) => Text(e.value,
                  style: TextStyle(
                      fontSize: _moodSlider == e.key + 1
                          ? 34 : 22))).toList(),
            ),
            Slider(
              value:       _moodSlider.toDouble(),
              min: 1, max: 5, divisions: 4,
              activeColor: Colors.green,
              label:       _moodLabel(_moodSlider),
              onChanged: (v) => setState(() => _moodSlider = v.round()),
            ),
            Center(child: Text(_moodLabel(_moodSlider),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13))),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity, height: 44,
              child: ElevatedButton(
                onPressed: _saveMood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Mood',
                    style: TextStyle(color: Colors.white)),
              ),
            ),

            const SizedBox(height: 24),

            // ── Sleep ─────────────────────────────
            const TestSectionTitle(
                title: 'How many hours did you sleep?'),
            Wrap(
              spacing: 8,
              children: [
                {'v': 'less5', 'l': '< 5 hrs'},
                {'v': '6',     'l': '6 hrs'},
                {'v': '7',     'l': '7 hrs'},
                {'v': '8',     'l': '8 hrs'},
                {'v': 'more8', 'l': '> 8 hrs'},
              ].map((opt) {
                final isSel = _selectedSleep == opt['v'];
                return GestureDetector(
                  onTap: () => _saveSleep(opt['v']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSel ? Colors.green : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isSel
                              ? Colors.green
                              : Colors.grey.shade300),
                    ),
                    child: Text(opt['l']!,
                        style: TextStyle(
                          color: isSel ? Colors.white : Colors.black,
                          fontWeight: isSel
                              ? FontWeight.bold : FontWeight.normal,
                        )),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),



            //    for notifications

            const SizedBox(height: 16),
            TestNotificationTrigger(
              patientName:     widget.user.name,
              prescription:    _prescription,
              nextAppointment: _nextAppointment,
              isGuardian:      false,
            ),


            const SizedBox(height: 8),


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












            // ── Water Intake ──────────────────────
            Row(children: [
              const TestSectionTitle(title: '💧 Water Intake'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Today: ${_todayLog?.waterIntake ?? 0} glasses',
                  style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [1,2,3,5].map((g) => Expanded(
              child: GestureDetector(
                onTap: () => _addWater(g),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:        Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text('+$g',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color:      Colors.blue.shade700,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            )).toList()),

            const SizedBox(height: 24),

            // ── Medication Toggle ─────────────────
            if (_prescription != null) ...[
              const TestSectionTitle(title: '💊 Today\'s Medication'),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleMedication(true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _todayLog?.medicationTaken == true
                            ? Colors.green : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text('✅ Taken',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _todayLog?.medicationTaken == true
                                ? Colors.white : Colors.green,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleMedication(false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _todayLog?.medicationTaken == false
                            ? Colors.red : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text('❌ Not Taken',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _todayLog?.medicationTaken == false
                                ? Colors.white : Colors.red,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ),
                ),
              ]),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _moodLabel(int m) {
    switch (m) {
      case 1: return 'Worse 😞'; case 2: return 'Bad 😟';
      case 3: return 'Okay 😐';  case 4: return 'Good 🙂';
      case 5: return 'Happy 😊'; default: return '';
    }
  }
}