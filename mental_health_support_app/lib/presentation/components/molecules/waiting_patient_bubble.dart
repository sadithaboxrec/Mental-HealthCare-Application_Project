import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/core/utils/app_date_utils.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_pill_button.dart';

class WaitingPatientBubble extends StatefulWidget {
  final String patientName;
  final DateTime waitingSince;
  final VoidCallback onAccept;
  final VoidCallback? onDecline;

  const WaitingPatientBubble({
    super.key,
    required this.patientName,
    required this.waitingSince,
    required this.onAccept,
    this.onDecline,
  });

  @override
  State<WaitingPatientBubble> createState() => _WaitingPatientBubbleState();
}

class _WaitingPatientBubbleState extends State<WaitingPatientBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final waitStr = AppDateUtils.waitTime(widget.waitingSince);

    return Semantics(
      label:
          '${widget.patientName} is waiting, wait time $waitStr. Accept or decline.',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.cloud,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.amberDeep.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Pulsing indicator
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (ctx, child) => Transform.scale(
                scale: reduceMotion ? 1.0 : _pulseAnim.value,
                child: child,
              ),
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.amberDeep,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Patient info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.patientName, style: AppTypography.title),
                  const SizedBox(height: 2),
                  // Wait time chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amberMist,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.timer(PhosphorIconsStyle.fill),
                          size: 11,
                          color: AppColors.amberDeep,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          waitStr,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.amberDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Actions
            Column(
              children: [
                MindCarePillButton(
                  label: 'Accept',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onAccept();
                  },
                  variant: PillButtonVariant.filled,
                  color: AppColors.amberDeep,
                  compact: true,
                ),
                if (widget.onDecline != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  MindCarePillButton(
                    label: 'Decline',
                    onPressed: widget.onDecline,
                    variant: PillButtonVariant.ghost,
                    color: AppColors.criticalDeep,
                    compact: true,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
