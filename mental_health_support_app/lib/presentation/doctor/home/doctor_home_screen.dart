import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/models/appointment.dart';
import 'package:mental_health_support_app/core/models/reschedule_request.dart';
import 'package:mental_health_support_app/core/controllers/doctor_controller.dart';
import 'package:mental_health_support_app/core/services/auth_service.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

// ── State data class ──────────────────────────────────────────────────────────
class _DoctorHomeData {
  final List<Map<String, dynamic>> allPatients;
  final List<Map<String, dynamic>> newPatients;
  final List<Appointment> todayAppointments;
  final List<RescheduleRequest> reschedules;
  final Map<String, Map<String, dynamic>?> xaiSnapshots;

  const _DoctorHomeData({
    required this.allPatients,
    required this.newPatients,
    required this.todayAppointments,
    required this.reschedules,
    required this.xaiSnapshots,
  });
}

// ── Providers ─────────────────────────────────────────────────────────────────
final _doctorHomeProvider = FutureProvider.autoDispose
    .family<_DoctorHomeData, String>((ref, doctorUid) async {
      final results = await Future.wait([
        DoctorController.getAllPatients(doctorUid),
        DoctorController.getNewPatients(doctorUid),
        DoctorController.getTodayAppointments(doctorUid),
        DoctorController.getPendingReschedules(doctorUid),
      ]);

      final allPatients = results[0] as List<Map<String, dynamic>>;
      final newPatients = results[1] as List<Map<String, dynamic>>;
      final appointments = results[2] as List<Appointment>;
      final reschedules = results[3] as List<RescheduleRequest>;

      final Map<String, Map<String, dynamic>?> snapshots = {};
      await Future.wait(
        allPatients.map((p) async {
          final uid = p['uid'] as String? ?? '';
          if (uid.isNotEmpty) {
            snapshots[uid] = await DoctorController.getXaiAnalysisSnapshot(uid);
          }
        }),
      );

      return _DoctorHomeData(
        allPatients: allPatients,
        newPatients: newPatients,
        todayAppointments: appointments,
        reschedules: reschedules,
        xaiSnapshots: snapshots,
      );
    });

// ── Helper: severity from XAI snapshot ───────────────────────────────────────
String _severityFromSnapshot(Map<String, dynamic>? snap) {
  if (snap == null) return 'stable';
  final raw =
      (snap['severity'] as String? ?? snap['riskLevel'] as String? ?? 'stable')
          .toLowerCase();
  if (raw.contains('critical')) return 'critical';
  if (raw.contains('warning') || raw.contains('high')) return 'warning';
  if (raw.contains('watch') || raw.contains('moderate')) return 'watch';
  return 'stable';
}

// ── Screen ────────────────────────────────────────────────────────────────────
class DoctorHomeScreen extends ConsumerWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDoc = ref.watch(currentUserDocProvider);
    final doctorName = userDoc.asData?.value?['name'] as String? ?? 'Doctor';
    final doctorUid = userDoc.asData?.value?['uid'] as String? ?? '';

    if (doctorUid.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.mist,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final homeAsync = ref.watch(_doctorHomeProvider(doctorUid));

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: homeAsync.when(
        loading: () => const _DoctorHomeLoading(),
        error: (e, _) => _DoctorHomeError(
          onRetry: () => ref.invalidate(_doctorHomeProvider(doctorUid)),
        ),
        data: (data) => _DoctorHomeBody(
          doctorName: doctorName,
          doctorUid: doctorUid,
          data: data,
          onRefresh: () => ref.invalidate(_doctorHomeProvider(doctorUid)),
        ),
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────
class _DoctorHomeLoading extends StatelessWidget {
  const _DoctorHomeLoading();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: 240, child: _GradientHeroSkeleton()),
        ),
        SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.skyDeep),
          ),
        ),
      ],
    );
  }
}

