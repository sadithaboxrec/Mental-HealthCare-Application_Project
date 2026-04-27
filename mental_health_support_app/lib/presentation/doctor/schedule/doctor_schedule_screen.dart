import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import 'package:mental_health_support_app/core/models/appointment.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

class DoctorScheduleScreen extends ConsumerStatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  ConsumerState<DoctorScheduleScreen> createState() =>
      _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends ConsumerState<DoctorScheduleScreen> {
  static final _db = FirebaseFirestore.instance;

  DateTime _focusWeek = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  List<Appointment> _appointments = [];
  bool _loading = false;
  String? _error;
  String? _doctorUid;

  List<DateTime> get _weekDays {
    final monday = _focusWeek.subtract(Duration(days: _focusWeek.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final userDoc = ref.read(currentUserDocProvider).asData?.value;
    _doctorUid = userDoc?['uid'] as String? ?? '';
    await _loadForDate(_selectedDate);
  }

  Future<void> _loadForDate(DateTime date) async {
    if (_doctorUid == null || _doctorUid!.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final key = _dateKey(date);
      final snap = await _db
          .collection('appointments')
          .where('doctorUid', isEqualTo: _doctorUid)
          .where('date', isEqualTo: key)
          .orderBy('time')
          .get();
      final appts = snap.docs
          .map((d) => Appointment.fromMap(d.id, d.data()))
          .toList();
      if (mounted) setState(() => _appointments = appts);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectDate(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDate = date);
    _loadForDate(date);
  }

  void _prevWeek() {
    HapticFeedback.lightImpact();
    setState(() => _focusWeek = _focusWeek.subtract(const Duration(days: 7)));
  }

  void _nextWeek() {
    HapticFeedback.lightImpact();
    setState(() => _focusWeek = _focusWeek.add(const Duration(days: 7)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Schedule', style: AppTypography.headline3),
                        Text(
                          DateFormat('MMMM yyyy').format(_focusWeek),
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _NavBtn(
                    icon: PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                    onTap: _prevWeek,
                    label: 'Previous week',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _NavBtn(
                    icon: PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                    onTap: _nextWeek,
                    label: 'Next week',
                  ),
                ],
              ),
            ),

            // ── Week strip ─────────────────────────────────────────
            _WeekStrip(
              days: _weekDays,
              selected: _selectedDate,
              today: DateTime.now(),
              onTap: _selectDate,
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Day header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIcons.calendarBlank(PhosphorIconsStyle.duotone),
                    size: AppSpacing.iconMd,
                    color: AppColors.skyDeep,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    DateFormat('EEEE, d MMMM').format(_selectedDate),
                    style: AppTypography.title.copyWith(
                      color: AppColors.skyDeep,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Body ───────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.skyDeep,
                        strokeWidth: 2,
                      ),
                    )
                  : _error != null
                  ? _ErrorView(
                      message: _error!,
                      onRetry: () => _loadForDate(_selectedDate),
                    )
                  : _appointments.isEmpty
                  ? _EmptyDay(date: _selectedDate)
                  : RefreshIndicator(
                      color: AppColors.skyDeep,
                      onRefresh: () => _loadForDate(_selectedDate),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.base,
                          0,
                          AppSpacing.base,
                          AppSpacing.huge,
                        ),
                        itemCount: _appointments.length,
                        itemBuilder: (ctx, i) =>
                            _ApptRow(appt: _appointments[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Week strip ──────────────────────────────────────────────────────────────
class _WeekStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onTap;

  const _WeekStrip({
    required this.days,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.sky.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: days.map((day) {
          final isSelected = _same(day, selected);
          final isToday = _same(day, today);
          return Expanded(
            child: Semantics(
              label:
                  '${DateFormat('EEEE d MMMM').format(day)}${isToday ? ', today' : ''}',
              button: true,
              selected: isSelected,
              child: GestureDetector(
                onTap: () => onTap(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.skyDeep : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(day).substring(0, 1),
                        style: AppTypography.caption.copyWith(
                          color: isSelected
                              ? AppColors.cloud.withValues(alpha: 0.75)
                              : AppColors.slate,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: AppTypography.title.copyWith(
                          color: isSelected ? AppColors.cloud : AppColors.ink,
                          fontWeight: isToday
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isToday && !isSelected ? 4 : 0,
                        height: isToday && !isSelected ? 4 : 0,
                        decoration: const BoxDecoration(
                          color: AppColors.skyDeep,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Appointment row ─────────────────────────────────────────────────────────
class _ApptRow extends StatelessWidget {
  final Appointment appt;
  const _ApptRow({required this.appt});

  Color get _statusDeep {
    switch (appt.status) {
      case 'completed':
        return AppColors.stableDeep;
      case 'absent':
        return AppColors.criticalDeep;
      case 'rescheduled':
        return AppColors.watchDeep;
      default:
        return AppColors.skyDeep;
    }
  }

  Color get _statusBg {
    switch (appt.status) {
      case 'completed':
        return AppColors.mintMist;
      case 'absent':
        return AppColors.criticalDeep.withValues(alpha: 0.08);
      case 'rescheduled':
        return AppColors.amberMist;
      default:
        return AppColors.skyMist;
    }
  }

  IconData get _statusIcon {
    switch (appt.status) {
      case 'completed':
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone);
      case 'absent':
        return PhosphorIcons.xCircle(PhosphorIconsStyle.duotone);
      case 'rescheduled':
        return PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.duotone);
      default:
        return PhosphorIcons.clock(PhosphorIconsStyle.duotone);
    }
  }

  String get _statusLabel {
    switch (appt.status) {
      case 'completed':
        return 'Completed';
      case 'absent':
        return 'Absent';
      case 'rescheduled':
        return 'Rescheduled';
      default:
        return 'Scheduled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Appointment with ${appt.patientName} at ${appt.time}, $_statusLabel',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.cloud,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.sky.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Time sidebar
            Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.skyMist,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLg),
                  bottomLeft: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(
                    PhosphorIcons.clock(PhosphorIconsStyle.duotone),
                    size: AppSpacing.iconMd,
                    color: AppColors.skyDeep,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    appt.time,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.skyDeep,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.sky.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          appt.patientName.isNotEmpty
                              ? appt.patientName[0].toUpperCase()
                              : '?',
                          style: AppTypography.label.copyWith(
                            color: AppColors.skyDeep,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appt.patientName,
                            style: AppTypography.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _statusBg,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PhosphorIcon(
                                  _statusIcon,
                                  size: 11,
                                  color: _statusDeep,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _statusLabel,
                                  style: AppTypography.caption.copyWith(
                                    color: _statusDeep,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav button ──────────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  const _NavBtn({required this.icon, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppSpacing.tapTargetMin,
          height: AppSpacing.tapTargetMin,
          decoration: BoxDecoration(
            color: AppColors.cloud,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.divider),
          ),
          child: Center(
            child: PhosphorIcon(icon, size: 16, color: AppColors.skyDeep),
          ),
        ),
      ),
    );
  }
}

// ── Empty day ───────────────────────────────────────────────────────────────
class _EmptyDay extends StatelessWidget {
  final DateTime date;
  const _EmptyDay({required this.date});

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.skyMist,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.calendarBlank(PhosphorIconsStyle.duotone),
                  size: AppSpacing.iconHuge,
                  color: AppColors.skyDeep,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              isToday ? 'Clear today' : 'No appointments',
              style: AppTypography.title,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isToday
                  ? 'Your schedule is free for today'
                  : 'Nothing booked for ${DateFormat('d MMMM').format(date)}',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ──────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIcons.wifiSlash(PhosphorIconsStyle.regular),
              size: AppSpacing.iconHuge,
              color: AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.base),
            Text('Could not load schedule', style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.skyDeep,
                foregroundColor: AppColors.cloud,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
              child: Text(
                'Retry',
                style: AppTypography.label.copyWith(color: AppColors.cloud),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
