import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/presentation/components/atoms/metric_pill.dart';

class DailyPulseMetric {
  final PhosphorIconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const DailyPulseMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });
}

class DailyPulseRow extends StatelessWidget {
  final int? moodLevel;
  final String? sleepHours;
  final String? waterGlasses;
  final bool medicationTaken;
  final bool isLoading;
  final VoidCallback? onMoodTap;
  final VoidCallback? onSleepTap;
  final VoidCallback? onWaterTap;
  final VoidCallback? onMedicationTap;

  const DailyPulseRow({
    super.key,
    this.moodLevel,
    this.sleepHours,
    this.waterGlasses,
    this.medicationTaken = false,
    this.isLoading = false,
    this.onMoodTap,
    this.onSleepTap,
    this.onWaterTap,
    this.onMedicationTap,
  });

  List<DailyPulseMetric> get _metrics {
    return [
      DailyPulseMetric(
        icon: PhosphorIcons.smiley(PhosphorIconsStyle.duotone),
        value: moodLevel != null ? _moodLabel(moodLevel!) : '--',
        label: 'Mood',
        color: moodLevel != null
            ? AppColors.moodColor(moodLevel!)
            : AppColors.slate,
        onTap: onMoodTap,
        isLoading: isLoading,
      ),
      DailyPulseMetric(
        icon: PhosphorIcons.moon(PhosphorIconsStyle.duotone),
        value: sleepHours ?? '--',
        label: 'hrs sleep',
        color: AppColors.lavenderDeep,
        onTap: onSleepTap,
        isLoading: isLoading,
      ),
      DailyPulseMetric(
        icon: PhosphorIcons.drop(PhosphorIconsStyle.duotone),
        value: waterGlasses ?? '--',
        label: 'glasses',
        color: AppColors.skyDeep,
        onTap: onWaterTap,
        isLoading: isLoading,
      ),
      DailyPulseMetric(
        icon: PhosphorIcons.pill(PhosphorIconsStyle.duotone),
        value: isLoading ? '--' : (medicationTaken ? 'Taken' : 'Pending'),
        label: 'Meds',
        color: medicationTaken ? AppColors.mintDeep : AppColors.warningDeep,
        onTap: onMedicationTap,
        isLoading: isLoading,
      ),
    ];
  }

  String _moodLabel(int level) {
    const labels = ['Awful', 'Low', 'Neutral', 'Good', 'Great'];
    return labels[(level.clamp(1, 5)) - 1];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        itemCount: _metrics.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final m = _metrics[index];
          return MetricPill(
            icon: m.icon,
            value: m.value,
            label: m.label,
            color: m.color,
            onTap: m.onTap,
            isLoading: m.isLoading,
          );
        },
      ),
    );
  }
}
