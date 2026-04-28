import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/utils/severity_utils.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;
  final bool compact;

  const SeverityBadge({
    super.key,
    required this.severity,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.severityColor(severity);
    final deep = AppColors.severityDeepColor(severity);
    final label = SeverityUtils.label(severity);
    final icon = SeverityUtils.icon(severity);

    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.xs : AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon, size: compact ? 12 : 14, color: deep),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: deep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
