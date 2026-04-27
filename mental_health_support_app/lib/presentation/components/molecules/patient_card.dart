import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/utils/app_date_utils.dart';
import 'package:mental_health_support_app/presentation/components/atoms/severity_badge.dart';

class PatientCard extends StatelessWidget {
  final String patientId;
  final String name;
  final String severity;
  final int xaiScore;
  final DateTime? lastActive;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;
  final VoidCallback? onViewReport;

  const PatientCard({
    super.key,
    required this.patientId,
    required this.name,
    required this.severity,
    required this.xaiScore,
    this.lastActive,
    this.onTap,
    this.onMessage,
    this.onViewReport,
  });

  @override
  Widget build(BuildContext context) {
    final deep = AppColors.severityDeepColor(severity);
    final lastActiveStr = lastActive != null
        ? AppDateUtils.timeAgo(lastActive!)
        : 'Unknown';

    return Semantics(
      label:
          'Patient $name, severity: $severity, wellness score $xaiScore, last active $lastActiveStr',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.cloud,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.lavenderMist,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: AppTypography.headline4.copyWith(
                          color: AppColors.lavenderDeep,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Name and severity
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTypography.title),
                        const SizedBox(height: AppSpacing.xs),
                        SeverityBadge(severity: severity, compact: true),
                      ],
                    ),
                  ),
                  // XAI score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        xaiScore.toString(),
                        style: AppTypography.dataMedium.copyWith(color: deep),
                      ),
                      Text('/ 10', style: AppTypography.labelSmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Last active
              Row(
                children: [
                  PhosphorIcon(
                    PhosphorIcons.clockCounterClockwise(
                      PhosphorIconsStyle.regular,
                    ),
                    size: 12,
                    color: AppColors.slate,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Last active $lastActiveStr',
                    style: AppTypography.bodySmall,
                  ),
                  const Spacer(),
                  // Action buttons
                  if (onMessage != null)
                    _IconAction(
                      icon: PhosphorIcons.chatCircle(
                        PhosphorIconsStyle.duotone,
                      ),
                      onTap: onMessage!,
                      label: 'Message',
                      color: AppColors.skyDeep,
                    ),
                  if (onViewReport != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _IconAction(
                      icon: PhosphorIcons.chartLineUp(
                        PhosphorIconsStyle.duotone,
                      ),
                      onTap: onViewReport!,
                      label: 'View report',
                      color: AppColors.lavenderDeep,
                    ),
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

class _IconAction extends StatelessWidget {
  final PhosphorIconData icon;
  final VoidCallback onTap;
  final String label;
  final Color color;

  const _IconAction({
    required this.icon,
    required this.onTap,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: PhosphorIcon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
