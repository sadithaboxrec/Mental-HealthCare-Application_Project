import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/prescription.dart';
import '../../../core/models/medicine.dart';
import '../../../core/models/appointment.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/controllers/doctor_controller.dart';

const _kBlue = Color(0xFF5BB8F5);
const _kLightBlue = Color(0xFFEAF5FD);
const _kBg = Color(0xFFF8FBFF);
const _kCard = Colors.white;
const _kBorder = Color(0xFFDAEEFB);

class PatientDetail extends StatefulWidget {
  final AppUser doctorUser;
  final String patientUid;
  final String patientName;

  const PatientDetail({
    super.key,
    required this.doctorUser,
    required this.patientUid,
    required this.patientName,
  });

  @override
  State<PatientDetail> createState() => _PatientDetailState();
}

class _PatientDetailState extends State<PatientDetail> {
  final _diagnosisCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _suggestionsCtrl = TextEditingController();

  String _nextApptDate = '';
  String _nextApptTime = '09:00';
  List<_MedEntry> _medicines = [];
  List<String> _medOptions = [];

  List<DailyLog> _patientLogs = [];
  List<Map<String, dynamic>> _guardianLogs = [];
  Prescription? _activePrescription;

  String _fromDate = '';
  String _toDate = '';

  bool _loadingForm = true;
  bool _loadingAnalytics = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _setDefaultRange();
    _loadAll();
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    _suggestionsCtrl.dispose();
    super.dispose();
  }

  void _setDefaultRange() {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 14));
    _toDate = _fmt(now);
    _fromDate = _fmt(from);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadAll() async {
    await Future.wait([_loadForm(), _loadAnalytics()]);
  }

  Future<void> _loadForm() async {
    setState(() => _loadingForm = true);
    try {
      final results = await Future.wait([
        DoctorController.getMedicineNames(),
        DoctorController.getActivePrescription(widget.patientUid),
      ]);
      _medOptions = results[0] as List<String>;
      _activePrescription = results[1] as Prescription?;

      if (_activePrescription != null) {
        _diagnosisCtrl.text = _activePrescription!.diagnosis;
        _notesCtrl.text = _activePrescription!.notes;
        _suggestionsCtrl.text = _activePrescription!.suggestions;
        _medicines = _activePrescription!.medicines
            .map((m) => _MedEntry.fromMedicine(m))
            .toList();
      }
      if (_medicines.isEmpty) _medicines.add(_MedEntry());
    } catch (e) {
      debugPrint('Load form error: $e');
    } finally {
      if (mounted) setState(() => _loadingForm = false);
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loadingAnalytics = true);
    try {
      final results = await Future.wait([
        DoctorController.getDailyLogs(widget.patientUid, _fromDate, _toDate),
        DoctorController.getGuardianLogs(widget.patientUid, _fromDate, _toDate),
      ]);
      if (mounted) {
        setState(() {
          _patientLogs = results[0] as List<DailyLog>;
          _guardianLogs = results[1] as List<Map<String, dynamic>>;
          _loadingAnalytics = false;
        });
      }
    } catch (e) {
      debugPrint('Load analytics error: $e');
      if (mounted) setState(() => _loadingAnalytics = false);
    }
  }

  Future<void> _save() async {
    if (_nextApptDate.isEmpty) {
      _snack('Set next appointment date');
      return;
    }
    if (_medicines.any((m) => m.selected == null)) {
      _snack('Select medicine for each entry');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Prescription'),
        content: const Text('Are you sure you want to save this prescription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kBlue),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now().toIso8601String();
      final prescription = Prescription(
        id: '',
        patientUid: widget.patientUid,
        doctorUid: widget.doctorUser.uid,
        patientName: widget.patientName,
        diagnosis: _diagnosisCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        suggestions: _suggestionsCtrl.text.trim(),
        nextAppointmentDate: _nextApptDate,
        isActive: true,
        medicines: _medicines.map((e) => e.toMedicine()).toList(),
        createdAt: now,
      );

      final appointment = Appointment(
        id: '',
        patientUid: widget.patientUid,
        doctorUid: widget.doctorUser.uid,
        patientName: widget.patientName,
        date: _nextApptDate,
        time: _nextApptTime,
        status: 'scheduled',
        createdAt: now,
      );

      await DoctorController.savePrescription(prescription);
      await DoctorController.saveAppointment(appointment);

      if (mounted) {
        _snack('✅ Saved Successfully');
        await _loadForm();
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _nextApptDate = _fmt(picked));
  }

  Future<void> _pickAnalyticsRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (range != null && mounted) {
      setState(() {
        _fromDate = _fmt(range.start);
        _toDate = _fmt(range.end);
      });
      _loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.patientName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loadingForm
          ? const Center(child: CircularProgressIndicator(color: _kBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Doctor Input'),
                  const SizedBox(height: 16),

                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Diagnosis',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _diagnosisCtrl,
                          maxLines: 2,
                          decoration: _inputDecoration('Enter diagnosis...'),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Clinical Notes',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            'Enter clinical notes...',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _sectionHeader('Medications'),
                  const SizedBox(height: 12),

                  ..._medicines.asMap().entries.map(
                    (e) => _medCard(e.key, e.value),
                  ),

                  const SizedBox(height: 8),

                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _medicines.add(_MedEntry())),
                    icon: const Icon(Icons.add, color: _kBlue),
                    label: const Text(
                      'Add Medicine',
                      style: TextStyle(color: _kBlue),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _sectionHeader('Suggestions for Patient'),
                  const SizedBox(height: 12),
                  _card(
                    child: TextField(
                      controller: _suggestionsCtrl,
                      maxLines: 3,
                      decoration: _inputDecoration('Enter suggestions...'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _sectionHeader('Next Appointment'),
                  const SizedBox(height: 12),
                  _card(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border: Border.all(color: _kBorder),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _nextApptDate.isEmpty
                                    ? 'Select Date'
                                    : _nextApptDate,
                                style: TextStyle(
                                  color: _nextApptDate.isEmpty
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null && mounted) {
                              setState(
                                () => _nextApptTime =
                                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: _kBorder),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_nextApptTime),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Prescription & Appointment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  _sectionHeader('Patient Analytics'),
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: _pickAnalyticsRange,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kLightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, color: _kBlue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$_fromDate → $_toDate',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Text('Change', style: TextStyle(color: _kBlue)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_loadingAnalytics)
                    const Center(
                      child: CircularProgressIndicator(color: _kBlue),
                    )
                  else
                    _AnalyticsChart(
                      patientLogs: _patientLogs,
                      guardianLogs: _guardianLogs,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) => Text(
    title,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  );

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBlue),
      ),
      contentPadding: const EdgeInsets.all(14),
    );
  }

  Widget _medCard(int index, _MedEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication, color: _kBlue, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: entry.selected,
                  hint: const Text('Select Medicine'),
                  items: _medOptions
                      .map(
                        (name) =>
                            DropdownMenuItem(value: name, child: Text(name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => entry.selected = val),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 24,
                ),
                onPressed: () {
                  if (_medicines.length > 1) {
                    setState(() => _medicines.removeAt(index));
                  } else {
                    _snack("At least one medicine is required");
                  }
                },
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text('8th Dec 2025', style: TextStyle(fontSize: 13)),
              const Spacer(),
              const Icon(Icons.access_time, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(_nextApptTime, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Medicine entry model ──────────────────────────────
class _MedEntry {
  String? selected;
  final doseCtrl = TextEditingController();
  bool beforeMeal = false;
  bool morning = false;
  bool afternoon = false;
  bool night = false;

  static _MedEntry fromMedicine(Medicine m) {
    final e = _MedEntry();
    e.selected = m.name;
    e.doseCtrl.text = m.dose;
    e.beforeMeal = m.beforeMeal;
    e.morning = m.morning;
    e.afternoon = m.afternoon;
    e.night = m.night;
    return e;
  }

  Medicine toMedicine() => Medicine(
    name: selected ?? '',
    dose: doseCtrl.text.trim(),
    beforeMeal: beforeMeal,
    morning: morning,
    afternoon: afternoon,
    night: night,
  );
}

// ── Analytics chart ───────────────────────────────────
class _AnalyticsChart extends StatelessWidget {
  final List<DailyLog> patientLogs;
  final List<Map<String, dynamic>> guardianLogs;

  const _AnalyticsChart({
    required this.patientLogs,
    required this.guardianLogs,
  });

  @override
  Widget build(BuildContext context) {
    if (patientLogs.isEmpty) {
      return const Center(
        child: Text(
          "No analytics data available",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mood Trend",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: patientLogs.length > 7 ? 7 : patientLogs.length,
            itemBuilder: (context, index) {
              final log = patientLogs[index];
              return Container(
                width: 70,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Text(
                      _moodEmoji(log.mood),
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      log.date.substring(5),
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      "Mood ${log.mood}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _moodEmoji(int mood) {
    switch (mood) {
      case 1:
        return "😢";
      case 2:
        return "🙁";
      case 3:
        return "😐";
      case 4:
        return "🙂";
      case 5:
        return "😊";
      default:
        return "😶";
    }
  }
}
