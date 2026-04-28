import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';

class MindCareNavItem {
  final String label;
  final PhosphorIconData icon;
  final String semanticLabel;

  const MindCareNavItem({
    required this.label,
    required this.icon,
    required this.semanticLabel,
  });
}

class MindCareBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<MindCareNavItem> items;
  final ValueChanged<int> onTap;
  final String role;

  const MindCareBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.role = 'patient',
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.roleDeep(role);
    final activeBg = AppColors.rolePrimary(role);

    return Semantics(
      label: 'Navigation',
      child: Container(
        margin: EdgeInsets.fromLTRB(
          AppSpacing.base,
          0,
          AppSpacing.base,
          MediaQuery.of(context).padding.bottom + AppSpacing.sm,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.cloud,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: activeBg.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final active = i == currentIndex;

            return Semantics(
              label: '${item.semanticLabel}${active ? ', selected' : ''}',
              button: true,
              selected: active,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? activeBg.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        item.icon,
                        size: 22,
                        color: active ? activeColor : AppColors.slate,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: active
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.xs,
                                ),
                                child: Text(
                                  item.label,
                                  style: AppTypography.label.copyWith(
                                    color: activeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
