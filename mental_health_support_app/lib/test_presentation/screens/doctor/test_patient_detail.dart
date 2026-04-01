import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/prescription.dart';
import '../../../core/models/medicine.dart';
import '../../../core/models/appointment.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/controllers/doctor_controller.dart';
import '../../components/test_button.dart';
import '../../components/test_section_title.dart';

class TestPatientDetail extends StatefulWidget {
  final AppUser doctorUser;
  final String  patientUid;
  final String  patientName;

  const TestPatientDetail({
    super.key,
    required this.doctorUser,
    required this.patientUid,
    required this.patientName,
  });

  @override
  State<TestPatientDetail> createState() => _TestPatientDetailState();
}

class _TestPatientDetailState extends State<TestPatientDetail> {
  // ── Prescription form state ───────────────────────────
  final _diagnosisCtrl   = TextEditingController();
  final _notesCtrl       = TextEditingController();
  final _suggestionsCtrl = TextEditingController();
  String  _nextApptDate  = '';
  String  _nextApptTime  = '09:00';
  List<_MedEntry> _medicines = [];
  List<String>    _medOptions = [];

  // ── Analytics state ───────────────────────────────────
  List<DailyLog>           _patientLogs  = [];
  List<Map<String,dynamic>> _guardianLogs = [];
  Prescription?            _activePrescription;
  String _fromDate = '';
  String _toDate   = '';

  bool _loadingForm      = true;
  bool _loadingAnalytics = true;
  bool _saving           = false;

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
    final now  = DateTime.now();
    final from = now.subtract(const Duration(days: 14));
    _toDate   = _fmt(now);
    _fromDate = _fmt(from);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

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
      _medOptions         = results[0] as List<String>;
      _activePrescription = results[1] as Prescription?;

