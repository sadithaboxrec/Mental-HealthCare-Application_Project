import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/models/app_user.dart';
import '../../../core/models/prescription.dart';
import '../../../core/controllers/patient_controller.dart';

import '../../components2/section_title.dart';

class PatientMedications extends StatefulWidget {
  final AppUser user;
  const PatientMedications({super.key, required this.user});

  @override
  State<PatientMedications> createState() => _PatientMedicationsState();
}

class _PatientMedicationsState extends State<PatientMedications> {
  static const Color _primaryBlue = Color(0xFF5DADE3);
  Prescription? _prescription;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _prescription =
          await PatientController.getActivePrescription(widget.user.uid);
    } catch (e) {
      debugPrint('Medications load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FD),
      appBar: AppBar(

        title: const Center(
          child: Text(
            'My Medicines',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),

        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFEAF3FC)],
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _primaryBlue),
              )
            : _prescription == null || _prescription!.medicines.isEmpty
                ? Center(
                    child: _glassCard(
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.medication_liquid_outlined,
                              size: 42,
                              color: _primaryBlue,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No active prescription',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      // ── Prescription summary ──────────────
                      _sectionContainer(
                        highlighted: true,
                        child: _glassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.description_outlined,
                                        color: _primaryBlue, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Prescription Summary',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Prescribed on ${_prescription!.createdAt.substring(0, 10)}',
                                      style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12.5),
                                    ),
                                  ],
                                ),
                                if (_prescription!.diagnosis.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(
                                            Icons.health_and_safety_outlined,
                                            size: 15,
                                            color: Colors.black54),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _prescription!.diagnosis,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Medicines list ────────────────────
                      _sectionContainer(
                        highlighted: false,
                        child: Column(
                          children: [
                            _glassCard(
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.medication_outlined,
                                        color: _primaryBlue, size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: SectionTitle(title: 'Medicines'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._prescription!.medicines.map(
                              (med) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _medicineCard(med),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Doctor suggestions ────────────────
                      if (_prescription!.suggestions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _sectionContainer(
                          highlighted: true,
                          child: Column(
                            children: [
                              _glassCard(
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(Icons.tips_and_updates_outlined,
                                          color: Colors.amber, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: SectionTitle(
                                            title: "Doctor's Suggestions"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _glassCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.14),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                            Icons.tips_and_updates_outlined,
                                            color: Colors.amber,
                                            size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _prescription!.suggestions,
                                          style: const TextStyle(
                                              fontSize: 13.2,
                                              color: Colors.black87,
                                              height: 1.35),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
      ),
    );
  }

  // ── Medicine card ─────────────────────────────────────
  Widget _medicineCard(dynamic med) {
    // ✅ FIX: read tabletCount (int) not dose (string)
    final int tabletCount = (med.tabletCount as int?) ?? 1;

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Name row + tablet count badge ─────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medication_outlined,
                      color: _primaryBlue, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    med.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // ✅ Always show tablet count badge (even 1 tablet)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: _primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$tabletCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Schedule chips ────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // time of day
                if (med.morning)
                  _scheduleChip(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Morning',
                    color: Colors.orange,
                  ),
                if (med.afternoon)
                  _scheduleChip(
                    icon: Icons.light_mode_outlined,
                    label: 'Afternoon',
                    color: Colors.amber,
                  ),
                if (med.night)
                  _scheduleChip(
                    icon: Icons.nightlight_round,
                    label: 'Night',
                    color: Colors.indigo,
                  ),

                // meal timing
                _scheduleChip(
                  icon: Icons.restaurant_outlined,
                  label: med.beforeMeal ? 'Before meal' : 'After meal',
                  color: Colors.teal,
                ),

                // tablet count chip (always visible)
                _scheduleChip(
                  icon: Icons.medication_liquid_outlined,
                  label: tabletCount == 1
                      ? '1 tablet'
                      : '$tabletCount tablets',
                  color: _primaryBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black.withOpacity(0.12),
                  width: 1.2,
                ),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionContainer({
    required Widget child,
    required bool highlighted,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? _primaryBlue.withOpacity(0.12)
            : Colors.black.withOpacity(0.035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? _primaryBlue.withOpacity(0.25)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: child,
    );
  }

  Widget _scheduleChip({
    required IconData icon,
    required String label,
    required Color color,
  }) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.13),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}