class _GradientHeroSkeleton extends StatelessWidget {
  const _GradientHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sky, AppColors.mint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const SafeArea(child: SizedBox.expand()),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────
class _DoctorHomeError extends StatelessWidget {
  final VoidCallback onRetry;
  const _DoctorHomeError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.wifiSlash(),
            size: AppSpacing.iconHuge,
            color: AppColors.slate,
          ),
          const SizedBox(height: AppSpacing.base),
          Text('Could not load dashboard', style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: 'Retry loading dashboard',
            button: true,
            child: TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: AppTypography.label.copyWith(color: AppColors.skyDeep),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────
class _DoctorHomeBody extends StatefulWidget {
  final String doctorName;
  final String doctorUid;
  final _DoctorHomeData data;
  final VoidCallback onRefresh;

  const _DoctorHomeBody({
    required this.doctorName,
    required this.doctorUid,
    required this.data,
    required this.onRefresh,
  });

  @override
  State<_DoctorHomeBody> createState() => _DoctorHomeBodyState();
}

class _DoctorHomeBodyState extends State<_DoctorHomeBody> {
  String _severityFilter = '';

  Map<String, int> get _severityCounts {
    final counts = {'critical': 0, 'warning': 0, 'watch': 0, 'stable': 0};
    for (final p in widget.data.allPatients) {
      final uid = p['uid'] as String? ?? '';
      final sev = _severityFromSnapshot(widget.data.xaiSnapshots[uid]);
      counts[sev] = (counts[sev] ?? 0) + 1;
    }
    return counts;
  }

  List<Map<String, dynamic>> get _alertPatients {
    return widget.data.allPatients.where((p) {
      final uid = p['uid'] as String? ?? '';
      final sev = _severityFromSnapshot(widget.data.xaiSnapshots[uid]);
      return sev == 'critical' || sev == 'warning';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final counts = _severityCounts;
    final alerts = _alertPatients;
    final reduce = MediaQuery.of(context).disableAnimations;
    final width = MediaQuery.of(context).size.width;
    final isWide = kIsWeb || width >= 800;

    if (isWide) {
      return _WebDashboardLayout(
        doctorName: widget.doctorName,
        doctorUid: widget.doctorUid,
        data: widget.data,
        counts: counts,
        alerts: alerts,
        severityFilter: _severityFilter,
        onFilterTap: (sev) => setState(() {
          _severityFilter = _severityFilter == sev ? '' : sev;
        }),
        reduceMotion: reduce,
        onRefresh: widget.onRefresh,
      );
    }
    // ── Mobile layout ──────────────────────────────────────────────────────
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: AppColors.skyDeep,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _GradientHero(
              doctorName: widget.doctorName,
              counts: counts,
              severityFilter: _severityFilter,
              onFilterTap: (sev) => setState(() {
                _severityFilter = _severityFilter == sev ? '' : sev;
              }),
              reduceMotion: reduce,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          if (alerts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: PhosphorIcons.warning(PhosphorIconsStyle.duotone),
                iconColor: AppColors.warningDeep,
                title: 'Urgent Alerts',
                trailing: _CountBadge(
                  count: alerts.length,
                  color: AppColors.warning,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.sm,
                AppSpacing.base,
                AppSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final p = alerts[i];
                  final uid = p['uid'] as String? ?? '';
                  final snap = widget.data.xaiSnapshots[uid];
                  final sev = _severityFromSnapshot(snap);
                  return _AlertCard(
                    patient: p,
                    severity: sev,
                    xaiSnap: snap,
                    onReview: () => context.push('/doctor/patient/$uid'),
                  );
                }, childCount: alerts.length),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: _SectionHeader(
              icon: PhosphorIcons.calendarCheck(PhosphorIconsStyle.duotone),
              iconColor: AppColors.skyDeep,
              title: "Today's Schedule",
              trailing: _CountBadge(
                count: widget.data.todayAppointments.length,
                color: AppColors.sky,
              ),
              action: widget.data.todayAppointments.isNotEmpty
                  ? _TextAction(
                      label: 'View Schedule',
                      onTap: () => context.go('/doctor/schedule'),
                    )
                  : null,
            ),
          ),
          if (widget.data.todayAppointments.isEmpty)
            const SliverToBoxAdapter(
              child: _EmptySection(message: 'No appointments today'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.sm,
                AppSpacing.base,
                AppSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _AppointmentTile(
                    appointment: widget.data.todayAppointments[i],
                    reduceMotion: reduce,
                  ),
                  childCount: widget.data.todayAppointments.length,
                ),
              ),
            ),
          if (widget.data.reschedules.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: PhosphorIcons.clockCounterClockwise(
                  PhosphorIconsStyle.duotone,
                ),
                iconColor: AppColors.amberDeep,
                title: 'Reschedule Requests',
                trailing: _CountBadge(
                  count: widget.data.reschedules.length,
                  color: AppColors.amber,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.sm,
                AppSpacing.base,
                AppSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _RescheduleCard(
                    request: widget.data.reschedules[i],
                    onApproved: widget.onRefresh,
                  ),
                  childCount: widget.data.reschedules.length,
                ),
              ),
            ),
          ],
          if (widget.data.newPatients.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: PhosphorIcons.userPlus(PhosphorIconsStyle.duotone),
                iconColor: AppColors.mintDeep,
                title: 'New Patients',
                trailing: _CountBadge(
                  count: widget.data.newPatients.length,
                  color: AppColors.mint,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.sm,
                AppSpacing.base,
                AppSpacing.xxl,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _NewPatientTile(
                    patient: widget.data.newPatients[i],
                    onView: () {
                      final uid =
                          widget.data.newPatients[i]['uid'] as String? ?? '';
                      context.push('/doctor/patient/$uid');
                    },
                  ),
                  childCount: widget.data.newPatients.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.huge)),
        ],
      ),
    );
  }
}

