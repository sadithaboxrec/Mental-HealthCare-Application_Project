import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mental_health_support_app/core/assets/app_assets.dart';
import 'package:mental_health_support_app/core/models/appointment.dart';
import 'package:mental_health_support_app/core/models/prescription.dart';
import 'package:mental_health_support_app/core/models/medicine.dart';
import 'package:mental_health_support_app/core/services/guardian_service.dart';
import 'package:mental_health_support_app/core/services/auth_service.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/utils/app_date_utils.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_asset.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mood_orb.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_pill_button.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

class GuardianHomeScreen extends ConsumerStatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  ConsumerState<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends ConsumerState<GuardianHomeScreen> {
  // Core identifiers
  String _guardianUid = '';
  String _patientUid = '';
  String _patientName = '';

  // Remote data
  Map<String, dynamic>? _todayLog;
  Prescription? _prescription;
  Appointment? _nextAppointment;

  // Loading states
  bool _loading = true;
  String? _error;

  // Editable log state
  int _selectedMood = 0;
  int _waterCount = 0;
  bool _medicationTaken = false;
  final _obsCtrl = TextEditingController();
  bool _savingObs = false;
  String _obsStatus = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userDoc = await ref.read(currentUserDocProvider.future);
      _guardianUid = userDoc?['uid'] ?? '';

      final patientUid = await GuardianService.getPatientUid(_guardianUid);
      if (patientUid == null) {
        throw Exception('No patient linked to this account.');
      }
      _patientUid = patientUid;
      _patientName =
          await GuardianService.getPatientName(patientUid) ?? 'Your patient';

      final results = await Future.wait([
        GuardianService.getTodayLogPublic(_guardianUid),
        GuardianService.getPatientActivePrescription(patientUid),
        GuardianService.getPatientNextAppointment(patientUid),
      ]);

      _todayLog = results[0] as Map<String, dynamic>?;
      _prescription = results[1] as Prescription?;
      _nextAppointment = results[2] as Appointment?;

