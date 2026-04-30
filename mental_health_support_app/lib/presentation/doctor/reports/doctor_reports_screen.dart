import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mental_health_support_app/core/assets/app_assets.dart';
import 'package:mental_health_support_app/core/models/clinical_report.dart';
import 'package:mental_health_support_app/core/services/api_service.dart';
import 'package:mental_health_support_app/core/services/report_service.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_asset.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_pill_button.dart';
import 'package:mental_health_support_app/presentation/components/atoms/shimmer_card.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

class DoctorReportsScreen extends ConsumerStatefulWidget {
  const DoctorReportsScreen({super.key});

  @override
  ConsumerState<DoctorReportsScreen> createState() =>
      _DoctorReportsScreenState();
}

class _DoctorReportsScreenState extends ConsumerState<DoctorReportsScreen> {
  List<ClinicalReport> _reports = [];
  bool _loading = true;
  String? _error;
  bool _generating = false;
  String? _doctorUid;

  // Form state
  String? _selectedPatientUid;
  List<Map<String, dynamic>> _patients = [];
  String _reportTypeLabel = 'Monthly Review';

  static final _db = FirebaseFirestore.instance;
  static const _reportTypes = [
    'Daily Log',
    'Weekly Summary',
    'Monthly Review',
    'Yearly Review',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final userDoc = ref.read(currentUserDocProvider).asData?.value;
    _doctorUid =
        (userDoc?['uid'] as String?) ??
        ref.read(firebaseAuthProvider).currentUser?.uid ??
        '';
    await Future.wait([_loadPatients(), _loadReports()]);
  }

  Future<void> _loadPatients() async {
    if (_doctorUid == null || _doctorUid!.isEmpty) return;
    try {
      final snap = await _db
          .collection('patients')
          .where('assignedDoctor', isEqualTo: _doctorUid)
          .get();
      if (mounted) {
        setState(() => _patients = snap.docs.map((d) => d.data()).toList());
      }
    } catch (_) {}
  }

