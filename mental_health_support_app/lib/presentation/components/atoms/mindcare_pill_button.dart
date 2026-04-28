import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';

enum PillButtonVariant { filled, outlined, ghost, destructive }

class MindCarePillButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final bool isLoading;
  final PhosphorIconData? icon;
  final Color? color;
  final String? semanticLabel;
  final bool compact;
  final bool hero;
  final double? width;

  const MindCarePillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PillButtonVariant.filled,
    this.isLoading = false,
    this.icon,
    this.color,
    this.semanticLabel,
    this.compact = false,
    this.hero = false,
    this.width,
  });

  @override
  State<MindCarePillButton> createState() => _MindCarePillButtonState();
}

class _MindCarePillButtonState extends State<MindCarePillButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Color get _primaryColor => widget.variant == PillButtonVariant.destructive
      ? AppColors.criticalDeep
      : (widget.color ?? AppColors.lavender);

  double get _height => widget.hero
      ? AppSpacing.buttonHeightHero
      : widget.compact
      ? AppSpacing.buttonHeightSm
      : AppSpacing.buttonHeight;

  bool get _isDisabled => widget.onPressed == null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      button: true,
      enabled: !_isDisabled,
      child: GestureDetector(
        onTapDown: (_) {
          if (!reduceMotion) _pressCtrl.forward();
        },
        onTapUp: (_) {
          if (!reduceMotion) _pressCtrl.reverse();
        },
        onTapCancel: () {
          if (!reduceMotion) _pressCtrl.reverse();
        },
        onTap: widget.onPressed == null || widget.isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              },
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) => Transform.scale(
            scale: reduceMotion ? 1.0 : _scaleAnim.value,
            child: child,
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isDisabled ? 0.4 : 1.0,
            child: _buildButton(),
          ),
        ),
      ),
    );
  }

  Widget _buildButton() {
    final isOutlined = widget.variant == PillButtonVariant.outlined;
    final isGhost = widget.variant == PillButtonVariant.ghost;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation(
                isOutlined || isGhost ? _primaryColor : AppColors.cloud,
              ),
              strokeWidth: 2,
            ),
          ),
        ] else ...[
          if (widget.icon != null) ...[
            PhosphorIcon(
              widget.icon!,
              size: 18,
              color: isOutlined || isGhost ? _primaryColor : AppColors.cloud,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            widget.label,
            style: AppTypography.title.copyWith(
              color: isOutlined || isGhost ? _primaryColor : AppColors.cloud,
              fontSize: widget.compact ? 13 : null,
            ),
          ),
        ],
      ],
    );

    if (isOutlined) {
      return Container(
        height: _height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: _primaryColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: content,
        ),
      );
    }

    if (isGhost) {
      return Container(
        height: _height,
        width: widget.width,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: content,
        ),
      );
    }

    // filled or destructive
    return Container(
      height: _height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        gradient: LinearGradient(
          colors: [_primaryColor, _primaryColor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: content,
      ),
    );
  }
}
