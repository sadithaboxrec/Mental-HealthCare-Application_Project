import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/prescription.dart';
import '../../../core/models/appointment.dart';

import '../../../core/controllers/auth_controller.dart';
import '../../../core/controllers/guardian_controller.dart';
import '../../../core/navigation/navigation_helper.dart';

import 'widgets/guardian_header.dart';
import 'widgets/mood_section.dart';
import 'widgets/water_section.dart';
import 'widgets/medication_status_section.dart';
import 'widgets/appointment_section.dart';
import 'widgets/medicine_section.dart';
import 'widgets/observation_section.dart';

class GuardianHome extends StatefulWidget {
  final AppUser user;

  const GuardianHome({super.key, required this.user});

  @override
  State<GuardianHome> createState() => _GuardianHomeState();
}

class _GuardianHomeState extends State<GuardianHome> {
  String? _patientUid;

  Map<String, dynamic>? _todayLog;
  Prescription? _prescription;
  Appointment? _nextAppointment;

  bool _loading = true;
  bool _savingMed = false;
  bool _savingObs = false;
  bool _savedObs = false;

  double _moodValue = 3;

  final TextEditingController _obsCtrl = TextEditingController();
  final FocusNode _obsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    _obsFocus.dispose();
    super.dispose();
  }

  // ── LOAD ────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() => _loading = true);

    _patientUid = await GuardianController.getPatientUid(widget.user.uid);

    if (_patientUid != null) {
      final results = await Future.wait([
        GuardianController.getTodayLog(widget.user.uid),
        GuardianController.getPatientPrescription(_patientUid!),
        GuardianController.getPatientNextAppointment(_patientUid!),
      ]);

      _todayLog = results[0] as Map<String, dynamic>?;
      _prescription = results[1] as Prescription?;
      _nextAppointment = results[2] as Appointment?;

      _moodValue = ((_todayLog?['mood'] as int? ?? 3).clamp(1, 5)).toDouble();
      _obsCtrl.text = _todayLog?['observations'] ?? '';
    }

    setState(() => _loading = false);
  }

  // ── MEDICATION
  Future<void> _toggleMedication(bool taken) async {
    setState(() => _savingMed = true);
    await GuardianController.updateMedication(
      widget.user.uid,
      _patientUid!,
      taken,
    );
    setState(() {
      _todayLog ??= {};
      _todayLog!['medicationTaken'] = taken;
      _savingMed = false;
    });
  }

  // ── WATER
  Future<void> _addWater(int g) async {
    await GuardianController.addWater(widget.user.uid, _patientUid!, g);
    setState(() {
      _todayLog ??= {};
      _todayLog!['waterIntake'] = (_todayLog!['waterIntake'] ?? 0) + g;
    });
  }

  // ── MOOD
  Future<void> _saveMood(double v) async {
    _moodValue = v.clamp(1, 5);
    await GuardianController.updateMood(
      widget.user.uid,
      _patientUid!,
      v.round(),
    );
    setState(() {});
  }

  // ── OBSERVATIONS
  Future<void> _saveObservations() async {
    if (_patientUid == null) return;
    setState(() {
      _savingObs = true;
      _savedObs = false;
    });
    await GuardianController.updateObservations(
      widget.user.uid,
      _patientUid!,
      _obsCtrl.text.trim(),
    );
    setState(() {
      _savingObs = false;
      _savedObs = true;
    });
  }

  // ── LOGOUT
  Future<void> _logout() async {
    await AuthController.logout();
    if (context.mounted) NavigationHelper.goToLogin(context);
  }

  // ── BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A90D9)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF4A90D9),
              child: ListView(
                children: [
                  GuardianHeader(user: widget.user, onLogout: _logout),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        MoodSection(
                          moodValue: _moodValue,
                          onChanged: _saveMood,
                          saving: false,
                          saved: true,
                        ),
                        WaterSection(
                          intake: _todayLog?['waterIntake'] ?? 0,
                          onAdd: _addWater,
                        ),
                        MedicationStatusSection(
                          taken: _todayLog?['medicationTaken'],
                          loading: _savingMed,
                          onToggle: _toggleMedication,
                        ),
                        AppointmentSection(appointment: _nextAppointment),
                        MedicineSection(prescription: _prescription),
                        ObservationsSection(
                          controller: _obsCtrl,
                          saving: _savingObs,
                          saved: _savedObs,
                          onSave: _saveObservations,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
//end of file mishara