  Future<void> _loadReports() async {
    if (_doctorUid == null || _doctorUid!.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Pull from all assigned patients
      final allPatients = await _db
          .collection('patients')
          .where('assignedDoctor', isEqualTo: _doctorUid)
          .get();
      final patientUids = allPatients.docs
          .map((d) => (d.data()['uid'] as String?)?.trim().isNotEmpty == true
              ? (d.data()['uid'] as String).trim()
              : d.id)
          .toList();

      final futures = patientUids
          .map((uid) => ReportService.listReports(uid, limit: 5))
          .toList();
      final results = await Future.wait(futures);
      final all = results.expand((r) => r).toList()
        ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

      if (mounted) setState(() => _reports = all.take(30).toList());
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error =
              'Backend error ${e.statusCode}: check server connection.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateReport() async {
    if (_selectedPatientUid == null) {
      _showSnack('Please select a patient first.');
      return;
    }
    setState(() => _generating = true);
    HapticFeedback.mediumImpact();
    try {
      final report = await ReportService.generateReport(
        patientUid: _selectedPatientUid!,
        reportTypeLabel: _reportTypeLabel,
      );
      if (mounted) {
        _showSnack(
          'Report generated: ${report.aggregatedSeverity.toUpperCase()} severity, score ${report.score}',
        );
        setState(() => _reports = [report, ..._reports]);
      }
    } on ApiException catch (e) {
      if (mounted) {
        _showSnack('Backend error ${e.statusCode}. Is the server running?');
      }
    } catch (e) {
      if (mounted) _showSnack('Failed: $e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTypography.bodySmall),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.skyDeep,
          onRefresh: _loadReports,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    AppSpacing.base,
                    AppSpacing.base,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    'Clinical Reports',
                    style: AppTypography.headline3,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _GenerateCard(
                  patients: _patients,
                  selectedUid: _selectedPatientUid,
                  reportTypeLabel: _reportTypeLabel,
                  reportTypes: _reportTypes,
                  generating: _generating,
                  onPatientChanged: (uid, name) => setState(() {
                    _selectedPatientUid = uid;
                  }),
                  onTypeChanged: (t) => setState(() => _reportTypeLabel = t),
                  onGenerate: _generateReport,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    0,
                    AppSpacing.base,
                    AppSpacing.sm,
                  ),
                  child: Text('Recent Reports', style: AppTypography.title),
                ),
              ),
              if (_loading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, _) => const Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.base,
                        0,
                        AppSpacing.base,
                        AppSpacing.sm,
                      ),
                      child: ShimmerCard(height: 100),
                    ),
                    childCount: 4,
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: _ErrorMsg(message: _error!, onRetry: _loadReports),
                )
              else if (_reports.isEmpty)
                const SliverToBoxAdapter(child: _EmptyReports())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _ReportCard(
                      report: _reports[i],
                      onTap: () => _showDetail(ctx, _reports[i]),
                    ),
                    childCount: _reports.length,
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.huge),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, ClinicalReport report) {
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

// ── Generate Card ─────────────────────────────────────────────────────────────
class _GenerateCard extends StatelessWidget {
  final List<Map<String, dynamic>> patients;
  final String? selectedUid;
  final String reportTypeLabel;
  final List<String> reportTypes;
  final bool generating;
  final void Function(String uid, String name) onPatientChanged;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onGenerate;

  const _GenerateCard({
    required this.patients,
    required this.selectedUid,
    required this.reportTypeLabel,
    required this.reportTypes,
    required this.generating,
    required this.onPatientChanged,
    required this.onTypeChanged,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sky.withValues(alpha: 0.6), AppColors.skyMist],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.sky.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.sky.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cloud.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIcons.filePlus(PhosphorIconsStyle.duotone),
                    size: AppSpacing.iconLg,
                    color: AppColors.skyDeep,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Generate Report', style: AppTypography.title),
                  Text(
                    'X-AI powered clinical analysis',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _Dropdown(
            label: 'Select patient',
            value: selectedUid,
            items: patients.map((p) {
              final uid = p['uid'] as String? ?? '';
              final name = p['name'] as String? ?? 'Unknown';
              return DropdownMenuItem(
                value: uid,
                child: Text(name, style: AppTypography.body),
              );
            }).toList(),
            onChanged: (uid) {
              if (uid == null) return;
              final p = patients.firstWhere(
                (x) => x['uid'] == uid,
                orElse: () => {},
              );
              onPatientChanged(uid, p['name'] as String? ?? '');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _Dropdown<String>(
            label: 'Report type',
            value: reportTypeLabel,
            items: reportTypes
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t, style: AppTypography.body),
                  ),
                )
                .toList(),
            onChanged: (t) {
              if (t != null) onTypeChanged(t);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          MindCarePillButton(
            label: 'Generate via X-AI Engine',
            onPressed: generating ? null : onGenerate,
            isLoading: generating,
            width: double.infinity,
            color: AppColors.skyDeep,
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            label,
            style: AppTypography.body.copyWith(color: AppColors.slate),
          ),
          isExpanded: true,
          icon: PhosphorIcon(
            PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
            size: 14,
            color: AppColors.slate,
          ),
          style: AppTypography.body,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Report Card ───────────────────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final ClinicalReport report;
  final VoidCallback onTap;
  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sevColor = AppColors.severityColor(report.aggregatedSeverity);
    final sevDeep = AppColors.severityDeepColor(report.aggregatedSeverity);
    final adherence = report.adherenceSummary['adherencePercent'];

    return Semantics(
      label: '${report.type} report for ${report.patientName}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            0,
            AppSpacing.base,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.cloud,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: sevColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: sevColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: sevColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        PhosphorIcons.fileText(PhosphorIconsStyle.duotone),
                        size: AppSpacing.iconMd,
                        color: sevDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report.patientName, style: AppTypography.title),
                        Text(
                          '${report.type.toUpperCase()} · ${report.startDate} → ${report.endDate}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  // Severity badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: sevColor,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      report.aggregatedSeverity.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: sevDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: AppSpacing.sm),
              // Metrics row
              Row(
                children: [
                  _MetricPill(
                    icon: PhosphorIconsDuotone.chartBar,
                    label: 'Score',
                    value: '${report.score}',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (adherence != null)
                    _MetricPill(
                      icon: PhosphorIconsDuotone.pill,
                      label: 'Adherence',
                      value: '$adherence%',
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  _MetricPill(
                    icon: PhosphorIconsDuotone.checkCircle,
                    label: 'Confidence',
                    value: '${(report.confidence * 100).round()}%',
                  ),
                ],
              ),
              if (report.summary['screeningNote'] != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  report.summary['screeningNote'] as String? ?? '',
                  style: AppTypography.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.fog,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 12, color: AppColors.skyDeep),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$label $value',
            style: AppTypography.caption.copyWith(color: AppColors.inkLight),
          ),
        ],
      ),
    );
  }
}

// ── Report Detail Sheet ───────────────────────────────────────────────────────
class _ReportDetailSheet extends StatelessWidget {
  final ClinicalReport report;
  const _ReportDetailSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    final sevDeep = AppColors.severityDeepColor(report.aggregatedSeverity);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, ctrl) => Column(
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
                Text(report.patientName, style: AppTypography.headline4),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.severityColor(report.aggregatedSeverity),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    report.aggregatedSeverity.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: sevDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                _DetailRow(
                  label: 'Period',
                  value: '${report.startDate} → ${report.endDate}',
                ),
                _DetailRow(label: 'Type', value: report.type.toUpperCase()),
                _DetailRow(label: 'Score', value: '${report.score} / 30'),
                _DetailRow(
                  label: 'Text Score',
                  value: '${report.textConcernScore}',
                ),
                _DetailRow(
                  label: 'Confidence',
                  value: '${(report.confidence * 100).round()}%',
                ),
                if (report.summary['screeningNote'] != null)
                  _DetailRow(
                    label: 'Clinical Note',
                    value: report.summary['screeningNote'] as String? ?? '',
                  ),
                if (report.summary['action'] != null)
                  _DetailRow(
                    label: 'Recommended Action',
                    value: report.summary['action'] as String? ?? '',
                  ),
                const SizedBox(height: AppSpacing.md),
                if (report.topDrivers.isNotEmpty) ...[
                  Text('Primary Drivers', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.sm),
                  ...report.topDrivers.take(5).map((d) {
                    final dm = d is Map<String, dynamic>
                        ? d
                        : <String, dynamic>{};
                    final name =
                        dm['displayName'] as String? ??
                        dm['theme'] as String? ??
                        d.toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.skyDeep,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(name, style: AppTypography.body),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: AppSpacing.xl),
                // PDF download
                OutlinedButton.icon(
                  onPressed: () {
                    final url = report.pdfUrl;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'PDF: $url',
                          style: AppTypography.bodySmall,
                        ),
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
                SizedBox(
                  height:
                      MediaQuery.of(context).padding.bottom + AppSpacing.base,
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

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const MindCareAsset(
              asset: AppAssets.emptyReports,
              width: 160,
              height: 130,
              fallbackIcon: PhosphorIconsDuotone.fileText,
              fallbackColor: AppColors.skyDeep,
            ),
            const SizedBox(height: AppSpacing.base),
            Text('No reports yet', style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Generate your first X-AI report above',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorMsg extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorMsg({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const MindCareAsset(
            asset: AppAssets.errorState,
            width: 140,
            height: 110,
            fallbackIcon: PhosphorIconsRegular.wifiSlash,
            fallbackColor: AppColors.slate,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Failed to load reports', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onRetry,
            child: Text('Try again', style: AppTypography.label),
          ),
        ],
      ),
    );
  }
}