      if (_todayLog != null) {
        _selectedMood = _todayLog?['mood'] as int? ?? 0;
        _waterCount = _todayLog?['waterIntake'] as int? ?? 0;
        _medicationTaken = _todayLog?['medicationTaken'] as bool? ?? false;
        _obsCtrl.text = _todayLog?['observations'] as String? ?? '';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleMedication(bool taken) async {
    if (taken) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          title: Text('Confirm Medication', style: AppTypography.headline4),
          content: Text(
            'Are you confirming that $_patientName has taken their medication?',
            style: AppTypography.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Confirm',
                style: TextStyle(color: AppColors.mintDeep),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    setState(() => _medicationTaken = taken);
    await GuardianService.updateMedication(_guardianUid, _patientUid, taken);
  }

  Future<void> _saveObservation() async {
    if (_obsCtrl.text.trim().isEmpty) return;
    setState(() {
      _savingObs = true;
      _obsStatus = 'Saving...';
    });
    try {
      await GuardianService.updateObservations(
        _guardianUid,
        _patientUid,
        _obsCtrl.text.trim(),
      );
      if (mounted) setState(() => _obsStatus = 'Saved ✓');
    } catch (_) {
      if (mounted) setState(() => _obsStatus = 'Save failed');
    } finally {
      if (mounted) setState(() => _savingObs = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.logout();
  }

  // ── Build helpers ──────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.mintDeep),
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
              PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
              size: 56,
              color: AppColors.criticalDeep,
            ),
            const SizedBox(height: AppSpacing.base),
            Text('Something went wrong', style: AppTypography.headline4),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? '',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            MindCarePillButton(
              label: 'Try Again',
              onPressed: _load,
              color: AppColors.mintDeep,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final padding = MediaQuery.of(context).padding;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.mint, AppColors.amber],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        padding.top + AppSpacing.base,
        AppSpacing.base,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watching over',
                      style: AppTypography.body.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.65),
                      ),
                    ),
                    Text(
                      _patientName,
                      style: AppTypography.headline2.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.shieldCheck(
                            PhosphorIconsStyle.duotone,
                          ),
                          size: 14,
                          color: AppColors.inkLight,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Guardian Dashboard',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const MindCareAsset(
                asset: AppAssets.guardianSupport,
                width: 112,
                height: 98,
                fallbackIcon: PhosphorIconsDuotone.shieldCheck,
                fallbackColor: AppColors.mintDeep,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientStatusCard() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.mint.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.user(PhosphorIconsStyle.duotone),
                color: AppColors.mintDeep,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Patient Status Today',
                style: AppTypography.label.copyWith(color: AppColors.mintDeep),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Mood
              Column(
                children: [
                  _selectedMood > 0
                      ? MoodOrb(level: _selectedMood, size: 52, selected: true)
                      : Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: AppColors.fog,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sentiment_neutral,
                            color: AppColors.slate,
                            size: 28,
                          ),
                        ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Mood', style: AppTypography.caption),
                ],
              ),
              // Medication
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _medicationTaken
                          ? AppColors.mintMist
                          : AppColors.critical.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      _medicationTaken ? '✓ Taken' : '✗ Not taken',
                      style: AppTypography.label.copyWith(
                        color: _medicationTaken
                            ? AppColors.mintDeep
                            : AppColors.criticalDeep,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Medication', style: AppTypography.caption),
                ],
              ),
              // Water
              Column(
                children: [
                  Text(
                    '$_waterCount',
                    style: AppTypography.dataMedium.copyWith(
                      color: AppColors.skyDeep,
                    ),
                  ),
                  Text('glasses', style: AppTypography.caption),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLogSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'Your Observations Today',
              style: AppTypography.headline4,
            ),
          ),

          // Mood selector
          _SectionCard(
            title: "How do you observe $_patientName's mood?",
            icon: PhosphorIcons.smiley(PhosphorIconsStyle.duotone),
            color: AppColors.mintDeep,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (i) {
                final level = i + 1;
                return Semantics(
                  label: 'Set mood level $level',
                  button: true,
                  selected: _selectedMood == level,
                  child: MoodOrb(
                    level: level,
                    size: 44,
                    showLabel: false,
                    selected: _selectedMood == level,
                    onTap: () async {
                      setState(() => _selectedMood = level);
                      HapticFeedback.selectionClick();
                      await GuardianService.updateMood(
                        _guardianUid,
                        _patientUid,
                        level,
                      );
                    },
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Water tracker
          _SectionCard(
            title: 'Water intake today',
            icon: PhosphorIcons.drop(PhosphorIconsStyle.duotone),
            color: AppColors.skyDeep,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Remove glass of water',
                  button: true,
                  child: GestureDetector(
                    onTap: _waterCount > 0
                        ? () {
                            HapticFeedback.selectionClick();
                            setState(
                              () =>
                                  _waterCount = (_waterCount - 1).clamp(0, 20),
                            );
                          }
                        : null,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.fog,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.remove,
                        color: _waterCount > 0
                            ? AppColors.inkLight
                            : AppColors.slate,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Column(
                  children: [
                    Text(
                      '$_waterCount',
                      style: AppTypography.dataMedium.copyWith(
                        color: AppColors.skyDeep,
                      ),
                    ),
                    Text('glasses', style: AppTypography.caption),
                  ],
                ),
                const SizedBox(width: AppSpacing.xl),
                Semantics(
                  label: 'Add glass of water',
                  button: true,
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      setState(() => _waterCount++);
                      await GuardianService.addWater(
                        _guardianUid,
                        _patientUid,
                        1,
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.skyDeep,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: AppColors.cloud),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Medication toggle
          _SectionCard(
            title: 'Has $_patientName taken their medication?',
            icon: PhosphorIcons.pill(PhosphorIconsStyle.duotone),
            color: AppColors.mintDeep,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: 'Mark medication not taken',
                          button: true,
                          toggled: !_medicationTaken,
                          child: GestureDetector(
                            onTap: () => _toggleMedication(false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: !_medicationTaken
                                    ? AppColors.criticalDeep
                                    : AppColors.fog,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(
                                    AppSpacing.radiusPill,
                                  ),
                                  bottomLeft: Radius.circular(
                                    AppSpacing.radiusPill,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Not Taken',
                                textAlign: TextAlign.center,
                                style: AppTypography.label.copyWith(
                                  color: !_medicationTaken
                                      ? AppColors.cloud
                                      : AppColors.slate,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Semantics(
                          label: 'Mark medication taken',
                          button: true,
                          toggled: _medicationTaken,
                          child: GestureDetector(
                            onTap: () => _toggleMedication(true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: _medicationTaken
                                    ? AppColors.mintDeep
                                    : AppColors.fog,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(
                                    AppSpacing.radiusPill,
                                  ),
                                  bottomRight: Radius.circular(
                                    AppSpacing.radiusPill,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Taken',
                                textAlign: TextAlign.center,
                                style: AppTypography.label.copyWith(
                                  color: _medicationTaken
                                      ? AppColors.cloud
                                      : AppColors.slate,
                                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildObservationsSection() {
    return _SectionCard(
      title: 'Write your observations',
      icon: PhosphorIcons.noteBlank(PhosphorIconsStyle.duotone),
      color: AppColors.amberDeep,
      child: Column(
        children: [
          TextField(
            controller: _obsCtrl,
            maxLines: 4,
            style: AppTypography.body.copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              hintText:
                  'How is $_patientName doing today? Any concerns or positive changes?',
              hintStyle: AppTypography.body.copyWith(color: AppColors.slate),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.fog,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _obsStatus,
                style: AppTypography.caption.copyWith(
                  color: _obsStatus.contains('✓')
                      ? AppColors.mintDeep
                      : AppColors.slate,
                ),
              ),
              MindCarePillButton(
                label: 'Save Observation',
                onPressed: _saveObservation,
                isLoading: _savingObs,
                compact: true,
                color: AppColors.amberDeep,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.calendar(PhosphorIconsStyle.duotone),
                  size: 18,
                  color: AppColors.lavenderDeep,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Next Appointment', style: AppTypography.headline4),
              ],
            ),
          ),
          if (_nextAppointment != null)
            _AppointmentTile(appointment: _nextAppointment!)
          else
            _buildEmptyState(
              icon: PhosphorIcons.calendarX(PhosphorIconsStyle.duotone),
              message: 'No upcoming appointments',
            ),
        ],
      ),
    );
  }

  Widget _buildMedicinesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.pill(PhosphorIconsStyle.duotone),
                  size: 18,
                  color: AppColors.mintDeep,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Current Medicines', style: AppTypography.headline4),
              ],
            ),
          ),
          if (_prescription != null && _prescription!.medicines.isNotEmpty)
            ..._prescription!.medicines.map((m) => _MedicineCard(medicine: m))
          else
            _buildEmptyState(
              icon: PhosphorIcons.pill(PhosphorIconsStyle.duotone),
              message: 'No active prescription',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required PhosphorIconData icon,
    required String message,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
            icon,
            size: 20,
            color: AppColors.slate.withValues(alpha: 0.5),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(message, style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSignOut() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.base,
      ),
      child: MindCarePillButton(
        label: 'Sign Out',
        variant: PillButtonVariant.destructive,
        onPressed: _signOut,
        width: double.infinity,
        compact: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: RefreshIndicator(
        color: AppColors.mintDeep,
        onRefresh: _load,
        child: _loading
            ? _buildLoading()
            : _error != null
            ? _buildError()
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeroHeader()),
                  SliverToBoxAdapter(child: _buildPatientStatusCard()),
                  SliverToBoxAdapter(child: _buildDailyLogSection()),
                  SliverToBoxAdapter(child: _buildObservationsSection()),
                  SliverToBoxAdapter(child: _buildAppointmentSection()),
                  SliverToBoxAdapter(child: _buildMedicinesSection()),
                  SliverToBoxAdapter(child: _buildSignOut()),
                  SliverToBoxAdapter(child: SizedBox(height: AppSpacing.huge)),
                ],
              ),
      ),
    );
  }
}

// ── Private helper widgets ─────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final PhosphorIconData icon;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTypography.titleSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.lavender.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavenderDeep.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lavenderMist,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Center(
              child: PhosphorIcon(
                PhosphorIconsRegular.calendar,
                size: 22,
                color: AppColors.lavenderDeep,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(appointment.date), style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.clock,
                      size: 12,
                      color: AppColors.slate,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      AppDateUtils.formatTime(appointment.time),
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatusBadge(status: appointment.status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return AppDateUtils.formatShortDate(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'scheduled'
        ? AppColors.mintDeep
        : status == 'rescheduled'
        ? AppColors.amberDeep
        : AppColors.slate;
    final bg = status == 'scheduled'
        ? AppColors.mintMist
        : status == 'rescheduled'
        ? AppColors.amberMist
        : AppColors.fog;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final Medicine medicine;

  const _MedicineCard({required this.medicine});

  String get _timingText {
    final slots = <String>[];
    if (medicine.morning) slots.add('Morning');
    if (medicine.afternoon) slots.add('Afternoon');
    if (medicine.night) slots.add('Night');
    if (slots.isEmpty) return 'As directed';
    return slots.join(' · ');
  }

  String get _mealText => medicine.beforeMeal ? 'Before meal' : 'After meal';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.mintMist,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Center(
              child: PhosphorIcon(
                PhosphorIconsRegular.pill,
                size: 18,
                color: AppColors.mintDeep,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${medicine.dose}  ·  $_timingText',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.mintMist,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text(
              _mealText,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.mintDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
