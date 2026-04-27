import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/controllers/doctor_controller.dart';
import 'package:mental_health_support_app/core/models/prescription.dart';
import 'package:mental_health_support_app/core/models/medicine.dart';
import 'package:mental_health_support_app/core/models/appointment.dart';
import 'package:mental_health_support_app/core/models/daily_log.dart';
import 'package:mental_health_support_app/presentation/components/atoms/severity_badge.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final String patientUid;
  const PatientDetailScreen({super.key, required this.patientUid});

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  int _selectedTab = 0;
  Map<String, dynamic>? _patient;
  Map<String, dynamic>? _xaiData;
  Prescription? _prescription;
  List<DailyLog> _dailyLogs = [];
  bool _loading = true;

  // On web: Overview is always visible in left panel — tabs exclude it.
  // On mobile: Overview is the first tab.
  static const _mobileTabs = ['Overview', 'Analytics', 'Treatment', 'History'];
  static const _webTabs = ['Analytics', 'Treatment', 'History'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final patDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientUid)
          .get();
      final xaiDoc = await FirebaseFirestore.instance
          .collection('analytics_snapshots')
          .doc(widget.patientUid)
          .get();

      final prescription = await DoctorController.getActivePrescription(
        widget.patientUid,
      );

      final from = DateTime.now().subtract(const Duration(days: 30));
      final fromStr = DateFormat('yyyy-MM-dd').format(from);
      final toStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      List<DailyLog> logs = [];
      try {
        logs = await DoctorController.getDailyLogs(
          widget.patientUid,
          fromStr,
          toStr,
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          _patient = patDoc.data();
          _xaiData = xaiDoc.exists ? xaiDoc.data() : null;
          _prescription = prescription;
          _dailyLogs = logs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _severityFromXai() {
    if (_xaiData == null) return 'stable';
    final raw =
        (_xaiData!['severity'] as String? ??
                _xaiData!['riskLevel'] as String? ??
                'stable')
            .toLowerCase();
    if (raw.contains('critical')) return 'critical';
    if (raw.contains('warning') || raw.contains('high')) return 'warning';
    if (raw.contains('watch') || raw.contains('moderate')) return 'watch';
    return 'stable';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.mist,
        body: Column(
          children: [
            Container(
              height: 180 + MediaQuery.of(context).padding.top,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.sky, AppColors.mint],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    children: [
                      Semantics(
                        label: 'Go back',
                        button: true,
                        child: IconButton(
                          icon: PhosphorIcon(
                            PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular),
                            color: AppColors.ink,
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.skyDeep),
              ),
            ),
          ],
        ),
      );
    }

    final severity = _severityFromXai();
    final doctorUid =
        ref.read(currentUserDocProvider).asData?.value?['uid'] as String? ?? '';
    final width = MediaQuery.of(context).size.width;
    final isWide = kIsWeb || width >= 800;

    if (isWide) {
      // ── Web: two-panel dashboard layout ────────────────────────────────────
      final webTabContent = [
        _AnalyticsTab(dailyLogs: _dailyLogs, xaiData: _xaiData),
        _TreatmentTab(
          prescription: _prescription,
          patientUid: widget.patientUid,
          patientDoc: _patient,
          onRefresh: _load,
          doctorUid: doctorUid,
        ),
        _HistoryTab(patientUid: widget.patientUid),
      ];
      return Scaffold(
        backgroundColor: AppColors.mist,
        body: Column(
          children: [
            _PatientHeader(
              patient: _patient,
              xaiData: _xaiData,
              severity: severity,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left panel: always-visible overview (380px)
                  SizedBox(
                    width: 380,
                    child: Container(
                      color: AppColors.cloud,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        child: _XaiInsightCard(
                          xaiData: _xaiData,
                          severity: severity,
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.divider),
                  // Right panel: tabbed
                  Expanded(
                    child: Column(
                      children: [
                        _TabBar(
                          tabs: _webTabs,
                          selected: _selectedTab,
                          onSelect: (i) => setState(() => _selectedTab = i),
                        ),
                        Expanded(
                          child:
                              webTabContent[_selectedTab.clamp(
                                0,
                                webTabContent.length - 1,
                              )],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile: original vertical tab layout ────────────────────────────────
    final mobileTabContent = [
      _OverviewTab(
        xaiData: _xaiData,
        severity: severity,
        patientUid: widget.patientUid,
      ),
      _AnalyticsTab(dailyLogs: _dailyLogs, xaiData: _xaiData),
      _TreatmentTab(
        prescription: _prescription,
        patientUid: widget.patientUid,
        patientDoc: _patient,
        onRefresh: _load,
        doctorUid: doctorUid,
      ),
      _HistoryTab(patientUid: widget.patientUid),
    ];

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: Column(
        children: [
          _PatientHeader(
            patient: _patient,
            xaiData: _xaiData,
            severity: severity,
            onBack: () => context.pop(),
          ),
          _TabBar(
            tabs: _mobileTabs,
            selected: _selectedTab,
            onSelect: (i) => setState(() => _selectedTab = i),
          ),
          Expanded(child: mobileTabContent[_selectedTab]),
        ],
      ),
    );
  }
}

// ── Patient Header ─────────────────────────────────────────────────────────────
class _PatientHeader extends StatelessWidget {
  final Map<String, dynamic>? patient;
  final Map<String, dynamic>? xaiData;
  final String severity;
  final VoidCallback onBack;

  const _PatientHeader({
    required this.patient,
    required this.xaiData,
    required this.severity,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final name = patient?['name'] as String? ?? 'Loading...';
    final score = xaiData?['score'] is int
        ? xaiData!['score'] as int
        : xaiData?['score'] is double
        ? (xaiData!['score'] as double).round()
        : 0;
    final gender = patient?['gender'] as String?;
    final dob = patient?['dob'] as String?;
    final empStatus = patient?['employeeStatus'] as String?;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sky, AppColors.mint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        MediaQuery.of(context).padding.top + AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                label: 'Go back',
                button: true,
                child: IconButton(
                  icon: PhosphorIcon(
                    PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular),
                    color: AppColors.ink,
                  ),
                  onPressed: onBack,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.headline3.copyWith(
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (xaiData != null)
                      Row(
                        children: [
                          SeverityBadge(severity: severity, compact: true),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Score: $score/10',
                            style: AppTypography.labelSmall,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (gender != null && gender.isNotEmpty)
                  _InfoPill(
                    icon: PhosphorIcons.person(PhosphorIconsStyle.regular),
                    label: gender,
                  ),
                if (dob != null && dob.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _InfoPill(
                    icon: PhosphorIcons.cake(PhosphorIconsStyle.regular),
                    label: dob,
                  ),
                ],
                if (empStatus != null && empStatus.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _InfoPill(
                    icon: PhosphorIcons.briefcase(PhosphorIconsStyle.regular),
                    label: empStatus,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.cloud.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 13, color: AppColors.inkLight),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: AppColors.inkLight),
          ),
        ],
      ),
    );
  }
}

// ── Tab Bar ────────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  const _TabBar({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cloud,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: tabs.asMap().entries.map((e) {
            final i = e.key;
            final label = e.value;
            final isSelected = selected == i;
            return Semantics(
              label: '$label tab',
              button: true,
              selected: isSelected,
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.skyDeep : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    label,
                    style: AppTypography.label.copyWith(
                      color: isSelected ? AppColors.cloud : AppColors.slate,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Overview Tab ───────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic>? xaiData;
  final String severity;
  final String patientUid;

  const _OverviewTab({
    required this.xaiData,
    required this.severity,
    required this.patientUid,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        children: [_XaiInsightCard(xaiData: xaiData, severity: severity)],
      ),
    );
  }
}

class _XaiInsightCard extends StatelessWidget {
  final Map<String, dynamic>? xaiData;
  final String severity;

  const _XaiInsightCard({required this.xaiData, required this.severity});

  @override
  Widget build(BuildContext context) {
    if (xaiData == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.fog,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            PhosphorIcon(
              PhosphorIcons.brain(PhosphorIconsStyle.regular),
              size: AppSpacing.iconHuge,
              color: AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.base),
            Text('Analysis Pending', style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Wellness analysis will appear once the patient has logged sufficient data.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final sevColor = AppColors.severityColor(severity);
    final deep = AppColors.severityDeepColor(severity);

    final score = xaiData!['score'] is int
        ? xaiData!['score'] as int
        : xaiData!['score'] is double
        ? (xaiData!['score'] as double).round()
        : 0;
    final confidence = xaiData!['confidence'] is double
        ? xaiData!['confidence'] as double
        : xaiData!['confidence'] is int
        ? (xaiData!['confidence'] as int).toDouble()
        : 0.0;
    final action = xaiData!['action'] as String? ?? '';
    final screeningNote = xaiData!['screeningNote'] as String? ?? '';
    final rawDrivers = xaiData!['primaryDrivers'] as List<dynamic>? ?? [];
    final drivers = rawDrivers
        .take(5)
        .map((d) {
          if (d is String) return d;
          if (d is Map) return d['name'] as String? ?? '';
          return '';
        })
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: sevColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: sevColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.brain(PhosphorIconsStyle.duotone),
                color: deep,
                size: AppSpacing.iconLg,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Wellness Analysis', style: AppTypography.label),
              const Spacer(),
              SeverityBadge(severity: severity),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    score.toString(),
                    style: AppTypography.dataLarge.copyWith(color: deep),
                  ),
                  Text('/10', style: AppTypography.caption),
                ],
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Confidence', style: AppTypography.label),
                    Text(
                      '${(confidence * 100).round()}%',
                      style: AppTypography.dataSmall.copyWith(color: deep),
                    ),
                    if (action.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Action: $action',
                        style: AppTypography.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (drivers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Key Signals', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: drivers
                  .map(
                    (d) => _DriverChip(label: d, deep: deep, color: sevColor),
                  )
                  .toList(),
            ),
          ],
          if (screeningNote.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              screeningNote,
              style: AppTypography.caption.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DriverChip extends StatelessWidget {
  final String label;
  final Color deep;
  final Color color;

  const _DriverChip({
    required this.label,
    required this.deep,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: AppTypography.labelSmall.copyWith(color: deep)),
    );
  }
}

// ── Analytics Tab — Rich Clinical Dashboard ────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  final List<DailyLog> dailyLogs;
  final Map<String, dynamic>? xaiData;

  const _AnalyticsTab({required this.dailyLogs, required this.xaiData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        children: [
          // A ── Risk Score Decomposition
          _ScoreDecompositionCard(xaiData: xaiData),
          const SizedBox(height: AppSpacing.base),
          // B ── Source Breakdown Heatmap
          _SourceBreakdownCard(xaiData: xaiData),
          const SizedBox(height: AppSpacing.base),
          // C ── Mood Trend
          _MoodTrendCard(dailyLogs: dailyLogs),
          const SizedBox(height: AppSpacing.base),
          // D ── Medication Adherence
          _AdherenceCard(dailyLogs: dailyLogs),
          const SizedBox(height: AppSpacing.base),
          // E ── Primary Drivers (expanded)
          _PrimaryDriversCard(xaiData: xaiData),
          const SizedBox(height: AppSpacing.base),
          // F ── Behavioral Signal Cards
          _BehavioralSignalsCard(xaiData: xaiData),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

// A ── Score Decomposition ──────────────────────────────────────────────────────
class _ScoreDecompositionCard extends StatelessWidget {
  final Map<String, dynamic>? xaiData;
  const _ScoreDecompositionCard({required this.xaiData});

  @override
  Widget build(BuildContext context) {
    final total = (xaiData?['score'] as num?)?.toDouble() ?? 0;
    final textScore = (xaiData?['textConcernScore'] as num?)?.toDouble() ?? 0;
    final behavScore = (total - textScore).clamp(0, total).toDouble();
    final maxScore = 30.0;

    return _AnalyticsCard(
      icon: PhosphorIcons.chartBar(PhosphorIconsStyle.duotone),
      iconColor: AppColors.lavenderDeep,
      title: 'Risk Score Breakdown',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScoreChip(
                label: 'Total',
                value: total.round(),
                color: AppColors.lavenderDeep,
              ),
              const SizedBox(width: AppSpacing.sm),
              _ScoreChip(
                label: 'Text',
                value: textScore.round(),
                color: AppColors.skyDeep,
              ),
              const SizedBox(width: AppSpacing.sm),
              _ScoreChip(
                label: 'Behavioral',
                value: behavScore.round(),
                color: AppColors.amberDeep,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: SizedBox(
              height: 18,
              child: LayoutBuilder(
                builder: (ctx, c) {
                  final w = c.maxWidth;
                  final textW = (textScore / maxScore * w).clamp(0.0, w);
                  final behavW = (behavScore / maxScore * w).clamp(
                    0.0,
                    w - textW,
                  );
                  return Stack(
                    children: [
                      Container(color: AppColors.fog, width: w),
                      Container(
                        color: AppColors.skyDeep.withValues(alpha: 0.8),
                        width: textW,
                      ),
                      Positioned(
                        left: textW,
                        child: Container(
                          color: AppColors.amberDeep.withValues(alpha: 0.8),
                          width: behavW,
                          height: 18,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _LegendDot(color: AppColors.skyDeep, label: 'Text signals'),
              const SizedBox(width: AppSpacing.md),
              _LegendDot(
                color: AppColors.amberDeep,
                label: 'Behavioral signals',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _ScoreChip({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTypography.dataSmall.copyWith(color: color, fontSize: 18),
          ),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

// B ── Source Breakdown Heatmap ─────────────────────────────────────────────────
class _SourceBreakdownCard extends StatelessWidget {
  final Map<String, dynamic>? xaiData;
  const _SourceBreakdownCard({required this.xaiData});

  static const _sourceIcons = {
    'diary': PhosphorIconsDuotone.book,
    'chat': PhosphorIconsDuotone.chats,
    'guardian': PhosphorIconsDuotone.users,
    'mobility': PhosphorIconsDuotone.mapPin,
    'activity': PhosphorIconsDuotone.pulse,
    'medication': PhosphorIconsDuotone.pill,
    'appointments': PhosphorIconsDuotone.calendarCheck,
    'daily_log': PhosphorIconsDuotone.sunHorizon,
  };

  @override
  Widget build(BuildContext context) {
    final breakdown =
        xaiData?['sourceBreakdown'] as Map<String, dynamic>? ?? {};
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final entries = breakdown.entries.toList()
      ..sort((a, b) {
        final sa = (a.value as Map<String, dynamic>?)?['score'] as num? ?? 0;
        final sb = (b.value as Map<String, dynamic>?)?['score'] as num? ?? 0;
        return sb.compareTo(sa);
      });

    return _AnalyticsCard(
      icon: PhosphorIcons.gridFour(PhosphorIconsStyle.duotone),
      iconColor: AppColors.mintDeep,
      title: 'Data Source Breakdown',
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: entries.map((e) {
          final src = e.key;
          final val = e.value as Map<String, dynamic>? ?? {};
          final score = (val['score'] as num?)?.toInt() ?? 0;
          final count = (val['count'] as num?)?.toInt() ?? 0;
          final intensity = score == 0 ? 0.0 : (score / 10).clamp(0.1, 1.0);
          final color = score > 6
              ? AppColors.criticalDeep
              : score > 3
              ? AppColors.warningDeep
              : AppColors.stableDeep;
          return Container(
            width: 110,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: intensity * 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: color.withValues(alpha: intensity * 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhosphorIcon(
                  _sourceIcons[src] ?? PhosphorIconsDuotone.database,
                  size: AppSpacing.iconMd,
                  color: color,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  src.replaceAll('_', ' '),
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Score $score · $count items',
                  style: AppTypography.caption,
                  maxLines: 1,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// C ── Mood Trend ────────────────────────────────────────────────────────────────
class _MoodTrendCard extends StatelessWidget {
  final List<DailyLog> dailyLogs;
  const _MoodTrendCard({required this.dailyLogs});

  @override
  Widget build(BuildContext context) {
    final logsWithMood = dailyLogs.where((l) => l.mood > 0).toList();
    final baseDate = DateTime.now().subtract(const Duration(days: 30));
    final spots = logsWithMood.map((l) {
      final dt = DateTime.tryParse(l.date) ?? DateTime.now();
      final x = dt.difference(baseDate).inDays.toDouble().clamp(0.0, 30.0);
      return FlSpot(x, l.mood.toDouble().clamp(1.0, 5.0));
    }).toList();
    final mean = spots.isEmpty
        ? 0.0
        : spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;

    return _AnalyticsCard(
      icon: PhosphorIcons.trendUp(PhosphorIconsStyle.duotone),
      iconColor: AppColors.lavenderDeep,
      title: 'Mood Trend — 30 Days',
      child: spots.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'No mood data',
                  style: TextStyle(color: AppColors.slate),
                ),
              ),
            )
          : SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 1,
                  maxY: 5,
                  minX: 0,
                  maxX: 30,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    verticalInterval: 7,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppColors.divider, strokeWidth: 1),
                    getDrawingVerticalLine: (_) => const FlLine(
                      color: AppColors.divider,
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 52,
                        getTitlesWidget: (v, _) {
                          const labels = {
                            1: 'Awful',
                            2: 'Low',
                            3: 'Neutral',
                            4: 'Good',
                            5: 'Great',
                          };
                          return Text(
                            labels[v.toInt()] ?? '',
                            style: AppTypography.caption,
                          );
                        },
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: mean,
                        color: AppColors.lavenderDeep.withValues(alpha: 0.5),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          labelResolver: (_) =>
                              'avg ${mean.toStringAsFixed(1)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.lavenderDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.lavenderDeep,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.lavender.withValues(alpha: 0.1),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                          radius: 3.5,
                          color: AppColors.lavenderDeep,
                          strokeWidth: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// D ── Adherence Card ───────────────────────────────────────────────────────────
class _AdherenceCard extends StatelessWidget {
  final List<DailyLog> dailyLogs;
  const _AdherenceCard({required this.dailyLogs});

  @override
  Widget build(BuildContext context) {
    final taken = dailyLogs.where((l) => l.medicationTaken).length;
    final total = dailyLogs.length;
    final adherence = total > 0 ? taken / total : 0.0;

    return _AnalyticsCard(
      icon: PhosphorIcons.pill(PhosphorIconsStyle.duotone),
      iconColor: AppColors.mintDeep,
      title: 'Medication Adherence',
      child: Row(
        children: [
          Text(
            '${(adherence * 100).round()}%',
            style: AppTypography.dataLarge.copyWith(color: AppColors.mintDeep),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: LinearProgressIndicator(
                    value: adherence.clamp(0.0, 1.0),
                    backgroundColor: AppColors.mintMist,
                    color: adherence < 0.5
                        ? AppColors.criticalDeep
                        : AppColors.mintDeep,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$taken of $total days taken',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// E ── Primary Drivers (expanded) ──────────────────────────────────────────────
class _PrimaryDriversCard extends StatelessWidget {
  final Map<String, dynamic>? xaiData;
  const _PrimaryDriversCard({required this.xaiData});

  @override
  Widget build(BuildContext context) {
    final rawDrivers = xaiData?['primaryDrivers'] as List<dynamic>? ?? [];
    if (rawDrivers.isEmpty) return const SizedBox.shrink();

    return _AnalyticsCard(
      icon: PhosphorIcons.brain(PhosphorIconsStyle.duotone),
      iconColor: AppColors.lavenderDeep,
      title: 'Primary Clinical Drivers',
      child: Column(
        children: rawDrivers.take(8).map((d) {
          final Map<String, dynamic> dm = d is Map<String, dynamic> ? d : {};
          final name =
              dm['displayName'] as String? ??
              dm['theme'] as String? ??
              d.toString();
          final snippet = dm['evidenceSnippet'] as String? ?? '';
          final weight = (dm['weight'] as num?)?.toInt() ?? 0;
          final source = dm['source'] as String? ?? '';
          final severity = dm['severity'] as String? ?? 'stable';
          final sevColor = AppColors.severityColor(severity);
          final sevDeep = AppColors.severityDeepColor(severity);

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: sevColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: sevColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: sevDeep,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(name, style: AppTypography.titleSmall),
                    ),
                    if (weight > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: sevDeep.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                        child: Text(
                          'w:$weight',
                          style: AppTypography.caption.copyWith(color: sevDeep),
                        ),
                      ),
                  ],
                ),
                if (snippet.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    snippet,
                    style: AppTypography.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (source.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs2),
                  Text(
                    'Source: $source',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// F ── Behavioral Signal Cards ──────────────────────────────────────────────────
class _BehavioralSignalsCard extends StatelessWidget {
  final Map<String, dynamic>? xaiData;
  const _BehavioralSignalsCard({required this.xaiData});

  static const _categoryIcons = {
    'mood': PhosphorIconsDuotone.smiley,
    'sleep': PhosphorIconsDuotone.moon,
    'medication': PhosphorIconsDuotone.pill,
    'circadian': PhosphorIconsDuotone.sunHorizon,
    'mobility': PhosphorIconsDuotone.mapPin,
    'psychomotor': PhosphorIconsDuotone.pulse,
    'appointments': PhosphorIconsDuotone.calendarCheck,
    'guardian': PhosphorIconsDuotone.users,
    'typing': PhosphorIconsDuotone.keyboard,
  };

  @override
  Widget build(BuildContext context) {
    // Try entries from sourceBreakdown or behavioralSignals
    final entries =
        xaiData?['entries'] as List<dynamic>? ??
        xaiData?['behavioralSignals'] as List<dynamic>? ??
        [];
    final signalCount =
        (xaiData?['behavioralSignalCount'] as num?)?.toInt() ?? entries.length;

    if (entries.isEmpty && signalCount == 0) return const SizedBox.shrink();

    return _AnalyticsCard(
      icon: PhosphorIcons.pulse(PhosphorIconsStyle.duotone),
      iconColor: AppColors.amberDeep,
      title: 'Behavioral Signals ($signalCount detected)',
      child: entries.isEmpty
          ? Text(
              '$signalCount behavioral signals contributed to this analysis.',
              style: AppTypography.bodySmall,
            )
          : SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (ctx, i) {
                  final e = entries[i];
                  final em = e is Map<String, dynamic>
                      ? e
                      : <String, dynamic>{};
                  final category = em['category'] as String? ?? 'behavioral';
                  final label =
                      em['label'] as String? ??
                      em['signal'] as String? ??
                      category;
                  final snippet =
                      em['evidenceSnippet'] as String? ??
                      em['content'] as String? ??
                      '';
                  final severity = em['severity'] as String? ?? 'stable';
                  final sevColor = AppColors.severityColor(severity);
                  final sevDeep = AppColors.severityDeepColor(severity);
                  final icon =
                      _categoryIcons[category] ??
                      PhosphorIconsDuotone.checkCircle;

                  return Container(
                    width: 180,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: sevColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: sevColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PhosphorIcon(
                          icon,
                          size: AppSpacing.iconMd,
                          color: sevDeep,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          label.replaceAll('_', ' '),
                          style: AppTypography.titleSmall.copyWith(
                            color: sevDeep,
                          ),
                          maxLines: 2,
                        ),
                        const Spacer(),
                        if (snippet.isNotEmpty)
                          Text(
                            snippet,
                            style: AppTypography.caption,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: sevDeep.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill,
                            ),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: AppTypography.caption.copyWith(
                              color: sevDeep,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ── Shared card shell ──────────────────────────────────────────────────────────
class _AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _AnalyticsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.sky.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(icon, size: AppSpacing.iconMd, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTypography.title),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          child,
        ],
      ),
    );
  }
}

// ── Treatment Tab ──────────────────────────────────────────────────────────────
class _TreatmentTab extends StatelessWidget {
  final Prescription? prescription;
  final String patientUid;
  final Map<String, dynamic>? patientDoc;
  final VoidCallback onRefresh;
  final String doctorUid;

  const _TreatmentTab({
    required this.prescription,
    required this.patientUid,
    required this.patientDoc,
    required this.onRefresh,
    required this.doctorUid,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Prescription
          if (prescription != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.cloud,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.prescription(PhosphorIconsStyle.duotone),
                        color: AppColors.skyDeep,
                        size: AppSpacing.iconLg,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Active Prescription', style: AppTypography.title),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mintMist,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.mintDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LabelValue(
                    label: 'Diagnosis',
                    value: prescription!.diagnosis,
                  ),
                  if (prescription!.notes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _LabelValue(label: 'Notes', value: prescription!.notes),
                  ],
                  if (prescription!.suggestions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _LabelValue(
                      label: 'Suggestions',
                      value: prescription!.suggestions,
                    ),
                  ],
                  if (prescription!.nextAppointmentDate.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _LabelValue(
                      label: 'Next Appointment',
                      value: prescription!.nextAppointmentDate,
                    ),
                  ],
                  if (prescription!.medicines.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('Medications', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.sm),
                    ...prescription!.medicines.map(
                      (m) => _MedicineRow(medicine: m),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.fog,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Column(
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.prescription(PhosphorIconsStyle.regular),
                      size: AppSpacing.iconHuge,
                      color: AppColors.slate,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('No active prescription', style: AppTypography.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Create a prescription for this patient',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
          ],
          // Update Prescription button
          Semantics(
            label: 'Update or create prescription',
            button: true,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPrescriptionEditor(context),
                icon: PhosphorIcon(
                  PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular),
                  size: 18,
                  color: AppColors.cloud,
                ),
                label: Text(
                  prescription != null
                      ? 'Update Prescription'
                      : 'Create Prescription',
                  style: AppTypography.label.copyWith(color: AppColors.cloud),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyDeep,
                  foregroundColor: AppColors.cloud,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Schedule Appointment button
          Semantics(
            label: 'Schedule new appointment',
            button: true,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAppointmentSheet(context),
                icon: PhosphorIcon(
                  PhosphorIcons.calendarPlus(PhosphorIconsStyle.regular),
                  size: 18,
                  color: AppColors.skyDeep,
                ),
                label: Text(
                  'Schedule Appointment',
                  style: AppTypography.label.copyWith(color: AppColors.skyDeep),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.skyDeep,
                  side: const BorderSide(color: AppColors.skyDeep),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrescriptionEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cloud,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) => _PrescriptionEditorSheet(
        patientUid: patientUid,
        patientName: patientDoc?['name'] as String? ?? '',
        doctorUid: doctorUid,
        existing: prescription,
        onSaved: onRefresh,
      ),
    );
  }

  void _showAppointmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cloud,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) => _AppointmentSheet(
        patientUid: patientUid,
        patientName: patientDoc?['name'] as String? ?? '',
        doctorUid: doctorUid,
        onSaved: onRefresh,
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;

  const _LabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs2),
        Text(value, style: AppTypography.body),
      ],
    );
  }
}

class _MedicineRow extends StatelessWidget {
  final Medicine medicine;
  const _MedicineRow({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final times = [
      if (medicine.morning) 'Morning',
      if (medicine.afternoon) 'Afternoon',
      if (medicine.night) 'Night',
    ].join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.skyMist,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.sky.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIcons.pill(PhosphorIconsStyle.duotone),
            size: AppSpacing.iconMd,
            color: AppColors.skyDeep,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicine.name, style: AppTypography.titleSmall),
                if (medicine.dose.isNotEmpty)
                  Text(medicine.dose, style: AppTypography.caption),
                if (times.isNotEmpty) Text(times, style: AppTypography.caption),
              ],
            ),
          ),
          if (medicine.beforeMeal)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.amberMist,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                'Before meal',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.amberDeep,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Prescription Editor Sheet ──────────────────────────────────────────────────
class _PrescriptionEditorSheet extends StatefulWidget {
  final String patientUid;
  final String patientName;
  final String doctorUid;
  final Prescription? existing;
  final VoidCallback onSaved;

  const _PrescriptionEditorSheet({
    required this.patientUid,
    required this.patientName,
    required this.doctorUid,
    required this.existing,
    required this.onSaved,
  });

  @override
  State<_PrescriptionEditorSheet> createState() =>
      _PrescriptionEditorSheetState();
}

class _PrescriptionEditorSheetState extends State<_PrescriptionEditorSheet> {
  late TextEditingController _diagnosisCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _suggestionsCtrl;
  late TextEditingController _nextDateCtrl;
  List<_MedicineEntry> _medicines = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _diagnosisCtrl = TextEditingController(
      text: widget.existing?.diagnosis ?? '',
    );
    _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
    _suggestionsCtrl = TextEditingController(
      text: widget.existing?.suggestions ?? '',
    );
    _nextDateCtrl = TextEditingController(
      text: widget.existing?.nextAppointmentDate ?? '',
    );
    if (widget.existing != null) {
      _medicines = widget.existing!.medicines
          .map(
            (m) => _MedicineEntry(
              name: m.name,
              dose: m.dose,
              morning: m.morning,
              afternoon: m.afternoon,
              night: m.night,
              beforeMeal: m.beforeMeal,
            ),
          )
          .toList();
    }
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    _suggestionsCtrl.dispose();
    _nextDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_diagnosisCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Diagnosis is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final rx = Prescription(
        id: '',
        patientUid: widget.patientUid,
        doctorUid: widget.doctorUid,
        patientName: widget.patientName,
        diagnosis: _diagnosisCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        suggestions: _suggestionsCtrl.text.trim(),
        nextAppointmentDate: _nextDateCtrl.text.trim(),
        isActive: true,
        medicines: _medicines
            .map(
              (e) => Medicine(
                name: e.name,
                dose: e.dose,
                morning: e.morning,
                afternoon: e.afternoon,
                night: e.night,
                beforeMeal: e.beforeMeal,
              ),
            )
            .toList(),
        createdAt: now,
      );
      await DoctorController.savePrescription(rx);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addMedicine() {
    setState(() => _medicines.add(_MedicineEntry()));
  }

  void _removeMedicine(int index) {
    setState(() => _medicines.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Row(
                children: [
                  Text(
                    widget.existing != null
                        ? 'Update Prescription'
                        : 'New Prescription',
                    style: AppTypography.headline4,
                  ),
                  const Spacer(),
                  Semantics(
                    label: 'Close',
                    button: true,
                    child: IconButton(
                      icon: PhosphorIcon(
                        PhosphorIcons.x(PhosphorIconsStyle.regular),
                        color: AppColors.slate,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(AppSpacing.base),
                children: [
                  _SheetTextField(
                    controller: _diagnosisCtrl,
                    label: 'Diagnosis *',
                    hint: 'Primary diagnosis',
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SheetTextField(
                    controller: _notesCtrl,
                    label: 'Clinical Notes',
                    hint: 'Additional notes...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SheetTextField(
                    controller: _suggestionsCtrl,
                    label: 'Suggestions',
                    hint: 'Lifestyle suggestions...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SheetTextField(
                    controller: _nextDateCtrl,
                    label: 'Next Appointment Date',
                    hint: 'e.g. 2025-06-01',
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 7),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.skyDeep,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        _nextDateCtrl.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(picked);
                      }
                    },
                    readOnly: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Text('Medications', style: AppTypography.title),
                      const Spacer(),
                      Semantics(
                        label: 'Add medication',
                        button: true,
                        child: TextButton.icon(
                          onPressed: _addMedicine,
                          icon: PhosphorIcon(
                            PhosphorIcons.plus(PhosphorIconsStyle.regular),
                            size: 16,
                            color: AppColors.skyDeep,
                          ),
                          label: Text(
                            'Add',
                            style: AppTypography.label.copyWith(
                              color: AppColors.skyDeep,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._medicines.asMap().entries.map(
                    (e) => _MedicineEditorCard(
                      entry: e.value,
                      onChanged: () => setState(() {}),
                      onRemove: () => _removeMedicine(e.key),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Semantics(
                    label: 'Save prescription',
                    button: true,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.skyDeep,
                          foregroundColor: AppColors.cloud,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill,
                            ),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.cloud,
                                ),
                              )
                            : Text(
                                'Save Prescription',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.cloud,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineEntry {
  String name;
  String dose;
  bool morning;
  bool afternoon;
  bool night;
  bool beforeMeal;

  _MedicineEntry({
    this.name = '',
    this.dose = '',
    this.morning = false,
    this.afternoon = false,
    this.night = false,
    this.beforeMeal = false,
  });
}

class _MedicineEditorCard extends StatelessWidget {
  final _MedicineEntry entry;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _MedicineEditorCard({
    required this.entry,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.skyMist,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.sky.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Medicine name',
                    labelStyle: AppTypography.label,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  controller: TextEditingController(text: entry.name)
                    ..selection = TextSelection.collapsed(
                      offset: entry.name.length,
                    ),
                  onChanged: (v) {
                    entry.name = v;
                    onChanged();
                  },
                  style: AppTypography.body,
                ),
              ),
              Semantics(
                label: 'Remove medication',
                button: true,
                child: IconButton(
                  icon: PhosphorIcon(
                    PhosphorIcons.trash(PhosphorIconsStyle.regular),
                    color: AppColors.criticalDeep,
                    size: 18,
                  ),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          TextField(
            decoration: InputDecoration(
              labelText: 'Dose (e.g. 10mg)',
              labelStyle: AppTypography.label,
              border: InputBorder.none,
              isDense: true,
            ),
            controller: TextEditingController(text: entry.dose)
              ..selection = TextSelection.collapsed(offset: entry.dose.length),
            onChanged: (v) {
              entry.dose = v;
              onChanged();
            },
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _ToggleChip(
                label: 'Morning',
                value: entry.morning,
                onChanged: (v) {
                  entry.morning = v;
                  onChanged();
                },
              ),
              _ToggleChip(
                label: 'Afternoon',
                value: entry.afternoon,
                onChanged: (v) {
                  entry.afternoon = v;
                  onChanged();
                },
              ),
              _ToggleChip(
                label: 'Night',
                value: entry.night,
                onChanged: (v) {
                  entry.night = v;
                  onChanged();
                },
              ),
              _ToggleChip(
                label: 'Before Meal',
                value: entry.beforeMeal,
                onChanged: (v) {
                  entry.beforeMeal = v;
                  onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label ${value ? "selected" : "not selected"}',
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: value ? AppColors.skyDeep : AppColors.cloud,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: value ? AppColors.skyDeep : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: value ? AppColors.cloud : AppColors.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(color: AppColors.slate),
            filled: true,
            fillColor: AppColors.mist,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.skyDeep,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
          ),
          style: AppTypography.body,
        ),
      ],
    );
  }
}

// ── Appointment Sheet ──────────────────────────────────────────────────────────
class _AppointmentSheet extends StatefulWidget {
  final String patientUid;
  final String patientName;
  final String doctorUid;
  final VoidCallback onSaved;

  const _AppointmentSheet({
    required this.patientUid,
    required this.patientName,
    required this.doctorUid,
    required this.onSaved,
  });

  @override
  State<_AppointmentSheet> createState() => _AppointmentSheetState();
}

class _AppointmentSheetState extends State<_AppointmentSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _saving = false;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.skyDeep),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.skyDeep),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _selectedTime = t);
  }

  Future<void> _save() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final hour = _selectedTime!.hour.toString().padLeft(2, '0');
      final min = _selectedTime!.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$min';
      final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

      final appt = Appointment(
        id: '',
        patientUid: widget.patientUid,
        doctorUid: widget.doctorUid,
        patientName: widget.patientName,
        date: dateStr,
        time: timeStr,
        status: 'scheduled',
        createdAt: now,
      );
      await DoctorController.saveAppointment(appt);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appointment scheduled')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Row(
              children: [
                Text('Schedule Appointment', style: AppTypography.headline4),
                const Spacer(),
                Semantics(
                  label: 'Close',
                  button: true,
                  child: IconButton(
                    icon: PhosphorIcon(
                      PhosphorIcons.x(PhosphorIconsStyle.regular),
                      color: AppColors.slate,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              children: [
                // Date picker
                Semantics(
                  label: 'Select appointment date',
                  button: true,
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.calendarBlank(
                              PhosphorIconsStyle.regular,
                            ),
                            color: AppColors.skyDeep,
                            size: AppSpacing.iconMd,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            _selectedDate != null
                                ? DateFormat(
                                    'EEEE, MMMM d, y',
                                  ).format(_selectedDate!)
                                : 'Select Date',
                            style: AppTypography.body.copyWith(
                              color: _selectedDate != null
                                  ? AppColors.ink
                                  : AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Time picker
                Semantics(
                  label: 'Select appointment time',
                  button: true,
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.clock(PhosphorIconsStyle.regular),
                            color: AppColors.skyDeep,
                            size: AppSpacing.iconMd,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            _selectedTime != null
                                ? _selectedTime!.format(context)
                                : 'Select Time',
                            style: AppTypography.body.copyWith(
                              color: _selectedTime != null
                                  ? AppColors.ink
                                  : AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  label: 'Confirm appointment',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.skyDeep,
                        foregroundColor: AppColors.cloud,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cloud,
                              ),
                            )
                          : Text(
                              'Confirm Appointment',
                              style: AppTypography.label.copyWith(
                                color: AppColors.cloud,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(
                  height:
                      AppSpacing.base + MediaQuery.of(context).padding.bottom,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── History Tab ────────────────────────────────────────────────────────────────
class _HistoryTab extends StatefulWidget {
  final String patientUid;
  const _HistoryTab({required this.patientUid});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('clinical_reports')
          .where('patientUid', isEqualTo: widget.patientUid)
          .orderBy('generatedAt', descending: true)
          .get();
      if (mounted) {
        setState(() {
          _reports = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.skyDeep),
                )
              : _reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.fileText(PhosphorIconsStyle.regular),
                        size: AppSpacing.iconHuge,
                        color: AppColors.slate,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Text('No reports yet', style: AppTypography.title),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Clinical reports will appear here',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  itemCount: _reports.length,
                  itemBuilder: (ctx, i) => _ReportTile(
                    report: _reports[i],
                    onTap: () => _showReportDetail(ctx, _reports[i]),
                  ),
                ),
        ),
      ],
    );
  }

  void _showReportDetail(BuildContext context, Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cloud,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) => _ReportDetailSheet(report: report),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onTap;

  const _ReportTile({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type =
        report['reportType'] as String? ??
        report['type'] as String? ??
        'Report';
    final severity = report['severity'] as String? ?? 'stable';
    final createdAt = report['createdAt'] as String? ?? '';
    final score = report['score'] ?? 0;

    return Semantics(
      label: '$type report',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cloud,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.skyMist,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIcons.fileText(PhosphorIconsStyle.duotone),
                    color: AppColors.skyDeep,
                    size: AppSpacing.iconMd,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type, style: AppTypography.titleSmall),
                    if (createdAt.isNotEmpty)
                      Text(createdAt, style: AppTypography.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SeverityBadge(severity: severity, compact: true),
                  if (score != 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text('$score/10', style: AppTypography.caption),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportDetailSheet extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportDetailSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    final type =
        report['reportType'] as String? ??
        report['type'] as String? ??
        'Report';
    final severity = report['severity'] as String? ?? 'stable';
    final score = report['score'];
    final note =
        report['screeningNote'] as String? ?? report['notes'] as String? ?? '';
    final action = report['action'] as String? ?? '';
    final drivers = (report['primaryDrivers'] as List<dynamic>? ?? [])
        .map((d) => d is String ? d : (d as Map)['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Row(
              children: [
                Text(type, style: AppTypography.headline4),
                const Spacer(),
                SeverityBadge(severity: severity),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.divider),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                if (score != null)
                  _DetailRow(label: 'Score', value: '$score / 10'),
                if (action.isNotEmpty)
                  _DetailRow(label: 'Recommended Action', value: action),
                if (note.isNotEmpty)
                  _DetailRow(label: 'Clinical Note', value: note),
                if (drivers.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Primary Drivers', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.sm),
                  ...drivers.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.skyDeep,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(d, style: AppTypography.body)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                Semantics(
                  label: 'Download PDF - opens admin portal',
                  button: true,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PDF available via admin portal'),
                        ),
                      );
                    },
                    icon: PhosphorIcon(
                      PhosphorIcons.downloadSimple(PhosphorIconsStyle.regular),
                      size: 18,
                      color: AppColors.skyDeep,
                    ),
                    label: Text(
                      'Download PDF',
                      style: AppTypography.label.copyWith(
                        color: AppColors.skyDeep,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.skyDeep,
                      side: const BorderSide(color: AppColors.skyDeep),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.body),
        ],
      ),
    );
  }
}
