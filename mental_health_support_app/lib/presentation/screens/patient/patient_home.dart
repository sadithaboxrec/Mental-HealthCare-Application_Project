import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/models/prescription.dart';
import '../../../core/controllers/patient_controller.dart';

import 'mood_response.dart';
import 'diary_screen.dart';
import '../chat/patient_chat.dart';

import 'widgets/mood_tracker.dart';
import 'widgets/hydration_tracker.dart';
import 'widgets/sleep_tracker.dart';
import 'widgets/home_action_row.dart';
import 'widgets/medication_tracker.dart';
import 'widgets/home_header.dart';

class PatientHome extends StatefulWidget {
  final AppUser user;
  const PatientHome({super.key, required this.user});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  DailyLog? _todayLog;
  Prescription? _prescription;
  bool _loading = true;

  int _moodSlider = 3;
  String _selectedSleep = '';
  int _localWaterCount = 0;
  bool? _localMedTaken;

  final Color _primaryBlue = const Color(0xFF8EC5F5);
  final Color _primaryBlueDeep = const Color(0xFF6BA8E8);
  static const Color _screenBg = Color(0xFFF3F2EF);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        PatientController.getTodayLog(widget.user.uid),
        PatientController.getActivePrescription(widget.user.uid),
      ]);
      if (mounted) {
        setState(() {
          _todayLog = results[0] as DailyLog?;
          _prescription = results[1] as Prescription?;
          if (_todayLog != null) {
            _moodSlider = _todayLog!.mood > 0 ? _todayLog!.mood : 3;
            _selectedSleep = _todayLog!.sleepHours;
            _localWaterCount = _todayLog!.waterIntake;
            _localMedTaken = _todayLog!.medicationTaken;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleMedicationUpdate(bool taken) {
    setState(() => _localMedTaken = taken);
    PatientController.updateMedication(widget.user.uid, taken);
  }

  void _handleWaterAdd(int amount) {
    setState(() => _localWaterCount += amount);
    PatientController.addWater(widget.user.uid, amount);
    _showWaterToast(amount);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width >= 600 ? 28.0 : 20.0;

    return Scaffold(
      body: Container(
        color: _screenBg,
        child: SafeArea(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: _primaryBlueDeep,
                    strokeWidth: 2.5,
                  ),
                )
              : ListView(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 10),
                  children: [
                    HomeHeader(
  userName: widget.user.name,  
  primaryBlue: _primaryBlue,
  primaryBlueDeep: _primaryBlueDeep,
),
                    const SizedBox(height: 8),

                    _buildCard(
                      child: MoodTracker(
                        currentMood: _moodSlider,
                        emojiColors: const [
                          Color(0xFFEF5350),
                          Color(0xFFFF9800),
                          Color(0xFF78909C),
                          Color(0xFF66BB6A),
                          Color(0xFF29B6F6),
                        ],
                        primaryBlue: _primaryBlue,
                        primaryBlueDeep: _primaryBlueDeep,
                        onChanged: (v) => setState(() => _moodSlider = v),
                        onSave: (v) {
                          PatientController.updateMood(widget.user.uid, v);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MoodResponse(mood: v),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    HomeActionRow(
                      primaryBlue: _primaryBlue,
                      primaryBlueDeep: _primaryBlueDeep,
                      onDiaryTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiaryScreen(user: widget.user),
                        ),
                      ),
                      onSupportTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientChat(user: widget.user),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildCard(
                      child: HydrationTracker(
                        count: _localWaterCount,
                        onAdd: _handleWaterAdd,
                        primaryBlue: _primaryBlue,
                        primaryBlueDeep: _primaryBlueDeep,
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildCard(
                      child: SleepTracker(
                        selectedSleep: _selectedSleep,
                        primaryBlue: _primaryBlue,
                        primaryBlueDeep: _primaryBlueDeep,
                        onSelect: (val) {
                          setState(() => _selectedSleep = val);
                          PatientController.updateSleep(widget.user.uid, val);
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (_prescription != null)
                      _buildCard(
                        child: MedicationTracker(
                          medicationTaken: _localMedTaken,
                          onToggle: _handleMedicationUpdate,
                          primaryBlueDeep: _primaryBlueDeep,
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFCFCFD)],
        ),
        border: Border.all(color: const Color(0xFFE5E3DF), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF2D3142).withOpacity(0.04),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  void _showWaterToast(int added) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        });
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.white.withOpacity(0.9),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💧', style: TextStyle(fontSize: 50)),
                    const SizedBox(height: 12),
                    Text(
                      'Success!',
                      style: TextStyle(
                        color: _primaryBlueDeep,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total today: $_localWaterCount glasses',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
