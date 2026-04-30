import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mental_health_support_app/core/theme/app_colors.dart';

class MindCareAsset extends StatelessWidget {
  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final Color fallbackColor;

  const MindCareAsset({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallbackIcon = PhosphorIconsDuotone.heartbeat,
    this.fallbackColor = AppColors.lavenderDeep,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) {
        return SizedBox(
          width: width,
          height: height,
          child: Center(
            child: PhosphorIcon(
              fallbackIcon,
              size: (width ?? height ?? 48) * 0.5,
              color: fallbackColor,
            ),
          ),
        );
      },
    );
  }
}