      // Pre-fill from active prescription
      if (_activePrescription != null) {
        _diagnosisCtrl.text   = _activePrescription!.diagnosis;
        _notesCtrl.text       = _activePrescription!.notes;
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
        DoctorController.getDailyLogs(
            widget.patientUid, _fromDate, _toDate),
        DoctorController.getGuardianLogs(
            widget.patientUid, _fromDate, _toDate),
      ]);
      if (mounted) setState(() {
        _patientLogs  = results[0] as List<DailyLog>;
        _guardianLogs = results[1] as List<Map<String,dynamic>>;
        _loadingAnalytics = false;
      });
    } catch (e) {
      debugPrint('Load analytics error: $e');
      if (mounted) setState(() => _loadingAnalytics = false);
    }
  }

  // Future<void> _save() async {
  //   if (_nextApptDate.isEmpty) {
  //     _snack('Set next appointment date');
  //     return;
  //   }
  //   if (_medicines.any((m) => m.selected == null)) {
  //     _snack('Select medicine for each entry');
  //     return;
  //   }
  //
  //   setState(() => _saving = true);
  //
  //   try {
  //     final now = DateTime.now().toIso8601String();
  //
  //     final prescription = Prescription(
  //       id:                  '',
  //       patientUid:          widget.patientUid,
  //       doctorUid:           widget.doctorUser.uid,
  //       patientName:         widget.patientName,
  //       diagnosis:           _diagnosisCtrl.text.trim(),
  //       notes:               _notesCtrl.text.trim(),
  //       suggestions:         _suggestionsCtrl.text.trim(),
  //       nextAppointmentDate: _nextApptDate,
  //       isActive:            true,
  //       medicines:           _medicines.map((e) => e.toMedicine()).toList(),
  //       createdAt:           now,
  //     );
  //
  //     final appointment = Appointment(
  //       id:          '',
  //       patientUid:  widget.patientUid,
  //       doctorUid:   widget.doctorUser.uid,
  //       patientName: widget.patientName,
  //       date:        _nextApptDate,
  //       time:        _nextApptTime,
  //       status:      'scheduled',
  //       createdAt:   now,
  //     );
  //
  //     await DoctorController.savePrescription(prescription);
  //     await DoctorController.saveAppointment(appointment);
  //
  //     if (mounted) {
  //       _snack('✅ Prescription and appointment saved');
  //       await _loadForm();
  //     }
  //   } catch (e) {
  //     _snack('Error: $e');
  //   } finally {
  //     if (mounted) setState(() => _saving = false);
  //   }
  // }


  Future<void> _save() async {
    if (_nextApptDate.isEmpty) {
      _snack('Set next appointment date');
      return;
    }
    if (_medicines.any((m) => m.selected == null)) {
      _snack('Select medicine for each entry');
      return;
    }

    // ── Confirmation dialog ─────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Prescription'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Patient: ${widget.patientName}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              const Text('Medicines:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ..._medicines.map((m) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• ${m.selected ?? "?"} — ${m.doseCtrl.text}\n'
                      '  ${m.morning ? "🌅" : ""}${m.afternoon ? "☀️" : ""}${m.night ? "🌙" : ""} '
                      '${m.beforeMeal ? "Before meal" : "After meal"}',
                  style: const TextStyle(fontSize: 13),
                ),
              )),
              const Divider(),
              if (_diagnosisCtrl.text.isNotEmpty)
                Text('Diagnosis: ${_diagnosisCtrl.text}'),
              if (_suggestionsCtrl.text.isNotEmpty)
                Text('Suggestions: ${_suggestionsCtrl.text}'),
              const Divider(),
              Text('Next Appointment: $_nextApptDate at $_nextApptTime',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Confirm & Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now().toIso8601String();
      final prescription = Prescription(
        id: '', patientUid: widget.patientUid,
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
        id: '', patientUid: widget.patientUid,
        doctorUid: widget.doctorUser.uid,
        patientName: widget.patientName,
        date: _nextApptDate, time: _nextApptTime,
        status: 'scheduled', createdAt: now,
      );
      await DoctorController.savePrescription(prescription);
      await DoctorController.saveAppointment(appointment);
      if (mounted) {
        _snack('✅ Saved');
        await _loadForm();
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _nextApptDate = _fmt(picked));
    }
  }

  Future<void> _pickAnalyticsRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate:  DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.parse(_fromDate),
        end:   DateTime.parse(_toDate),
      ),
    );
    if (range != null && mounted) {
      setState(() {
        _fromDate = _fmt(range.start);
        _toDate   = _fmt(range.end);
      });
      _loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('[TEST] ${widget.patientName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _loadingForm
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ══ DOCTOR INPUT SECTION ══════════════
          _sectionHeader('Doctor Input', Colors.blue),
          const SizedBox(height: 12),

          // Diagnosis
          const TestSectionTitle(title: 'Diagnosis'),
          TextField(
            controller: _diagnosisCtrl,
            maxLines: 3,
            decoration: _inputDec('Enter diagnosis...'),
          ),
          const SizedBox(height: 12),

          // Notes
          const TestSectionTitle(title: 'Clinical Notes'),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: _inputDec('Enter notes...'),
          ),
          const SizedBox(height: 12),

          // Medicines
          TestSectionTitle(
            title: 'Medicines',
            subtitle: _activePrescription != null
                ? 'Pre-filled from active prescription' : null,
          ),
          ..._medicines.asMap().entries.map((e) =>
              _MedEntryWidget(
                key:     ValueKey(e.key),
                entry:   e.value,
                index:   e.key,
                options: _medOptions,
                onRemove: e.key == 0 ? null : () =>
                    setState(() => _medicines.removeAt(e.key)),
                onChanged: () => setState(() {}),
              ),
          ),

          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Medicine'),
            onPressed: () =>
                setState(() => _medicines.add(_MedEntry())),
          ),
          const SizedBox(height: 12),

          // Suggestions
          const TestSectionTitle(title: 'Suggestions for Patient'),
          TextField(
            controller: _suggestionsCtrl,
            maxLines: 3,
            decoration: _inputDec('Enter suggestions...'),
          ),
          const SizedBox(height: 16),

          // Next appointment
          const TestSectionTitle(title: 'Next Appointment'),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:        Colors.white,
                    border:       Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _nextApptDate.isEmpty
                        ? 'Tap to pick date' : _nextApptDate,
                    style: TextStyle(
                        color: _nextApptDate.isEmpty
                            ? Colors.grey : Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Time picker
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour:   int.parse(_nextApptTime.split(':')[0]),
                    minute: int.parse(_nextApptTime.split(':')[1]),
                  ),
                );
                if (t != null && mounted) {
                  setState(() => _nextApptTime =
                  '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  border:       Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_nextApptTime),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          TestButton(
            label:     'Save Prescription & Appointment',
            onPressed: _save,
            isLoading: _saving,
            color:     Colors.blue,
          ),

          const SizedBox(height: 32),
          const Divider(thickness: 2),
          const SizedBox(height: 16),

          // ══ ANALYTICS SECTION ═════════════════
          _sectionHeader('Patient Analytics', Colors.teal),
          const SizedBox(height: 12),

          // Date range picker
          GestureDetector(
            onTap: _pickAnalyticsRange,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        Colors.teal.withOpacity(0.08),
                border:       Border.all(
                    color: Colors.teal.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(children: [
                const Icon(Icons.date_range,
                    color: Colors.teal, size: 18),
                const SizedBox(width: 8),
                Text('$_fromDate  →  $_toDate',
                    style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                const Text('Tap to change',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 11)),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          if (_loadingAnalytics)
            const Center(child: CircularProgressIndicator())
          else ...[
            _AnalyticsChart(
              patientLogs:  _patientLogs,
              guardianLogs: _guardianLogs,
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border:       Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(title,
        style: TextStyle(
            color:      color,
            fontWeight: FontWeight.bold,
            fontSize:   15)),
  );

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText:    hint,
    hintStyle:   const TextStyle(color: Colors.grey, fontSize: 13),
    filled:      true,
    fillColor:   Colors.white,
    border:      OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    contentPadding: const EdgeInsets.all(12),
  );
}


// ── Medicine entry state ──────────────────────────────────
class _MedEntry {
  String? selected;
  final doseCtrl = TextEditingController();
  bool beforeMeal = false;
  bool morning    = false;
  bool afternoon  = false;
  bool night      = false;

  static _MedEntry fromMedicine(Medicine m) {
    final e = _MedEntry();
    e.selected   = m.name;
    e.doseCtrl.text = m.dose;
    e.beforeMeal = m.beforeMeal;
    e.morning    = m.morning;
    e.afternoon  = m.afternoon;
    e.night      = m.night;
    return e;
  }

  Medicine toMedicine() => Medicine(
    name:       selected ?? '',
    dose:       doseCtrl.text.trim(),
    beforeMeal: beforeMeal,
    morning:    morning,
    afternoon:  afternoon,
    night:      night,
  );
}


class _MedEntryWidget extends StatefulWidget {
  final _MedEntry    entry;
  final int          index;
  final List<String> options;
  final VoidCallback? onRemove;
  final VoidCallback  onChanged;

  const _MedEntryWidget({
    super.key,
    required this.entry,
    required this.index,
    required this.options,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_MedEntryWidget> createState() => _MedEntryWidgetState();
}

class _MedEntryWidgetState extends State<_MedEntryWidget> {
  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Medicine ${widget.index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (widget.onRemove != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                onPressed: widget.onRemove,
              ),
          ]),

          DropdownButtonFormField<String>(
            value:      e.selected,
            hint:       const Text('Select Medicine'),
            isExpanded: true,
            items: widget.options.map((n) =>
                DropdownMenuItem(value: n, child: Text(n))).toList(),
            onChanged: (v) =>
                setState(() { e.selected = v; widget.onChanged(); }),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: e.doseCtrl,
            decoration: InputDecoration(
              hintText: 'Dose (e.g. 1 tablet, 5ml)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),

          // Time checkboxes
          Wrap(spacing: 8, children: [
            _cb('Morning',   e.morning,
                    (v) => setState(() { e.morning   = v!; widget.onChanged(); })),
            _cb('Afternoon', e.afternoon,
                    (v) => setState(() { e.afternoon = v!; widget.onChanged(); })),
            _cb('Night',     e.night,
                    (v) => setState(() { e.night     = v!; widget.onChanged(); })),
          ]),

          // Before/after meal
          Row(children: [
            Radio<bool>(
              value: true, groupValue: e.beforeMeal,
              onChanged: (v) =>
                  setState(() { e.beforeMeal = v!; widget.onChanged(); }),
            ),
            const Text('Before meal', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 12),
            Radio<bool>(
              value: false, groupValue: e.beforeMeal,
              onChanged: (v) =>
                  setState(() { e.beforeMeal = v!; widget.onChanged(); }),
            ),
            const Text('After meal', style: TextStyle(fontSize: 13)),
          ]),
        ],
      ),
    );
  }

  Widget _cb(String label, bool val, Function(bool?) onChange) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Checkbox(value: val, onChanged: onChange),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]);
}


// ── Analytics chart widget ────────────────────────────────
class _AnalyticsChart extends StatelessWidget {
  final List<DailyLog>           patientLogs;
  final List<Map<String,dynamic>> guardianLogs;

  const _AnalyticsChart({
    required this.patientLogs,
    required this.guardianLogs,
  });

  @override
  Widget build(BuildContext context) {
    if (patientLogs.isEmpty && guardianLogs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No data in this range',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // Build a set of all dates
    final dates = <String>{};
    for (final l in patientLogs)  dates.add(l.date);
    // for (final l in guardianLogs) dates.add(l.date as String? ?? '');
     List<DailyLog> _guardianLogs = [];
    final sorted = dates.toList()..sort();



    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Mood chart (simple bar) ───────────────────
        const TestSectionTitle(title: 'Mood (Patient vs Guardian)'),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: sorted.map((date) {
              final pLog = _patientForDate(date);
              final gLog = _guardianForDate(date);
              final pMood = pLog?.mood ?? 0;
              final gMood = gLog != null
                  ? (gLog['mood'] as int? ?? 0) : 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (pMood > 0)
                            Container(
                              width:  10,
                              height: pMood * 16.0,
                              color:  Colors.green.withOpacity(0.7),
                            ),
                          const SizedBox(width: 2),
                          if (gMood > 0)
                            Container(
                              width:  10,
                              height: gMood * 16.0,
                              color:  Colors.orange.withOpacity(0.7),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(date.substring(5),
                          style: const TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Row(children: [
          _legend(Colors.green,  'Patient'),
          const SizedBox(width: 12),
          _legend(Colors.orange, 'Guardian'),
        ]),

        const SizedBox(height: 20),

        // ── Water intake ──────────────────────────────
        const TestSectionTitle(title: 'Water Intake (glasses/day)'),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: sorted.map((date) {
              final log   = _patientForDate(date);
              final water = log?.waterIntake ?? 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: water > 0 ? water * 8.0 : 2,
                        color:  Colors.blue.withOpacity(0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(date.substring(5),
                          style: const TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // ── Medication adherence ──────────────────────
        const TestSectionTitle(title: 'Medication Adherence'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: sorted.map((date) {
            final log   = _patientForDate(date);
            final taken = log?.medicationTaken ?? false;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:        taken
                    ? Colors.green.withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: taken ? Colors.green : Colors.red,
                    width: 0.8),
              ),
              child: Column(children: [
                Text(date.substring(5),
                    style: const TextStyle(fontSize: 9)),
                Icon(taken ? Icons.check : Icons.close,
                    size: 14,
                    color: taken ? Colors.green : Colors.red),
              ]),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // ── Daily log table ───────────────────────────
        const TestSectionTitle(title: 'Daily Detail'),
        Table(
          border:           TableBorder.all(color: Colors.grey.shade200),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(2),
          },
          children: [
            _tableRow(['Date', 'Mood', 'Water', 'Sleep'], isHeader: true),
            ...sorted.map((date) {
              final log = _patientForDate(date);
              return _tableRow([
                date.substring(5),
                log?.mood.toString() ?? '—',
                log != null ? '${log.waterIntake}g' : '—',
                log?.sleepHours.isEmpty ?? true ? '—' : log!.sleepHours,
              ]);
            }),
          ],
        ),
      ],
    );
  }

  DailyLog? _patientForDate(String date) {
    try { return patientLogs.firstWhere((l) => l.date == date); }
    catch (_) { return null; }
  }

  Map<String,dynamic>? _guardianForDate(String date) {
    try { return guardianLogs.firstWhere((l) => l['date'] == date); }
    catch (_) { return null; }
  }

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );

  TableRow _tableRow(List<String> cells, {bool isHeader = false}) =>
      TableRow(
        decoration: isHeader
            ? BoxDecoration(color: Colors.grey.shade100) : null,
        children: cells.map((c) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text(c,
              style: TextStyle(
                  fontSize:   11,
                  fontWeight: isHeader
                      ? FontWeight.bold : FontWeight.normal)),
        )).toList(),
      );
}