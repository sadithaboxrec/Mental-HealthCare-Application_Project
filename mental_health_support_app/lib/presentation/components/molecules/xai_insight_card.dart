import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/presentation/components/atoms/severity_badge.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_pill_button.dart';

class XaiInsightCard extends StatelessWidget {
  final int score;
  final String severity;
  final double confidence;
  final List<String> primaryDrivers;
  final String screeningNote;
  final VoidCallback? onViewMore;

  const XaiInsightCard({
    super.key,
    required this.score,
    required this.severity,
    required this.confidence,
    required this.primaryDrivers,
    required this.screeningNote,
    this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.severityColor(severity);
    final deep = AppColors.severityDeepColor(severity);

    return Semantics(
      label: 'Wellness insight: $severity status, score $score',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
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
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          PhosphorIcons.brain(PhosphorIconsStyle.duotone),
                          size: 24,
                          color: deep,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wellness Insight',
                            style: AppTypography.label.copyWith(color: deep),
                          ),
                          const SizedBox(height: 2),
                          SeverityBadge(severity: severity, compact: true),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          score.toString(),
                          style: AppTypography.dataLarge.copyWith(color: deep),
                        ),
                        Text('/ 10', style: AppTypography.labelSmall),
                      ],
                    ),
                  ],
                ),

                if (primaryDrivers.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Key Signals', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: primaryDrivers.take(4).map((d) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                        child: Text(
                          d,
                          style: AppTypography.labelSmall.copyWith(color: deep),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                if (screeningNote.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    screeningNote,
                    style: AppTypography.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (onViewMore != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  MindCarePillButton(
                    label: 'View Full Analysis',
                    onPressed: onViewMore,
                    variant: PillButtonVariant.ghost,
                    color: deep,
                    compact: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
