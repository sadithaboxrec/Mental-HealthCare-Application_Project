import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/models/prescription.dart';
import '../../../core/controllers/doctor_controller.dart';
import '../../components/test_section_title.dart';

class TestPatientAnalytics extends StatefulWidget {
  final AppUser doctorUser;
  final String  patientUid;
  final String  patientName;

  const TestPatientAnalytics({
    super.key,
    required this.doctorUser,
    required this.patientUid,
    required this.patientName,
  });

  @override
  State<TestPatientAnalytics> createState() =>
      _TestPatientAnalyticsState();
}

class _TestPatientAnalyticsState extends State<TestPatientAnalytics> {
  List<DailyLog>           _patientLogs  = [];
  List<Map<String,dynamic>> _guardianLogs = [];
  Prescription?            _prescription;
  bool   _loading         = true;
  bool   _showPatient     = true; // toggle between patient/guardian
  String _fromDate        = '';
  String _toDate          = '';

  @override
  void initState() {
    super.initState();
    _setRange();
    _load();
  }

  void _setRange() {
    final now  = DateTime.now();
    _toDate   = _fmt(now);
    _fromDate = _fmt(now.subtract(const Duration(days: 14)));
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        DoctorController.getDailyLogs(
            widget.patientUid, _fromDate, _toDate),
        DoctorController.getGuardianLogs(
            widget.patientUid, _fromDate, _toDate),
        DoctorController.getActivePrescription(widget.patientUid),
      ]);
      if (mounted) setState(() {
        _patientLogs  = results[0] as List<DailyLog>;
        _guardianLogs = results[1] as List<Map<String,dynamic>>;
        _prescription = results[2] as Prescription?;
        _loading      = false;
      });
    } catch (e) {
      debugPrint('Analytics load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickRange() async {
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
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('${widget.patientName} — Analytics'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.date_range), onPressed: _pickRange),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Date range ────────────────────────
          GestureDetector(
            onTap: _pickRange,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        Colors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.teal.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.date_range,
                    color: Colors.teal, size: 16),
                const SizedBox(width: 8),
                Text('$_fromDate  →  $_toDate',
                    style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                const Text('Change',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 11)),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── Patient / Guardian toggle bar ─────
          Container(
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _showPatient = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:        _showPatient
                        ? Colors.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person,
                          color: _showPatient
                              ? Colors.white : Colors.grey,
                          size: 16),
                      const SizedBox(width: 6),
                      Text('Patient Input',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:      _showPatient
                                ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
              )),
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _showPatient = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:        !_showPatient
                        ? Colors.orange : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield,
                          color: !_showPatient
                              ? Colors.white : Colors.grey,
                          size: 16),
                      const SizedBox(width: 6),
                      Text('Guardian Input',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:      !_showPatient
                                ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
              )),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Current Prescription ──────────────
          const TestSectionTitle(title: 'Current Prescription'),
          if (_prescription == null)
            const Text('No active prescription',
                style: TextStyle(color: Colors.grey))
          else
            ..._prescription!.medicines.map((med) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.medication,
                    color: Colors.teal, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(med.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500))),
                Text(med.dose,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 6),
                Text(
                  '${med.morning ? "🌅" : ""}${med.afternoon ? "☀️" : ""}${med.night ? "🌙" : ""}',
                  style: const TextStyle(fontSize: 12),
                ),
              ]),
            )),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // ── Charts ────────────────────────────
          if (_showPatient)
            _PatientCharts(logs: _patientLogs)
          else
            _GuardianCharts(logs: _guardianLogs),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}


// ── Patient charts ────────────────────────────────────────
class _PatientCharts extends StatelessWidget {
  final List<DailyLog> logs;
  const _PatientCharts({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No patient data in this range',
            style: TextStyle(color: Colors.grey)),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TestSectionTitle(title: 'Mood'),
        _barChart(logs.map((l) => _BarData(
          label: l.date.substring(5),
          value: l.mood.toDouble(),
          max:   5,
          color: _moodColor(l.mood),
        )).toList()),

        const SizedBox(height: 20),
        const TestSectionTitle(title: 'Water Intake (glasses)'),
        _barChart(logs.map((l) => _BarData(
          label: l.date.substring(5),
          value: l.waterIntake.toDouble(),
          max:   12,
          color: Colors.blue,
        )).toList()),

        const SizedBox(height: 20),
        const TestSectionTitle(title: 'Medication Adherence'),
        Wrap(spacing: 6, runSpacing: 6,
          children: logs.map((l) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color:        l.medicationTaken
                  ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: l.medicationTaken ? Colors.green : Colors.red),
            ),
            child: Column(children: [
              Text(l.date.substring(5),
                  style: const TextStyle(fontSize: 9)),
              Icon(l.medicationTaken ? Icons.check : Icons.close,
                  size: 14,
                  color: l.medicationTaken ? Colors.green : Colors.red),
            ]),
          )).toList(),
        ),

        const SizedBox(height: 20),
        const TestSectionTitle(title: 'Sleep'),
        Wrap(spacing: 6, runSpacing: 6,
          children: logs.map((l) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color:        Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Column(children: [
              Text(l.date.substring(5),
                  style: const TextStyle(fontSize: 9)),
              Text(l.sleepHours.isEmpty ? '—' : l.sleepHours,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          )).toList(),
        ),
      ],
    );
  }

  Color _moodColor(int m) {
    switch (m) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.amber;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }
}


// ── Guardian charts ───────────────────────────────────────
class _GuardianCharts extends StatelessWidget {
  final List<Map<String,dynamic>> logs;
  const _GuardianCharts({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No guardian data in this range',
            style: TextStyle(color: Colors.grey)),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TestSectionTitle(title: 'Mood (Guardian Observation)'),
        _barChart(logs.map((l) => _BarData(
          label: (l['date'] as String).substring(5),
          value: (l['mood'] as int? ?? 0).toDouble(),
          max:   5,
          color: Colors.orange,
        )).toList()),

        const SizedBox(height: 20),
        const TestSectionTitle(title: 'Water (Guardian Tracked)'),
        _barChart(logs.map((l) => _BarData(
          label: (l['date'] as String).substring(5),
          value: (l['waterIntake'] as int? ?? 0).toDouble(),
          max:   12,
          color: Colors.blue,
        )).toList()),

        const SizedBox(height: 20),
        const TestSectionTitle(title: 'Observations'),
        ...logs.where((l) =>
        (l['observations'] as String? ?? '').isNotEmpty).map((l) =>
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((l['date'] as String).substring(5),
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(l['observations'] as String? ?? '',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
        ),
      ],
    );
  }
}


// ── Shared bar chart ──────────────────────────────────────
class _BarData {
  final String label;
  final double value;
  final double max;
  final Color  color;
  const _BarData({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });
}

Widget _barChart(List<_BarData> data) {
  return SizedBox(
    height: 100,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((d) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(d.value > 0 ? d.value.toStringAsFixed(0) : '',
                  style: const TextStyle(fontSize: 8)),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: d.value > 0
                    ? (d.value / d.max) * 70 : 2,
                decoration: BoxDecoration(
                  color:        d.value > 0
                      ? d.color : Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 4),
              Text(d.label,
                  style: const TextStyle(fontSize: 8),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      )).toList(),
    ),
  );
}
