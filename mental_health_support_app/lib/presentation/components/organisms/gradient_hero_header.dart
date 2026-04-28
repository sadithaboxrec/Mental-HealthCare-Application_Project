import 'package:flutter/material.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/utils/app_date_utils.dart';

class GradientHeroHeader extends StatelessWidget {
  final String name;
  final String role;
  final Widget? trailing;
  final Widget? bottom;

  const GradientHeroHeader({
    super.key,
    required this.name,
    required this.role,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = AppColors.roleGradient(role);
    final greeting = AppDateUtils.greetingTime();
    final dateStr = AppDateUtils.formatDate(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        MediaQuery.of(context).padding.top + AppSpacing.base,
        AppSpacing.base,
        bottom != null ? AppSpacing.sm : AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: AppTypography.body.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: AppTypography.headline2.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      dateStr,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: AppSpacing.base),
            bottom!,
          ],
        ],
      ),
    );
  }
}
