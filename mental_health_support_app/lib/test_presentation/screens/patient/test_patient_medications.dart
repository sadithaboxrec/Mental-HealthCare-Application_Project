import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/prescription.dart';
import '../../../core/controllers/patient_controller.dart';
import '../../components/test_section_title.dart';

class TestPatientMedications extends StatefulWidget {
  final AppUser user;
  const TestPatientMedications({super.key, required this.user});

  @override
  State<TestPatientMedications> createState() =>
      _TestPatientMedicationsState();
}

class _TestPatientMedicationsState extends State<TestPatientMedications> {
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Medicines'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _prescription == null || _prescription!.medicines.isEmpty
          ? const Center(
          child: Text('No active prescription',
              style: TextStyle(color: Colors.grey)))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // Prescription info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prescribed on: '
                    '${_prescription!.createdAt.substring(0,10)}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                if (_prescription!.diagnosis.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Diagnosis: ${_prescription!.diagnosis}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          const TestSectionTitle(title: 'Medicines'),
          ..._prescription!.medicines.map((med) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.medication,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(med.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15))),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(med.dose,
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  if (med.morning)
                    _scheduleChip('🌅 Morning', Colors.orange),
                  if (med.afternoon)
                    _scheduleChip('☀️ Afternoon', Colors.amber),
                  if (med.night)
                    _scheduleChip('🌙 Night', Colors.indigo),
                  _scheduleChip(
                    med.beforeMeal
                        ? '🍽 Before meal'
                        : '🍽 After meal',
                    Colors.teal,
                  ),
                ]),
              ],
            ),
          )),

          if (_prescription!.suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            const TestSectionTitle(title: "Doctor's Suggestions"),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(_prescription!.suggestions,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _scheduleChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border:       Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label,
        style: TextStyle(
            color:    color,
            fontSize: 12,
            fontWeight: FontWeight.w500)),
  );
}