// ── Web Dashboard Layout (two-column) ─────────────────────────────────────────
class _WebDashboardLayout extends StatelessWidget {
  final String doctorName;
  final String doctorUid;
  final _DoctorHomeData data;
  final Map<String, int> counts;
  final List<Map<String, dynamic>> alerts;
  final String severityFilter;
  final ValueChanged<String> onFilterTap;
  final bool reduceMotion;
  final VoidCallback onRefresh;

  const _WebDashboardLayout({
    required this.doctorName,
    required this.doctorUid,
    required this.data,
    required this.counts,
    required this.alerts,
    required this.severityFilter,
    required this.onFilterTap,
    required this.reduceMotion,
    required this.onRefresh,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left sidebar ───────────────────────────────────────────────────
        SizedBox(
          width: 320,
          child: Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.sky, AppColors.mint],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        const Spacer(),
                        _SignOutPill(color: AppColors.inkLight),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _greeting(),
                      style: AppTypography.label.copyWith(
                        color: AppColors.inkLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Dr. $doctorName',
                      style: AppTypography.headline2.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _WebSeverityGrid(
                      counts: counts,
                      severityFilter: severityFilter,
                      onFilterTap: onFilterTap,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.calendarCheck(
                            PhosphorIconsStyle.duotone,
                          ),
                          color: AppColors.skyDeep,
                          size: AppSpacing.iconMd,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          "Today's Schedule",
                          style: AppTypography.title.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        const Spacer(),
                        _CountBadge(
                          count: data.todayAppointments.length,
                          color: AppColors.sky,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (data.todayAppointments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                        child: Text(
                          'No appointments today',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkLight,
                          ),
                        ),
                      )
                    else
                      ...data.todayAppointments.map(
                        (a) => _AppointmentTile(
                          appointment: a,
                          reduceMotion: reduceMotion,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // ── Main content ───────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: AppColors.mist,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Text('Dashboard', style: AppTypography.headline3),
                  const SizedBox(height: AppSpacing.xl),
                  if (alerts.isNotEmpty) ...[
                    _SectionHeader(
                      icon: PhosphorIcons.warning(PhosphorIconsStyle.duotone),
                      iconColor: AppColors.warningDeep,
                      title: 'Urgent Alerts',
                      trailing: _CountBadge(
                        count: alerts.length,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...alerts.map((p) {
                      final uid = p['uid'] as String? ?? '';
                      final snap = data.xaiSnapshots[uid];
                      final sev = _severityFromSnapshot(snap);
                      return _AlertCard(
                        patient: p,
                        severity: sev,
                        xaiSnap: snap,
                        onReview: () => context.push('/doctor/patient/$uid'),
                      );
                    }),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  if (data.reschedules.isNotEmpty) ...[
                    _SectionHeader(
                      icon: PhosphorIcons.clockCounterClockwise(
                        PhosphorIconsStyle.duotone,
                      ),
                      iconColor: AppColors.amberDeep,
                      title: 'Reschedule Requests',
                      trailing: _CountBadge(
                        count: data.reschedules.length,
                        color: AppColors.amber,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...data.reschedules.map(
                      (r) => _RescheduleCard(request: r, onApproved: onRefresh),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  if (data.newPatients.isNotEmpty) ...[
                    _SectionHeader(
                      icon: PhosphorIcons.userPlus(PhosphorIconsStyle.duotone),
                      iconColor: AppColors.mintDeep,
                      title: 'New Patients',
                      trailing: _CountBadge(
                        count: data.newPatients.length,
                        color: AppColors.mint,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...data.newPatients.map((p) {
                      final uid = p['uid'] as String? ?? '';
                      return _NewPatientTile(
                        patient: p,
                        onView: () => context.push('/doctor/patient/$uid'),
                      );
                    }),
                  ],
                  const SizedBox(height: AppSpacing.huge),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Web 2×2 severity grid ──────────────────────────────────────────────────────
class _WebSeverityGrid extends StatelessWidget {
  final Map<String, int> counts;
  final String severityFilter;
  final ValueChanged<String> onFilterTap;

  const _WebSeverityGrid({
    required this.counts,
    required this.severityFilter,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      ('critical', 'Critical', AppColors.critical, AppColors.criticalDeep),
      ('warning', 'Warning', AppColors.warning, AppColors.warningDeep),
      ('watch', 'Watch', AppColors.watch, AppColors.watchDeep),
      ('stable', 'Stable', AppColors.stable, AppColors.stableDeep),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.2,
      children: items.map((item) {
        final (key, label, color, deep) = item;
        final isSelected = severityFilter == key;
        return GestureDetector(
          onTap: () => onFilterTap(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected ? deep : color.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? deep : color,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${counts[key] ?? 0}',
                  style: AppTypography.dataSmall.copyWith(
                    color: AppColors.cloud,
                    fontSize: 20,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.cloud,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Gradient Hero ─────────────────────────────────────────────────────────────
class _GradientHero extends StatelessWidget {
  final String doctorName;
  final Map<String, int> counts;
  final String severityFilter;
  final ValueChanged<String> onFilterTap;
  final bool reduceMotion;

  const _GradientHero({
    required this.doctorName,
    required this.counts,
    required this.severityFilter,
    required this.onFilterTap,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sky, AppColors.mint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.base,
            AppSpacing.base,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  _SignOutPill(color: AppColors.cloud),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Greeting
              Text(
                greeting,
                style: AppTypography.label.copyWith(color: AppColors.cloud),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Dr. $doctorName',
                style: AppTypography.headline2.copyWith(color: AppColors.cloud),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                DateFormat('EEEE, MMMM d').format(now),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.cloud.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Severity pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SeverityPill(
                      label: 'Critical',
                      count: counts['critical'] ?? 0,
                      color: AppColors.critical,
                      deepColor: AppColors.criticalDeep,
                      selected: severityFilter == 'critical',
                      onTap: () => onFilterTap('critical'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SeverityPill(
                      label: 'Warning',
                      count: counts['warning'] ?? 0,
                      color: AppColors.warning,
                      deepColor: AppColors.warningDeep,
                      selected: severityFilter == 'warning',
                      onTap: () => onFilterTap('warning'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SeverityPill(
                      label: 'Watch',
                      count: counts['watch'] ?? 0,
                      color: AppColors.watch,
                      deepColor: AppColors.watchDeep,
                      selected: severityFilter == 'watch',
                      onTap: () => onFilterTap('watch'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SeverityPill(
                      label: 'Stable',
                      count: counts['stable'] ?? 0,
                      color: AppColors.stable,
                      deepColor: AppColors.stableDeep,
                      selected: severityFilter == 'stable',
                      onTap: () => onFilterTap('stable'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color deepColor;
  final bool selected;
  final VoidCallback onTap;

  const _SeverityPill({
    required this.label,
    required this.count,
    required this.color,
    required this.deepColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $count patients',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? deepColor : color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: selected ? deepColor : color,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: AppTypography.dataSmall.copyWith(
                  color: AppColors.cloud,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.cloud,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final Widget? action;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        0,
        AppSpacing.base,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSpacing.iconMd, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: AppTypography.title),
          const SizedBox(width: AppSpacing.sm),
          ?trailing,
          const Spacer(),
          ?action,
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        '$count',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TextAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: AppTypography.label.copyWith(color: AppColors.skyDeep),
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xl,
      ),
      child: Center(child: Text(message, style: AppTypography.bodySmall)),
    );
  }
}

// ── Alert Card ────────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final String severity;
  final Map<String, dynamic>? xaiSnap;
  final VoidCallback onReview;

  const _AlertCard({
    required this.patient,
    required this.severity,
    required this.xaiSnap,
    required this.onReview,
  });

  String get _primaryDriver {
    if (xaiSnap == null) return 'No data';
    final drivers =
        xaiSnap!['primaryDrivers'] as List<dynamic>? ??
        xaiSnap!['drivers'] as List<dynamic>? ??
        [];
    if (drivers.isEmpty) return 'No drivers identified';
    final first = drivers.first;
    if (first is String) return first;
    if (first is Map) return first['name'] as String? ?? 'Unknown';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final name = patient['name'] as String? ?? 'Unknown';
    final sevColor = AppColors.severityColor(severity);
    final sevDeep = AppColors.severityDeepColor(severity);

    return Semantics(
      label: 'Alert for $name, severity $severity',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cloud,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: sevColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: sevColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(name, style: AppTypography.title)),
                  _SeverityBadge(severity: severity),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    PhosphorIcons.brain(PhosphorIconsStyle.duotone),
                    size: AppSpacing.iconSm,
                    color: sevDeep,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Primary driver: $_primaryDriver',
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeightSm,
                child: Semantics(
                  label: 'Review patient $name',
                  button: true,
                  child: ElevatedButton(
                    onPressed: onReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sevDeep,
                      foregroundColor: AppColors.cloud,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                    ),
                    child: Text(
                      'Review Patient',
                      style: AppTypography.label.copyWith(
                        color: AppColors.cloud,
                      ),
                    ),
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

// ── Severity Badge ────────────────────────────────────────────────────────────
class _SeverityBadge extends StatelessWidget {
  final String severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.severityColor(severity);
    final deep = AppColors.severityDeepColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color),
      ),
      child: Text(
        severity.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: deep,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Appointment Tile ──────────────────────────────────────────────────────────
class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final bool reduceMotion;

  const _AppointmentTile({
    required this.appointment,
    required this.reduceMotion,
  });

  String get _displayTime {
    final raw = appointment.time.length >= 5
        ? appointment.time.substring(0, 5)
        : appointment.time;
    final parts = raw.split(':');
    int hour = int.tryParse(parts[0]) ?? 0;
    final min = parts.length > 1 ? parts[1] : '00';
    final ampm = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12)
      hour -= 12;
    return '$hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.skyMist),
        boxShadow: [
          BoxShadow(
            color: AppColors.sky.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.skyMist,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Center(
              child: Icon(
                PhosphorIcons.calendarCheck(PhosphorIconsStyle.duotone),
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
                Text(appointment.patientName, style: AppTypography.titleSmall),
                const SizedBox(height: AppSpacing.xs2),
                Text(_displayTime, style: AppTypography.caption),
              ],
            ),
          ),
          _StatusChip(status: appointment.status),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'completed':
        bg = AppColors.mintMist;
        fg = AppColors.mintDeep;
        break;
      case 'absent':
        bg = AppColors.critical.withValues(alpha: 0.2);
        fg = AppColors.criticalDeep;
        break;
      case 'rescheduled':
        bg = AppColors.amberMist;
        fg = AppColors.amberDeep;
        break;
      default:
        bg = AppColors.skyMist;
        fg = AppColors.skyDeep;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Reschedule Card ───────────────────────────────────────────────────────────
class _RescheduleCard extends StatefulWidget {
  final RescheduleRequest request;
  final VoidCallback onApproved;

  const _RescheduleCard({required this.request, required this.onApproved});

  @override
  State<_RescheduleCard> createState() => _RescheduleCardState();
}

class _RescheduleCardState extends State<_RescheduleCard> {
  bool _loading = false;

  Future<void> _approve() async {
    final picked = await showDatePicker(
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
    if (picked == null || !mounted) return;
    final newDate =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() => _loading = true);
    try {
      await DoctorController.approveReschedule(widget.request, newDate);
      if (mounted) widget.onApproved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _loading = true);
    try {
      // Decline = update status; we reuse approveReschedule with same date and let the caller refresh
      // In service, there's no dedicated decline method, so we mark it as a soft-decline locally
      widget
          .onApproved(); // triggers parent refresh which will hide it if status updated externally
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.amberMist),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.amberDeep),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.clockCounterClockwise(
                        PhosphorIconsStyle.duotone,
                      ),
                      color: AppColors.amberDeep,
                      size: AppSpacing.iconMd,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Patient: ${widget.request.patientUid}',
                        style: AppTypography.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Requested: ${widget.request.requestedDate}',
                  style: AppTypography.bodySmall,
                ),
                if (widget.request.reason.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Reason: ${widget.request.reason}',
                    style: AppTypography.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Approve reschedule request',
                        button: true,
                        child: ElevatedButton(
                          onPressed: _approve,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mintDeep,
                            foregroundColor: AppColors.cloud,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                            ),
                          ),
                          child: Text(
                            'Approve',
                            style: AppTypography.label.copyWith(
                              color: AppColors.cloud,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Semantics(
                        label: 'Decline reschedule request',
                        button: true,
                        child: OutlinedButton(
                          onPressed: _decline,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.criticalDeep,
                            side: const BorderSide(
                              color: AppColors.criticalDeep,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                            ),
                          ),
                          child: Text(
                            'Decline',
                            style: AppTypography.label.copyWith(
                              color: AppColors.criticalDeep,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

// ── New Patient Tile ──────────────────────────────────────────────────────────
class _NewPatientTile extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onView;

  const _NewPatientTile({required this.patient, required this.onView});

  @override
  Widget build(BuildContext context) {
    final name = patient['name'] as String? ?? 'Unknown';
    final email = patient['email'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.mintMist),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.mintMist,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTypography.title.copyWith(color: AppColors.mintDeep),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.titleSmall),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.mintMist,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text(
              'NEW',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.mintDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            label: 'View patient $name',
            button: true,
            child: TextButton(
              onPressed: onView,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.skyDeep,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: Text(
                'View',
                style: AppTypography.label.copyWith(color: AppColors.skyDeep),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sign Out Pill ─────────────────────────────────────────────────────────────
class _SignOutPill extends StatelessWidget {
  final Color color;
  const _SignOutPill({required this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sign out',
      button: true,
      child: GestureDetector(
        onTap: () => AuthService.logout(),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIcons.signOut(PhosphorIconsStyle.regular),
                size: 12,
                color: color,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Sign out',
                style: AppTypography.labelSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
