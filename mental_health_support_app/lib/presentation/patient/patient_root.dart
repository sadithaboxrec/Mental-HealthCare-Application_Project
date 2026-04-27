import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';

class PatientRoot extends StatelessWidget {
  final Widget child;
  const PatientRoot({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: child,
      bottomNavigationBar: _MindCareBottomNav(
        currentIndex: currentIndex,
        onTap: (i) {
          HapticFeedback.selectionClick();
          context.go(_pathForIndex(i));
        },
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/patient/journal')) return 1;
    if (location.startsWith('/patient/care')) return 2;
    if (location.startsWith('/patient/profile')) return 3;
    return 0;
  }

  String _pathForIndex(int i) {
    switch (i) {
      case 1:
        return '/patient/journal';
      case 2:
        return '/patient/care';
      case 3:
        return '/patient/profile';
      default:
        return '/patient/home';
    }
  }
}

class _MindCareBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MindCareBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(
      icon: PhosphorIconsRegular.house,
      activeIcon: PhosphorIconsFill.house,
      label: 'Home',
    ),
    _NavItem(
      icon: PhosphorIconsRegular.notebook,
      activeIcon: PhosphorIconsFill.notebook,
      label: 'Journal',
    ),
    _NavItem(
      icon: PhosphorIconsRegular.heartbeat,
      activeIcon: PhosphorIconsFill.heartbeat,
      label: 'Care',
    ),
    _NavItem(
      icon: PhosphorIconsRegular.user,
      activeIcon: PhosphorIconsFill.user,
      label: 'You',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.sm,
          AppSpacing.base,
          AppSpacing.md,
        ),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.cloud,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: [
              BoxShadow(
                color: AppColors.lavenderDeep.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: Semantics(
                  label: item.label,
                  button: true,
                  selected: selected,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.lavenderMist
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                            ),
                            child: PhosphorIcon(
                              selected ? item.activeIcon : item.icon,
                              size: AppSpacing.iconLg,
                              color: selected
                                  ? AppColors.lavenderDeep
                                  : AppColors.slate,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: AppTypography.labelSmall.copyWith(
                              color: selected
                                  ? AppColors.lavenderDeep
                                  : AppColors.slate,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final PhosphorIconData icon;
  final PhosphorIconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
