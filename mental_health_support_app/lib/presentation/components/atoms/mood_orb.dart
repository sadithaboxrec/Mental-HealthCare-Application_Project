import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';

class MoodOrb extends StatefulWidget {
  final int level; // 1–5
  final double size;
  final bool selected;
  final bool showLabel;
  final VoidCallback? onTap;

  const MoodOrb({
    super.key,
    required this.level,
    this.size = 56,
    this.selected = false,
    this.showLabel = false,
    this.onTap,
  });

  @override
  State<MoodOrb> createState() => _MoodOrbState();
}

class _MoodOrbState extends State<MoodOrb> with SingleTickerProviderStateMixin {
  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;

  static const _labels = ['Awful', 'Low', 'Neutral', 'Good', 'Great'];
  static const _emojis = ['😞', '😕', '😐', '🙂', '😄'];

  List<Color> get _gradientColors {
    final base = AppColors.moodColor(widget.level);
    return [base.withValues(alpha: 0.9), base];
  }

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _breathAnim = Tween(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut));
    _breathCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  String get _label => _labels[(widget.level.clamp(1, 5)) - 1];
  String get _emoji => _emojis[(widget.level.clamp(1, 5)) - 1];

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final color = AppColors.moodColor(widget.level);

    return Semantics(
      label: 'Mood: $_label (level ${widget.level} of 5)',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _breathAnim,
              builder: (ctx, child) => Transform.scale(
                scale: reduceMotion ? 1.0 : _breathAnim.value,
                child: child,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _gradientColors,
                    center: Alignment.topLeft,
                    radius: 1.2,
                  ),
                  border: widget.selected
                      ? Border.all(color: color, width: 2.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(
                        alpha: widget.selected ? 0.5 : 0.2,
                      ),
                      blurRadius: widget.selected ? 16 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _emoji,
                  style: TextStyle(fontSize: widget.size * 0.48),
                ),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(_label, style: AppTypography.labelSmall),
            ],
          ],
        ),
      ),
    );
  }
}
