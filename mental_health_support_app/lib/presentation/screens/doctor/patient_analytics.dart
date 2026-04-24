import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/models/diary_entry.dart';
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
  static const Map<String, List<String>> _themePhrases = {
    'hopelessness': [
      'hopeless',
      'no hope',
      'nothing will get better',
      'it will never get better',
      'no point',
      'what is the point',
    ],
    'burden': [
      'burden',
      'better off without me',
      'people would be better without me',
      'i am worthless',
      'worthless',
      'useless',
    ],
    'withdrawal': [
      'alone',
      'isolated',
      'nobody understands',
      'no one cares',
      'want to disappear',
      'stay away from everyone',
    ],
    'distress': [
      'overwhelmed',
      "can't cope",
      'falling apart',
      'anxious',
      'panic',
      'scared',
      'tired of this',
    ],
    'worsening': [
      'getting worse',
      'worse every day',
      'again and again',
      'still the same',
      'nothing changed',
      'worse than before',
    ],
    'self_harm': [
      'hurt myself',
      'self harm',
      'cut myself',
      'want to die',
      'kill myself',
      'end my life',
      'suicide',
    ],
    'plan_preparation': [
      'i have a plan',
      'planned it',
      'prepared for it',
      'goodbye',
      'farewell',
      'final note',
      'last message',
    ],
  };

  List<DailyLog> _patientLogs = [];
  List<Map<String, dynamic>> _guardianLogs = [];
  List<DiaryEntry> _diaryEntries = [];
  Prescription? _prescription;
  _DiaryAnalysisSummary? _diarySnapshotSummary;
  String? _diaryDataNotice;
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
    final patientLogs = await _safeLoad(
      () => DoctorController.getDailyLogs(widget.patientUid, _fromDate, _toDate),
      <DailyLog>[],
      label: 'daily logs',
    );
    final guardianLogs = await _safeLoad(
      () => DoctorController.getGuardianLogs(widget.patientUid, _fromDate, _toDate),
      <Map<String, dynamic>>[],
      label: 'guardian logs',
    );
    final prescription = await _safeLoad(
      () => DoctorController.getActivePrescription(widget.patientUid),
      null,
      label: 'prescription',
    );

    List<DiaryEntry> diaryEntries = [];
    _DiaryAnalysisSummary? diarySnapshotSummary;
    String? diaryDataNotice;

    try {
      diaryEntries = await DoctorController.getDiaryEntries(
        widget.patientUid,
        _fromDate,
        _toDate,
      );
    } on FirebaseException catch (e) {
      debugPrint('Diary entry load error: $e');
      if (e.code == 'permission-denied') {
        diaryDataNotice =
            'Raw diary entries are blocked by Firestore rules for this doctor account.';
      } else {
        diaryDataNotice = 'Could not load raw diary entries.';
      }
    } catch (e) {
      debugPrint('Diary entry load error: $e');
      diaryDataNotice = 'Could not load raw diary entries.';
    }

    if (diaryEntries.isEmpty) {
      try {
        final snapshot =
            await DoctorController.getDiaryAnalysisSnapshot(widget.patientUid);
        if (snapshot != null) {
          diarySnapshotSummary = _DiaryAnalysisSummary.fromSnapshot(snapshot);
          diaryDataNotice = diaryDataNotice == null
              ? 'Showing the stored diary analysis snapshot for this patient.'
              : 'Showing the stored diary analysis snapshot because raw diary entries are blocked.';
        }
      } on FirebaseException catch (e) {
        debugPrint('Diary snapshot load error: $e');
        if (diaryDataNotice == null && e.code == 'permission-denied') {
          diaryDataNotice =
              'Diary analysis is also blocked by Firestore rules for this doctor account.';
        }
      } catch (e) {
        debugPrint('Diary snapshot load error: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _patientLogs = patientLogs;
      _guardianLogs = guardianLogs;
      _diaryEntries = diaryEntries;
      _prescription = prescription;
      _diarySnapshotSummary = diarySnapshotSummary;
      _diaryDataNotice = diaryDataNotice;
      _loading = false;
    });
  }

  Future<T> _safeLoad<T>(
    Future<T> Function() loader,
    T fallback, {
    required String label,
  }) async {
    try {
      return await loader();
    } catch (e) {
      debugPrint('Analytics $label load error: $e');
      return fallback;
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
                _summaryCard(
                  "Diary Status",
                  _diaryAnalysis.severityLabel,
                  _diaryEntries.isEmpty ? "No entries" : "${_diaryEntries.length} entries",
                ),
                const SizedBox(width: 12),
                _summaryCard("Avg Mood", _averageMoodLabel(), _moodSummaryEmoji()),
                const SizedBox(width: 12),
                _summaryCard("Adherence", _adherenceLabel(), _adherenceStatus()),
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

            const SizedBox(height: 24),
            _sectionTitle("Diary Analysis"),
            const SizedBox(height: 8),
            _diaryAnalysisCard(),

            const SizedBox(height: 20),
            _sectionTitle("Diary Evidence"),
            const SizedBox(height: 8),
            _diaryEvidenceCard(),

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

  _DiaryAnalysisSummary get _diaryAnalysis =>
      _diarySnapshotSummary ?? _buildDiaryAnalysis(_diaryEntries);

  String _averageMoodLabel() {
    if (_patientLogs.isEmpty) return "--";
    final total = _patientLogs.fold<int>(0, (sum, log) => sum + log.mood);
    final average = total / _patientLogs.length;
    return average.toStringAsFixed(1);
  }

  String _moodSummaryEmoji() {
    if (_patientLogs.isEmpty) return "No logs";
    final total = _patientLogs.fold<int>(0, (sum, log) => sum + log.mood);
    final average = (total / _patientLogs.length).round();
    return _moodEmoji(average);
  }

  String _adherenceLabel() {
    if (_patientLogs.isEmpty) return "--";
    final takenCount = _patientLogs.where((log) => log.medicationTaken).length;
    final percentage = ((takenCount / _patientLogs.length) * 100).round();
    return '$percentage%';
  }

  String _adherenceStatus() {
    if (_patientLogs.isEmpty) return "No logs";
    final takenCount = _patientLogs.where((log) => log.medicationTaken).length;
    final ratio = takenCount / _patientLogs.length;
    if (ratio >= 0.8) return "On track";
    if (ratio >= 0.5) return "Monitor";
    return "Low";
  }

  String _displayDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year} - $hour:$minute $suffix';
  }

  int _wordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  String _diaryPreview(String content) {
    final clean = content.trim();
    if (clean.length <= 140) return clean;
    return '${clean.substring(0, 140).trim()}...';
  }

  Widget _diaryAnalysisCard() {
    final summary = _diaryAnalysis;

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
              Icon(Icons.shield_outlined, color: summary.color),
              const SizedBox(width: 10),
              const Text(
                "Diary Analysis Outcome",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              _severityBadge(summary.severity, summary.color),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            summary.action,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.screeningNote,
            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.grey,
              height: 1.45,
            ),
          ),
          if (_diaryDataNotice != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kLightBlue.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBlue.withOpacity(0.12)),
              ),
              child: Text(
                _diaryDataNotice!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metricChip(
                label: 'Entries',
                value: '${summary.entryCount}',
                color: _kBlue,
              ),
              _metricChip(
                label: 'Latest',
                value: summary.lastEntryAt == null
                    ? 'No entry'
                    : _displayDate(summary.lastEntryAt!),
                color: Colors.indigo,
              ),
              if (summary.themeCounts.isNotEmpty)
                _metricChip(
                  label: 'Top themes',
                  value: summary.themeCounts.keys.take(2).join(', '),
                  color: Colors.orange,
                ),
              _metricChip(
                label: 'Evidence',
                value: '${summary.evidence.length}',
                color: summary.color,
              ),
            ],
          ),
          if (summary.themeCounts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.themeCounts.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: summary.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: summary.color.withOpacity(0.16)),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(
                      fontSize: 12,
                      color: summary.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _diaryEvidenceCard() {
    final summary = _diaryAnalysis;
    if (summary.evidence.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          "No diary analysis evidence available in the selected range.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: summary.evidence.take(4).map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kLightBlue.withOpacity(0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      size: 18,
                      color: _kBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _displayDate(item.timestamp),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (item.explicit)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Explicit',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.excerpt,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      item.theme,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.whyItMatters,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _severityBadge(String severity, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  int _countOccurrences(String text, String phrase) {
    var index = 0;
    var count = 0;

    while (true) {
      index = text.indexOf(phrase, index);
      if (index == -1) break;
      count++;
      index += phrase.length;
    }

    return count;
  }

  String _themeRationale(String theme) {
    const rationales = {
      'hopelessness': 'Hopeless language can indicate worsening depressive risk and needs follow-up.',
      'burden': 'Burden or worthlessness language can increase concern and requires review.',
      'withdrawal': 'Withdrawal and isolation language can indicate deteriorating engagement and support needs.',
      'distress': 'High distress language suggests current emotional strain and should be tracked.',
      'worsening': 'Repeated worsening language suggests decline over time rather than a one-off bad day.',
      'self_harm': 'Direct self-harm or suicide language requires immediate clinical review.',
      'plan_preparation': 'Planning or preparation language requires immediate escalation and human review.',
    };

    return rationales[theme] ?? 'Relevant text concern detected.';
  }

  _DiaryEntryAnalysis _analyzeDiaryEntry(DiaryEntry entry) {
    final rawText = entry.content;
    final text = rawText.toLowerCase();

    final themes = <String>[];
    final counts = <String, int>{};
    var score = 0;

    for (final theme in _themePhrases.entries) {
      var matchCount = 0;
      for (final phrase in theme.value) {
        if (text.contains(phrase)) {
          matchCount += _countOccurrences(text, phrase);
        }
      }
      if (matchCount > 0) {
        counts[theme.key] = matchCount;
        themes.add(theme.key);
      }
    }

    score += counts['distress'] ?? 0;
    score += counts['worsening'] ?? 0;
    score += counts['withdrawal'] ?? 0;
    score += (counts['hopelessness'] ?? 0) * 2;
    score += (counts['burden'] ?? 0) * 2;
    score += (counts['self_harm'] ?? 0) * 5;
    score += (counts['plan_preparation'] ?? 0) * 6;

    final explicitSelfHarm = (counts['self_harm'] ?? 0) > 0;
    final explicitPlan = (counts['plan_preparation'] ?? 0) > 0;

    final severity = explicitPlan || score >= 8
        ? 'critical'
        : explicitSelfHarm || score >= 5
            ? 'warning'
            : score >= 2
                ? 'watch'
                : 'stable';

    final evidence = themes.map((theme) {
      return _DiaryEvidenceItem(
        timestamp: entry.createdAt,
        theme: theme,
        excerpt: _diaryPreview(rawText),
        explicit: theme == 'self_harm' || theme == 'plan_preparation',
        whyItMatters: _themeRationale(theme),
      );
    }).toList();

    return _DiaryEntryAnalysis(
      entry: entry,
      severity: severity,
      themes: themes,
      evidence: evidence,
    );
  }

  _DiaryAnalysisSummary _buildDiaryAnalysis(List<DiaryEntry> entries) {
    if (entries.isEmpty) {
      return const _DiaryAnalysisSummary(
        entryCount: 0,
        severity: 'stable',
        action: 'Routine monitoring only.',
        screeningNote:
            'Diary analysis is supportive evidence only and does not replace validated screening such as PHQ-9, PHQ-A, GAD-7, ASQ, or C-SSRS workflows.',
        themeCounts: {},
        evidence: [],
        lastEntryAt: null,
      );
    }

    const severityRank = {
      'stable': 0,
      'watch': 1,
      'warning': 2,
      'critical': 3,
    };

    final analyzed = entries.map(_analyzeDiaryEntry).toList();
    final themeCounts = <String, int>{};
    final evidence = <_DiaryEvidenceItem>[];
    var recentWarningCount = 0;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    for (final item in analyzed) {
      for (final theme in item.themes) {
        themeCounts[theme] = (themeCounts[theme] ?? 0) + 1;
      }
      evidence.addAll(item.evidence);

      final created = DateTime.tryParse(item.entry.createdAt)?.toLocal();
      if (created != null &&
          created.isAfter(sevenDaysAgo) &&
          (severityRank[item.severity] ?? 0) >= 2) {
        recentWarningCount++;
      }
    }

    var overall = analyzed
        .map((item) => item.severity)
        .reduce((a, b) => (severityRank[a] ?? 0) >= (severityRank[b] ?? 0) ? a : b);

    if (overall != 'critical' && recentWarningCount >= 2) {
      overall = 'warning';
    }

    if (overall == 'stable' && themeCounts.values.fold<int>(0, (sum, v) => sum + v) >= 2) {
      overall = 'watch';
    }

    final sortedThemeEntries = themeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _DiaryAnalysisSummary(
      entryCount: entries.length,
      severity: overall,
      action: _actionForSeverity(overall),
      screeningNote:
          'Diary analysis is supportive evidence only and does not replace validated screening such as PHQ-9, PHQ-A, GAD-7, ASQ, or C-SSRS workflows.',
      themeCounts: {
        for (final entry in sortedThemeEntries) entry.key: entry.value,
      },
      evidence: evidence.take(20).toList(),
      lastEntryAt: entries.first.createdAt,
    );
  }

  String _actionForSeverity(String severity) {
    switch (severity) {
      case 'watch':
        return 'Show in dashboard and include in doctor digest.';
      case 'warning':
        return 'Same-day clinician review and acknowledgement required.';
      case 'critical':
        return 'Immediate human review and urgent clinician alert required.';
      case 'stable':
      default:
        return 'Routine monitoring only.';
    }
  }

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
    final mealLabel = (med.beforeMeal == true)
        ? 'Before Meal'
        : (med.afterMeal == true)
        ? 'After Meal'
        : 'No preference';

    final mealColor = (med.beforeMeal == true)
        ? Colors.orange
        : (med.afterMeal == true)
        ? Colors.green
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kLightBlue.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Name + tablet count badge ───────────
          Row(
            children: [
              const Icon(Icons.medication_rounded, color: _kBlue, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(med.dose,
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              // Tablet count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${med.tabletCount ?? 1} tab${(med.tabletCount ?? 1) == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: _kBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Meal timing + schedule ──────────────
          Row(
            children: [
              Icon(Icons.restaurant_outlined, size: 14, color: mealColor),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mealColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mealLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mealColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "${med.morning == true ? '🌅 ' : ''}"
                    "${med.afternoon == true ? '☀️ ' : ''}"
                    "${med.night == true ? '🌙' : ''}",
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Mood Line Chart Painter ───────────────────────────────────────────────────

class _DiaryAnalysisSummary {
  final int entryCount;
  final String severity;
  final String action;
  final String screeningNote;
  final Map<String, int> themeCounts;
  final List<_DiaryEvidenceItem> evidence;
  final String? lastEntryAt;

  const _DiaryAnalysisSummary({
    required this.entryCount,
    required this.severity,
    required this.action,
    required this.screeningNote,
    required this.themeCounts,
    required this.evidence,
    required this.lastEntryAt,
  });

  factory _DiaryAnalysisSummary.fromSnapshot(Map<String, dynamic> map) {
    final rawThemeCounts = map['themeCounts'];
    final themeCounts = <String, int>{};
    if (rawThemeCounts is Map) {
      rawThemeCounts.forEach((key, value) {
        final parsedValue = value is int ? value : int.tryParse('$value') ?? 0;
        themeCounts['$key'] = parsedValue;
      });
    }

    final rawEvidence = map['evidence'];
    final evidence = <_DiaryEvidenceItem>[];
    if (rawEvidence is List) {
      for (final item in rawEvidence) {
        if (item is Map<String, dynamic>) {
          evidence.add(_DiaryEvidenceItem.fromMap(item));
        } else if (item is Map) {
          evidence.add(_DiaryEvidenceItem.fromMap(item.cast<String, dynamic>()));
        }
      }
    }

    return _DiaryAnalysisSummary(
      entryCount: _toInt(map['entryCount']),
      severity: (map['severity'] ?? 'stable').toString(),
      action: (map['action'] ?? 'Routine monitoring only.').toString(),
      screeningNote: (map['screeningNote'] ??
              'Diary analysis is supportive evidence only and does not replace validated screening such as PHQ-9, PHQ-A, GAD-7, ASQ, or C-SSRS workflows.')
          .toString(),
      themeCounts: themeCounts,
      evidence: evidence,
      lastEntryAt: map['lastEntryAt']?.toString(),
    );
  }

  String get severityLabel {
    switch (severity) {
      case 'critical':
        return 'Critical';
      case 'warning':
        return 'Warning';
      case 'watch':
        return 'Watch';
      default:
        return 'Stable';
    }
  }

  Color get color {
    switch (severity) {
      case 'critical':
        return const Color(0xFFB42318);
      case 'warning':
        return const Color(0xFFB54708);
      case 'watch':
        return const Color(0xFF1D4ED8);
      default:
        return const Color(0xFF1F7A4D);
    }
  }
}

class _DiaryEvidenceItem {
  final String timestamp;
  final String theme;
  final String excerpt;
  final bool explicit;
  final String whyItMatters;

  const _DiaryEvidenceItem({
    required this.timestamp,
    required this.theme,
    required this.excerpt,
    required this.explicit,
    required this.whyItMatters,
  });

  factory _DiaryEvidenceItem.fromMap(Map<String, dynamic> map) {
    return _DiaryEvidenceItem(
      timestamp: (map['timestamp'] ?? map['createdAt'] ?? '').toString(),
      theme: (map['theme'] ?? 'text concern').toString(),
      excerpt: (map['excerpt'] ?? '').toString(),
      explicit: map['explicit'] == true,
      whyItMatters: (map['whyItMatters'] ?? 'Relevant text concern detected.')
          .toString(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

class _DiaryEntryAnalysis {
  final DiaryEntry entry;
  final String severity;
  final List<String> themes;
  final List<_DiaryEvidenceItem> evidence;

  const _DiaryEntryAnalysis({
    required this.entry,
    required this.severity,
    required this.themes,
    required this.evidence,
  });
}

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
