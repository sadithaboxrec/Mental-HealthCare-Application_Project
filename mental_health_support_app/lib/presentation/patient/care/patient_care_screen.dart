import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mental_health_support_app/core/models/appointment.dart';
import 'package:mental_health_support_app/core/models/medicine.dart';
import 'package:mental_health_support_app/core/models/prescription.dart';
import 'package:mental_health_support_app/core/services/patient_service.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_pill_button.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_text_field.dart';
import 'package:mental_health_support_app/presentation/components/atoms/shimmer_card.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

class PatientCareScreen extends ConsumerStatefulWidget {
  const PatientCareScreen({super.key});

  @override
  ConsumerState<PatientCareScreen> createState() => _PatientCareScreenState();
}

class _PatientCareScreenState extends ConsumerState<PatientCareScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.base,
              ),
              child: Text(
                'My Care',
                style: AppTypography.headline3.copyWith(color: AppColors.ink),
              ),
            ),
            _SegmentedControl(
              options: const ['Medications', 'Appointments'],
              selected: _tab,
              onSelect: (i) => setState(() => _tab = i),
              color: AppColors.lavenderDeep,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: _tab == 0
                  ? _MedicationsTab(ref: ref)
                  : _AppointmentsTab(ref: ref, context: context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segmented Control ─────────────────────────────────────────────────────────

class _SegmentedControl extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;
  final Color color;

  const _SegmentedControl({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.fog,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Row(
          children: options.asMap().entries.map((e) {
            final i = e.key;
            final label = e.value;
            final isSelected = i == selected;
            return Expanded(
              child: Semantics(
                label: label,
                button: true,
                selected: isSelected,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTypography.label.copyWith(
                        color: isSelected ? AppColors.cloud : AppColors.slate,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
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

// ── Medications Tab ───────────────────────────────────────────────────────────

class _MedicationsTab extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _MedicationsTab({required this.ref});

  @override
  ConsumerState<_MedicationsTab> createState() => _MedicationsTabState();
}

class _MedicationsTabState extends ConsumerState<_MedicationsTab> {
  bool _loading = true;
  Prescription? _prescription;
  String? _error;
  bool _notesExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userDoc = await ref.read(currentUserDocProvider.future);
      final uid = userDoc?['uid'] as String? ?? '';
      final rx = await PatientService.getActivePrescription(uid);
      if (!mounted) return;
      setState(() {
        _prescription = rx;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          children: const [
            ShimmerCard(height: 140),
            SizedBox(height: AppSpacing.base),
            ShimmerCard(height: 100),
            SizedBox(height: AppSpacing.sm),
            ShimmerCard(height: 100),
            SizedBox(height: AppSpacing.sm),
            ShimmerCard(height: 100),
          ],
        ),
      );
    }

    if (_error != null) {
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
              Text('Could not load medications', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xl),
              MindCarePillButton(
                label: 'Retry',
                onPressed: _load,
                color: AppColors.lavenderDeep,
                variant: PillButtonVariant.outlined,
              ),
            ],
          ),
        ),
      );
    }

    if (_prescription == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
                size: 72,
                color: AppColors.slate.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppSpacing.base),
              Text('No prescription on file', style: AppTypography.headline4),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your doctor will add one soon',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final rx = _prescription!;
    final notesLong = rx.notes.length > 100;
    final notesText = (!_notesExpanded && notesLong)
        ? '${rx.notes.substring(0, 100)}...'
        : rx.notes;

    return RefreshIndicator(
      color: AppColors.lavenderDeep,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.xs,
          AppSpacing.base,
          AppSpacing.huge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Glass header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.lavenderMist,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.lavenderDeep.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: PhosphorIcon(
                          PhosphorIcons.stethoscope(PhosphorIconsStyle.duotone),
                          size: AppSpacing.iconMd,
                          color: AppColors.lavenderDeep,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          rx.diagnosis,
                          style: AppTypography.headline4.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (rx.notes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      notesText,
                      style: AppTypography.body.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.inkLight,
                      ),
                    ),
                    if (notesLong)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _notesExpanded = !_notesExpanded),
                        child: Text(
                          _notesExpanded ? 'Show less' : 'Show more',
                          style: AppTypography.label.copyWith(
                            color: AppColors.lavenderDeep,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Current Medicines', style: AppTypography.headline4),
            const SizedBox(height: AppSpacing.sm),

            ...rx.medicines.map((med) => _MedicineCard(medicine: med)),
          ],
        ),
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final Medicine medicine;
  const _MedicineCard({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final timings = <String>[];
    if (medicine.morning) timings.add('Morning');
    if (medicine.afternoon) timings.add('Afternoon');
    if (medicine.night) timings.add('Night');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.mintMist,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.mintDeep.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: PhosphorIcon(
              PhosphorIcons.pill(PhosphorIconsStyle.duotone),
              size: AppSpacing.iconMd,
              color: AppColors.mintDeep,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        medicine.name,
                        style: AppTypography.title.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (medicine.dose.isNotEmpty)
                      Text(
                        medicine.dose,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.mintDeep,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ...timings.map((t) => _TimingChip(label: t)),
                    if (medicine.beforeMeal) _MealChip(label: 'Before meal'),
                    if (medicine.afterMeal) _MealChip(label: 'After meal'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimingChip extends StatelessWidget {
  final String label;
  const _TimingChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.mintMist,
        border: Border.all(color: AppColors.mint),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: AppColors.mintDeep),
      ),
    );
  }
}

class _MealChip extends StatelessWidget {
  final String label;
  const _MealChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.amberMist,
        border: Border.all(color: AppColors.amber),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: AppColors.amberDeep),
      ),
    );
  }
}

// ── Appointments Tab ──────────────────────────────────────────────────────────

class _AppointmentsTab extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final BuildContext context;
  const _AppointmentsTab({required this.ref, required this.context});

  @override
  ConsumerState<_AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends ConsumerState<_AppointmentsTab> {
  bool _loading = true;
  Appointment? _nextAppointment;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userDoc = await ref.read(currentUserDocProvider.future);
      final uid = userDoc?['uid'] as String? ?? '';
      final appt = await PatientService.getNextAppointment(uid);
      if (!mounted) return;
      setState(() {
        _nextAppointment = appt;
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

  void _showRescheduleSheet(BuildContext ctx, Appointment appt) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.cloud,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (sheetCtx) => _RescheduleSheet(
        appointment: appt,
        onSubmit: (date, reason) async {
          final userDoc = await ref.read(currentUserDocProvider.future);
          final uid = userDoc?['uid'] as String? ?? '';
          await PatientService.requestReschedule(
            patientUid: uid,
            doctorUid: appt.doctorUid,
            appointmentId: appt.id,
            requestedDate: date,
            reason: reason,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reschedule requested')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          children: const [
            ShimmerCard(height: 160),
            SizedBox(height: AppSpacing.base),
            ShimmerCard(height: 100),
          ],
        ),
      );
    }

    if (_error != null) {
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
              Text('Could not load appointments', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xl),
              MindCarePillButton(
                label: 'Retry',
                onPressed: _load,
                color: AppColors.lavenderDeep,
                variant: PillButtonVariant.outlined,
              ),
            ],
          ),
        ),
      );
    }

    if (_nextAppointment == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIcons.calendarX(PhosphorIconsStyle.duotone),
                size: 72,
                color: AppColors.slate.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppSpacing.base),
              Text('No upcoming appointments', style: AppTypography.headline4),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your doctor will schedule one',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final appt = _nextAppointment!;

    return RefreshIndicator(
      color: AppColors.lavenderDeep,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: AppSpacing.xs,
          bottom: AppSpacing.huge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Text('Next Appointment', style: AppTypography.headline4),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.lavenderMist, AppColors.fog],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.lavenderMist,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: PhosphorIcon(
                          PhosphorIcons.calendarCheck(
                            PhosphorIconsStyle.duotone,
                          ),
                          size: AppSpacing.iconLg,
                          color: AppColors.lavenderDeep,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appt.date,
                              style: AppTypography.title.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                            Text(appt.time, style: AppTypography.bodySmall),
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
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          appt.status,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.lavenderDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MindCarePillButton(
                    label: 'Request Reschedule',
                    onPressed: () => _showRescheduleSheet(context, appt),
                    variant: PillButtonVariant.ghost,
                    color: AppColors.lavenderDeep,
                    compact: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reschedule Sheet ──────────────────────────────────────────────────────────

class _RescheduleSheet extends StatefulWidget {
  final Appointment appointment;
  final Future<void> Function(String date, String reason) onSubmit;

  const _RescheduleSheet({required this.appointment, required this.onSubmit});

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  DateTime? _selectedDate;
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.lavenderDeep,
            onPrimary: AppColors.cloud,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please pick a date')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final dateStr =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      await widget.onSubmit(dateStr, _reasonCtrl.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.base,
        AppSpacing.xl,
        AppSpacing.xl + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Request Reschedule', style: AppTypography.headline4),
            const SizedBox(height: AppSpacing.base),

            // Date picker button
            Semantics(
              label: _selectedDate == null
                  ? 'Pick a new date'
                  : 'Selected date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              button: true,
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: AppColors.fog,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: _selectedDate != null
                        ? Border.all(color: AppColors.lavender, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.calendarBlank(PhosphorIconsStyle.regular),
                        size: AppSpacing.iconMd,
                        color: AppColors.lavenderDeep,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _selectedDate == null
                            ? 'Pick a new date'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: AppTypography.body.copyWith(
                          color: _selectedDate == null
                              ? AppColors.slate
                              : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Reason field
            MindCareTextField(
              controller: _reasonCtrl,
              label: 'Reason (optional)',
              hint: 'Why do you need to reschedule?',
              maxLines: 3,
              prefixIcon: PhosphorIcons.chatText(PhosphorIconsStyle.regular),
            ),
            const SizedBox(height: AppSpacing.xl),

            MindCarePillButton(
              label: 'Submit Request',
              onPressed: _submitting ? null : _submit,
              isLoading: _submitting,
              color: AppColors.lavenderDeep,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
