import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';

class DoctorRoot extends ConsumerStatefulWidget {
  final Widget child;
  const DoctorRoot({super.key, required this.child});

  @override
  ConsumerState<DoctorRoot> createState() => _DoctorRootState();
}

class _DoctorRootState extends ConsumerState<DoctorRoot> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabItem(label: 'Dashboard', path: '/doctor/dashboard'),
    _TabItem(label: 'Patients', path: '/doctor/patients'),
    _TabItem(label: 'Schedule', path: '/doctor/schedule'),
    _TabItem(label: 'Reports', path: '/doctor/reports'),
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_tabs[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: widget.child,
      bottomNavigationBar: _DoctorBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _DoctorBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DoctorBottomNav({required this.currentIndex, required this.onTap});

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
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.cloud,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppColors.skyDeep.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                PhosphorIcons.chartPieSlice(PhosphorIconsStyle.duotone),
                'Dashboard',
              ),
              _buildNavItem(
                1,
                PhosphorIcons.users(PhosphorIconsStyle.duotone),
                'Patients',
              ),
              _buildNavItem(
                2,
                PhosphorIcons.calendarCheck(PhosphorIconsStyle.duotone),
                'Schedule',
              ),
              _buildNavItem(
                3,
                PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
                'Reports',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = index == currentIndex;
    return Expanded(
      child: Semantics(
        label: label,
        selected: isSelected,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(index),
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
                    color: isSelected ? AppColors.skyMist : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Icon(
                    icon,
                    size: AppSpacing.iconLg,
                    color: isSelected ? AppColors.skyDeep : AppColors.slate,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isSelected ? AppColors.skyDeep : AppColors.slate,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final String path;
  const _TabItem({required this.label, required this.path});
}
