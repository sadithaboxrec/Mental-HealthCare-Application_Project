import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mental_health_support_app/core/assets/app_assets.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/controllers/patient_controller.dart';
import 'package:mental_health_support_app/core/models/daily_log.dart';
import 'package:mental_health_support_app/core/models/prescription.dart';
import 'package:mental_health_support_app/core/models/appointment.dart';
import 'package:mental_health_support_app/core/models/diary_entry.dart';
import 'package:mental_health_support_app/core/utils/app_date_utils.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mood_orb.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_asset.dart';
import 'package:mental_health_support_app/presentation/components/atoms/shimmer_card.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_pill_button.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  bool _loading = true;
  String? _error;

  DailyLog? _todayLog;
  Prescription? _prescription;
  Appointment? _nextAppointment;
  List<DiaryEntry> _recentEntries = [];
  String _patientName = 'Patient';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userDoc = await ref.read(currentUserDocProvider.future);
      final uid = userDoc?['uid'] as String? ?? '';
      if (uid.isEmpty) throw Exception('User not found');

      final results = await Future.wait([
        PatientController.getTodayLog(uid),
        PatientController.getActivePrescription(uid),
        PatientController.getNextAppointment(uid),
        PatientController.getDiaryEntries(uid),
      ]);

      if (!mounted) return;
      setState(() {
        _patientName = (userDoc?['name'] as String?)?.trim().isNotEmpty == true
            ? (userDoc!['name'] as String).trim()
            : 'Patient';
        _todayLog = results[0] as DailyLog?;
        _prescription = results[1] as Prescription?;
        _nextAppointment = results[2] as Appointment?;
        final entries = results[3] as List<DiaryEntry>;
        _recentEntries = entries.take(1).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<String> _getUid() async {
    final userDoc = await ref.read(currentUserDocProvider.future);
    return userDoc?['uid'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _error != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        children: [
          const ShimmerCard(height: 200),
          const SizedBox(height: AppSpacing.base),
          const ShimmerCard(height: 140),
          const SizedBox(height: AppSpacing.base),
          const ShimmerCard(height: 100),
          const SizedBox(height: AppSpacing.base),
          const ShimmerCard(height: 100),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIcons.wifiSlash(PhosphorIconsStyle.duotone),
              size: AppSpacing.iconHuge,
              color: AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.base),
            Text('Something went wrong', style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? '',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            MindCarePillButton(label: 'Retry', onPressed: _load),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      color: AppColors.lavenderDeep,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GradientHeroHeader(
              patientName: _patientName,
              greeting: AppDateUtils.greetingTime(),
              dateStr: AppDateUtils.formatDate(DateTime.now()),
              todayLog: _todayLog,
            ),
            const SizedBox(height: AppSpacing.base),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Pulse", style: AppTypography.headline4),
                  const SizedBox(height: AppSpacing.sm),
                  _MoodTrackerCard(
                    todayLog: _todayLog,
                    onMoodSelected: (mood) async {
                      final uid = await _getUid();
                      if (uid.isEmpty) return;
                      await PatientController.updateMood(uid, mood);
                      _load();
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _SleepCard(
                          sleepHours: _todayLog?.sleepHours ?? '',
                          onSave: (hours) async {
                            final uid = await _getUid();
                            if (uid.isEmpty) return;
                            await PatientController.updateSleep(uid, hours);
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _WaterCard(
                          count: _todayLog?.waterIntake ?? 0,
                          onAdd: () async {
                            final uid = await _getUid();
                            if (uid.isEmpty) return;
                            await PatientController.addWater(uid, 1);
                            _load();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _MedicationCard(
                    taken: _todayLog?.medicationTaken ?? false,
                    medicines:
                        _prescription?.medicines.map((m) => m.name).toList() ??
                        [],
                    onToggle: (val) async {
                      final uid = await _getUid();
                      if (uid.isEmpty) return;
                      await PatientController.updateMedication(uid, val);
                      _load();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Actions', style: AppTypography.headline4),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionPill(
                          label: 'Write in Journal',
                          icon: PhosphorIcons.notebook(
                            PhosphorIconsStyle.duotone,
                          ),
                          color: AppColors.lavender,
                          onTap: () => context.go('/patient/journal'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _QuickActionPill(
                          label: 'Talk to Support',
                          icon: PhosphorIcons.chatTeardrop(
                            PhosphorIconsStyle.duotone,
                          ),
                          color: AppColors.sky,
                          onTap: () => context.push('/patient/chat'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionPill(
                          label: 'My Medicines',
                          icon: PhosphorIcons.pill(PhosphorIconsStyle.duotone),
                          color: AppColors.mint,
                          onTap: () => context.go('/patient/care'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _QuickActionPill(
                          label: 'Appointments',
                          icon: PhosphorIcons.calendarCheck(
                            PhosphorIconsStyle.duotone,
                          ),
                          color: AppColors.amber,
                          onTap: () => context.go('/patient/care'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            if (_nextAppointment != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                ),
                child: _NextAppointmentCard(appointment: _nextAppointment!),
              ),
            if (_recentEntries.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.base),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                ),
                child: _RecentJournalCard(entry: _recentEntries.first),
              ),
            ],
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }
}

// ── Gradient Hero Header ──────────────────────────────────────────────────────

class _GradientHeroHeader extends StatelessWidget {
  final String patientName;
  final String greeting;
  final String dateStr;
  final DailyLog? todayLog;

  const _GradientHeroHeader({
    required this.patientName,
    required this.greeting,
    required this.dateStr,
    required this.todayLog,
  });

  @override
  Widget build(BuildContext context) {
    final mood = todayLog?.mood ?? 0;
    final moodLabel = mood > 0
        ? ['Awful', 'Low', 'Neutral', 'Good', 'Great'][mood.clamp(1, 5) - 1]
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lavender, AppColors.sky],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusXl),
          bottomRight: Radius.circular(AppSpacing.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavender.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      patientName,
                      style: AppTypography.headline2.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      dateStr,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkLight,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 112,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const MindCareAsset(
                      asset: AppAssets.patientHomeHeader,
                      width: 110,
                      height: 92,
                      fallbackIcon: PhosphorIconsDuotone.brain,
                      fallbackColor: AppColors.lavenderDeep,
                    ),
                    if (mood > 0)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: MoodOrb(
                          level: mood.clamp(1, 5),
                          size: 44,
                          selected: true,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (moodLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.cloud.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIcons.sparkle(PhosphorIconsStyle.duotone),
                    size: 14,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    "Today's mood: $moodLabel",
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Mood Tracker Card ─────────────────────────────────────────────────────────

class _MoodTrackerCard extends StatelessWidget {
  final DailyLog? todayLog;
  final ValueChanged<int> onMoodSelected;

  const _MoodTrackerCard({
    required this.todayLog,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final mood = todayLog?.mood ?? 0;
    final hasLogged = mood > 0;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.smiley(PhosphorIconsStyle.duotone),
                size: AppSpacing.iconMd,
                color: AppColors.lavenderDeep,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Mood',
                style: AppTypography.title.copyWith(color: AppColors.ink),
              ),
              const Spacer(),
              if (hasLogged)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lavenderMist,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    'Logged',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.lavenderDeep,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasLogged)
            Center(
              child: MoodOrb(
                level: mood.clamp(1, 5),
                size: 72,
                selected: true,
                showLabel: true,
              ),
            )
          else ...[
            Text('How are you feeling?', style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (i) {
                return MoodOrb(
                  level: i + 1,
                  size: 48,
                  showLabel: false,
                  onTap: () => onMoodSelected(i + 1),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sleep Card ────────────────────────────────────────────────────────────────

class _SleepCard extends StatelessWidget {
  final String sleepHours;
  final ValueChanged<String> onSave;

  const _SleepCard({required this.sleepHours, required this.onSave});

  void _showSleepSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cloud,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) => _SleepBottomSheet(
        initial: double.tryParse(sleepHours) ?? 7.0,
        onSave: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLogged = sleepHours.isNotEmpty;
    return Semantics(
      label: hasLogged ? 'Sleep: $sleepHours hours' : 'Log sleep',
      button: true,
      child: GestureDetector(
        onTap: () => _showSleepSheet(context),
        child: _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PhosphorIcon(
                    PhosphorIcons.moon(PhosphorIconsStyle.duotone),
                    size: AppSpacing.iconMd,
                    color: AppColors.lavenderDeep,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Sleep', style: AppTypography.titleSmall),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (hasLogged) ...[
                Text(
                  sleepHours,
                  style: AppTypography.dataMedium.copyWith(
                    color: AppColors.lavenderDeep,
                  ),
                ),
                Text('hours', style: AppTypography.caption),
              ] else ...[
                Text(
                  'Log sleep',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                PhosphorIcon(
                  PhosphorIcons.plus(PhosphorIconsStyle.regular),
                  size: AppSpacing.iconMd,
                  color: AppColors.lavender,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SleepBottomSheet extends StatefulWidget {
  final double initial;
  final ValueChanged<String> onSave;
  const _SleepBottomSheet({required this.initial, required this.onSave});

  @override
  State<_SleepBottomSheet> createState() => _SleepBottomSheetState();
}

class _SleepBottomSheetState extends State<_SleepBottomSheet> {
  late double _hours;

  @override
  void initState() {
    super.initState();
    _hours = widget.initial.clamp(4.0, 12.0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Log Sleep', style: AppTypography.headline4),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '${_hours.toStringAsFixed(1)} hours',
            style: AppTypography.dataLarge.copyWith(
              color: AppColors.lavenderDeep,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Slider(
            value: _hours,
            min: 4,
            max: 12,
            divisions: 16,
            activeColor: AppColors.lavenderDeep,
            inactiveColor: AppColors.lavenderMist,
            onChanged: (v) => setState(() => _hours = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('4 hrs', style: AppTypography.caption),
              Text('12 hrs', style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          MindCarePillButton(
            label: 'Save',
            width: double.infinity,
            onPressed: () {
              widget.onSave(_hours.toStringAsFixed(1));
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: AppSpacing.base),
        ],
      ),
    );
  }
}

// ── Water Card ────────────────────────────────────────────────────────────────

class _WaterCard extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;

  const _WaterCard({required this.count, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final progress = (count / 8).clamp(0.0, 1.0);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.drop(PhosphorIconsStyle.duotone),
                size: AppSpacing.iconMd,
                color: AppColors.sky,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('Water', style: AppTypography.titleSmall),
              const Spacer(),
              Semantics(
                label: 'Add one glass of water',
                button: true,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onAdd();
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.sky.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 18,
                      color: AppColors.skyDeep,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$count',
            style: AppTypography.dataMedium.copyWith(color: AppColors.skyDeep),
          ),
          Text('/ 8 glasses', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.fog,
            valueColor: const AlwaysStoppedAnimation(AppColors.skyDeep),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        ],
      ),
    );
  }
}

// ── Medication Card ───────────────────────────────────────────────────────────

class _MedicationCard extends StatelessWidget {
  final bool taken;
  final List<String> medicines;
  final ValueChanged<bool> onToggle;

  const _MedicationCard({
    required this.taken,
    required this.medicines,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: taken ? AppColors.mintMist : AppColors.fog,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: PhosphorIcon(
              PhosphorIcons.pill(PhosphorIconsStyle.duotone),
              size: AppSpacing.iconLg,
              color: taken ? AppColors.mintDeep : AppColors.slate,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medication', style: AppTypography.title),
                if (medicines.isNotEmpty)
                  Text(
                    medicines.take(2).join(', '),
                    style: AppTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text('No prescription', style: AppTypography.bodySmall),
              ],
            ),
          ),
          Semantics(
            label: taken
                ? 'Mark medication as not taken'
                : 'Mark medication as taken',
            toggled: taken,
            child: Switch.adaptive(
              value: taken,
              onChanged: onToggle,
              activeColor: AppColors.mintDeep,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Action Pill ─────────────────────────────────────────────────────────

class _QuickActionPill extends StatelessWidget {
  final String label;
  final PhosphorIconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(icon, size: AppSpacing.iconMd, color: AppColors.ink),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.label.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Next Appointment Card ─────────────────────────────────────────────────────

class _NextAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _NextAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Next Appointment', style: AppTypography.headline4),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.lavenderMist, AppColors.fog],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: PhosphorIcon(
                  PhosphorIcons.calendarCheck(PhosphorIconsStyle.duotone),
                  size: AppSpacing.iconLg,
                  color: AppColors.lavenderDeep,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.date, style: AppTypography.title),
                    Text(
                      AppDateUtils.formatTime(appointment.time),
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lavenderMist,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  appointment.status,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.lavenderDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Recent Journal Card ───────────────────────────────────────────────────────

class _RecentJournalCard extends StatelessWidget {
  final DiaryEntry entry;
  const _RecentJournalCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Journal', style: AppTypography.headline4),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () => context.push('/patient/journal/editor?id=${entry.id}'),
          child: Container(
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
                      PhosphorIcons.notebook(PhosphorIconsStyle.duotone),
                      size: AppSpacing.iconMd,
                      color: AppColors.lavenderDeep,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(entry.createdDateKey, style: AppTypography.caption),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  entry.content,
                  style: AppTypography.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared Card Container ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

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
            color: AppColors.lavender.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
