import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/utils/app_date_utils.dart';

class DiaryEntryCard extends StatelessWidget {
  final String id;
  final String content;
  final DateTime createdAt;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DiaryEntryCard({
    super.key,
    required this.id,
    required this.content,
    required this.createdAt,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final previewLength = content.length.clamp(0, 100);
    final preview = content.substring(0, previewLength);

    return Semantics(
      label:
          'Journal entry from ${AppDateUtils.formatShortDate(createdAt)}: $preview',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cloud,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.lavender.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header bar
                Container(
                  color: AppColors.lavenderMist,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.notebook(PhosphorIconsStyle.duotone),
                        size: 16,
                        color: AppColors.lavenderDeep,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        AppDateUtils.formatShortDate(createdAt),
                        style: AppTypography.label.copyWith(
                          color: AppColors.lavenderDeep,
                        ),
                      ),
                      const Spacer(),
                      if (onEdit != null)
                        _ActionBtn(
                          icon: PhosphorIcons.pencil(
                            PhosphorIconsStyle.regular,
                          ),
                          onTap: onEdit!,
                          label: 'Edit',
                        ),
                      if (onDelete != null)
                        _ActionBtn(
                          icon: PhosphorIcons.trash(PhosphorIconsStyle.regular),
                          onTap: onDelete!,
                          label: 'Delete',
                          color: AppColors.criticalDeep,
                        ),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Text(
                    content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final PhosphorIconData icon;
  final VoidCallback onTap;
  final String label;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.onTap,
    required this.label,
    this.color = AppColors.slate,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: PhosphorIcon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
