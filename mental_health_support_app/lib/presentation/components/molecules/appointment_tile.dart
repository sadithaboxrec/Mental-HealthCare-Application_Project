import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/utils/app_date_utils.dart';

class AppointmentTile extends StatelessWidget {
  final String date;
  final String time;
  final String doctorOrPatientName;
  final String status;
  final VoidCallback? onTap;
  final VoidCallback? onReschedule;

  const AppointmentTile({
    super.key,
    required this.date,
    required this.time,
    required this.doctorOrPatientName,
    required this.status,
    this.onTap,
    this.onReschedule,
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.stableDeep;
      case 'absent':
        return AppColors.criticalDeep;
      case 'rescheduled':
        return AppColors.watchDeep;
      default:
        return AppColors.lavenderDeep;
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? dt;
    try {
      dt = DateTime.parse(date);
    } catch (_) {}

    final capitalizedStatus = status.isNotEmpty
        ? status[0].toUpperCase() + status.substring(1)
        : '';

    return Semantics(
      label:
          'Appointment with $doctorOrPatientName on $date at $time, status: $status',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
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
          child: Row(
            children: [
              // Date badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.lavenderMist,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dt != null ? '${dt.day}' : '--',
                      style: AppTypography.dataSmall.copyWith(
                        color: AppColors.lavenderDeep,
                      ),
                    ),
                    Text(
                      dt != null ? _monthAbbr(dt.month) : '--',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.lavenderDeep,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Name and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctorOrPatientName, style: AppTypography.title),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.clock(PhosphorIconsStyle.regular),
                          size: 12,
                          color: AppColors.slate,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppDateUtils.formatTime(time),
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  capitalizedStatus,
                  style: AppTypography.labelSmall.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthAbbr(int month) {
    const abbrs = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return abbrs[month - 1];
  }
}
