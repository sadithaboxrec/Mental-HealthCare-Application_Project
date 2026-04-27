import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';

class SeverityUtils {
  SeverityUtils._();

  static Color surfaceColor(String severity) =>
      AppColors.severityColor(severity);
  static Color deepColor(String severity) =>
      AppColors.severityDeepColor(severity);

  static Color surfaceColorMuted(String severity) =>
      AppColors.severityColor(severity).withValues(alpha: 0.15);

  static String label(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 'Critical';
      case 'warning':
        return 'Needs Review';
      case 'watch':
        return 'Watch';
      default:
        return 'Stable';
    }
  }

  static String clinicalAction(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 'Urgent assessment required';
      case 'warning':
        return 'Same-day review recommended';
      case 'watch':
        return 'Monitor closely';
      default:
        return 'Continue routine care';
    }
  }

  static PhosphorIconData icon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return PhosphorIcons.warning(PhosphorIconsStyle.fill);
      case 'warning':
        return PhosphorIcons.warningCircle(PhosphorIconsStyle.fill);
      case 'watch':
        return PhosphorIcons.eye(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
    }
  }

  static int rank(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 3;
      case 'warning':
        return 2;
      case 'watch':
        return 1;
      default:
        return 0;
    }
  }
}
