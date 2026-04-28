import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';

class MedicineCard extends StatelessWidget {
  final String name;
  final String? dose;
  final bool morning;
  final bool afternoon;
  final bool night;
  final bool beforeMeal;

  const MedicineCard({
    super.key,
    required this.name,
    this.dose,
    this.morning = false,
    this.afternoon = false,
    this.night = false,
    this.beforeMeal = false,
  });

  @override
  Widget build(BuildContext context) {
    final slots = <String>[];
    if (morning) slots.add('Morning');
    if (afternoon) slots.add('Afternoon');
    if (night) slots.add('Night');

    final timingLabel = slots.isNotEmpty ? slots.join(' & ') : 'As directed';
    final mealLabel = beforeMeal ? 'Before meal' : 'After meal';

    return Semantics(
      label:
          '$name${dose != null ? ', $dose' : ''}, taken $timingLabel $mealLabel',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.mintMist,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.mint.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.pill(PhosphorIconsStyle.duotone),
                  size: 20,
                  color: AppColors.mintDeep,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: AppTypography.title)),
                      if (dose != null)
                        Text(dose!, style: AppTypography.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      ...slots.map((s) => _SlotChip(label: s)),
                      _SlotChip(
                        label: mealLabel,
                        color: AppColors.amberDeep,
                        bg: AppColors.amberMist,
                      ),
                    ],
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

class _SlotChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _SlotChip({
    required this.label,
    this.color = AppColors.mintDeep,
    this.bg = AppColors.mintMist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }
}
