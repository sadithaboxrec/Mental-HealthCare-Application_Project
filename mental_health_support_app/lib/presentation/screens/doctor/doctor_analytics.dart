import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/models/prescription.dart';
import '../../../core/controllers/doctor_controller.dart';

const _kBlue = Color(0xFF5BB8F5);
const _kLightBlue = Color(0xFFEAF5FD);
const _kBg = Color(0xFFF8FBFF);
const _kCard = Colors.white;

class PatientAnalytics extends StatefulWidget {
  final AppUser doctorUser;
  final String patientUid;
  final String patientName;

  const PatientAnalytics({
    super.key,
    required this.doctorUser,
    required this.patientUid,
    required this.patientName,
  });

  @override
  State<PatientAnalytics> createState() => _PatientAnalyticsState();
}

class _PatientAnalyticsState extends State<PatientAnalytics> {
  List<DailyLog> _patientLogs = [];
  List<Map<String, dynamic>> _guardianLogs = [];
  Prescription? _prescription;
  bool _loading = true;
  bool _showPatient = true;

  int _period = 0;
  String _fromDate = '';
  String _toDate = '';

  @override
  void initState() {
    super.initState();
    _setRange();
    _load();
  }

  void _setRange() {
    final now = DateTime.now();
    _toDate = _fmt(now);
    _fromDate = _fmt(now.subtract(const Duration(days: 30)));
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        DoctorController.getDailyLogs(widget.patientUid, _fromDate, _toDate),
        DoctorController.getGuardianLogs(widget.patientUid, _fromDate, _toDate),
        DoctorController.getActivePrescription(widget.patientUid),
      ]);
      if (mounted) {
        setState(() {
          _patientLogs = results[0] as List<DailyLog>;
          _guardianLogs = results[1] as List<Map<String, dynamic>>;
          _prescription = results[2] as Prescription?;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Analytics load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickRange() async {
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
      _load();
    }
  }

  String _getPeriodTitle() {
    switch (_period) {
      case 0:
        return "This Week";
      case 1:
        return "This Month";
      default:
        return "This Year";
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.patientName,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Patient Analytics",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Summary cards ─────────────────────
                  Row(
                    children: [
                      _summaryCard("Sessions", "24", "This month"),
                      const SizedBox(width: 12),
                      _summaryCard("Avg Mood", "3.8", "😊"),
                      const SizedBox(width: 12),
                      _summaryCard("Adherence", "85%", "✅"),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Period toggle ─────────────────────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _kLightBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: ["Week", "Month", "Year"].asMap().entries.map((e) {
                        final active = e.key == _period;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _period = e.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: active ? _kBlue : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    color: active ? Colors.white : Colors.grey.shade700,
                                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Mood trend ────────────────────────
                  _sectionTitle("Mood Trend"),
                  const SizedBox(height: 8),
                  _moodTrendCard(),

                  const SizedBox(height: 24),

                  _sectionTitle("Water Intake"),
                  _statsBar(
                    "Water",
                    _patientLogs,
                    (log) => log.waterIntake.toDouble(),
                    "💧",
                    Colors.blue,
                  ),

                  const SizedBox(height: 20),
                  _sectionTitle("Sleep Hours"),
                  _statsBar(
                    "Sleep",
                    _patientLogs,
                    (log) => double.tryParse(log.sleepHours) ?? 0,
                    "🌙",
                    Colors.indigo,
                  ),

                  const SizedBox(height: 20),
                  _sectionTitle("Medication Adherence"),
                  _medicationAdherenceCard(),

                  const SizedBox(height: 28),

                  // ── Current prescription ──────────────
                  _sectionTitle("Current Prescription"),
                  if (_prescription == null)
                    const Text(
                      "No active prescription found",
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ..._prescription!.medicines.map((med) => _medicineTile(med)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard(String title, String value, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _kBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      );

  Widget _moodTrendCard() {
    final logs = _showPatient ? _patientLogs : _guardianLogs;
    if (logs.isEmpty) {
      return const Center(
        child: Text("No data available", style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getPeriodTitle(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showPatient = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _showPatient ? _kBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Patient",
                        style: TextStyle(
                          color: _showPatient ? Colors.white : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showPatient = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: !_showPatient ? Colors.orange : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Guardian",
                        style: TextStyle(
                          color: !_showPatient ? Colors.white : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _emojiMoodBar(logs),
        ],
      ),
    );
  }

  Widget _emojiMoodBar(dynamic logs) {
    final count = logs.length > 7 ? 7 : logs.length;

    final moodValues = List.generate(count, (i) {
      final log = logs[i];
      return _showPatient
          ? (log as DailyLog).mood.toDouble()
          : (log['mood'] as int? ?? 3).toDouble();
    });

    final dates = List.generate(count, (i) {
      final log = logs[i];
      return _showPatient
          ? (log as DailyLog).date.substring(5)
          : (log['date'] as String).substring(5);
    });

    const double itemWidth = 60;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: count * itemWidth,
        child: Column(
          children: [
            // ── Emoji row ──────────────────────
            Row(
              children: List.generate(count, (i) {
                final mood = moodValues[i].toInt();
                return SizedBox(
                  width: itemWidth,
                  child: Column(
                    children: [
                      Text(_moodEmoji(mood), style: const TextStyle(fontSize: 34)),
                      const SizedBox(height: 4),
                      Text(
                        "$mood",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 10),

            // ── Line chart ──────────────────────
            SizedBox(
              height: 110,
              child: CustomPaint(
                painter: _MoodLinePainter(moodValues, _showPatient ? _kBlue : Colors.orange),
                child: Row(
                  children: dates.map((d) {
                    return SizedBox(
                      width: itemWidth,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            d,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _statsBar(
    String title,
    List<DailyLog> logs,
    double Function(DailyLog) getValue,
    String emoji,
    Color color,
  ) {
    if (logs.isEmpty) return const SizedBox();
    final maxValue = logs.map(getValue).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...logs.take(7).map((log) {
            final value = getValue(log);
            final percent = maxValue > 0 ? (value / maxValue) * 100 : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      log.date.substring(5),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        backgroundColor: color.withOpacity(0.15),
                        color: color,
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _medicationAdherenceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Medication Taken",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _patientLogs.take(7).map((log) {
              final taken = log.medicationTaken;
              return Chip(
                label: Text(log.date.substring(5)),
                avatar: Icon(
                  taken ? Icons.check_circle : Icons.cancel,
                  color: taken ? Colors.green : Colors.red,
                ),
                backgroundColor: taken ? Colors.green.shade50 : Colors.red.shade50,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _medicineTile(dynamic med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kLightBlue.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.medication_rounded, color: _kBlue, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  med.dose,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            "${med.morning ? '🌅 ' : ''}${med.afternoon ? '☀️ ' : ''}${med.night ? '🌙' : ''}",
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

// ── Mood Line Chart Painter ───────────────────────────────────────────────────

class _MoodLinePainter extends CustomPainter {
  final List<double> moods;
  final Color color;

  _MoodLinePainter(this.moods, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (moods.length < 2) return;

    const double minMood = 1;
    const double maxMood = 5;
    const double bottomPad = 20; // space for date labels
    const double topPad = 10;
    final chartHeight = size.height - bottomPad - topPad;
    final stepX = size.width / (moods.length - 1);

    Offset toOffset(int i) {
      final x = i * stepX;
      final normalized = (moods[i] - minMood) / (maxMood - minMood);
      final y = topPad + chartHeight * (1 - normalized);
      return Offset(x, y);
    }

    // ── Filled gradient area ──────────────
    final fillPath = Path();
    fillPath.moveTo(toOffset(0).dx, size.height - bottomPad);
    for (int i = 0; i < moods.length; i++) {
      if (i == 0) {
        fillPath.lineTo(toOffset(0).dx, toOffset(0).dy);
      } else {
        final prev = toOffset(i - 1);
        final curr = toOffset(i);
        final cpX = (prev.dx + curr.dx) / 2;
        fillPath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }
    }
    fillPath.lineTo(toOffset(moods.length - 1).dx, size.height - bottomPad);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // ── Smooth line ───────────────────────
    final linePath = Path();
    linePath.moveTo(toOffset(0).dx, toOffset(0).dy);
    for (int i = 1; i < moods.length; i++) {
      final prev = toOffset(i - 1);
      final curr = toOffset(i);
      final cpX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Dots ──────────────────────────────
    for (int i = 0; i < moods.length; i++) {
      final o = toOffset(i);
      // white fill
      canvas.drawCircle(o, 5, Paint()..color = Colors.white);
      // colored border
      canvas.drawCircle(
        o,
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_MoodLinePainter old) =>
      old.moods != moods || old.color != color;
}