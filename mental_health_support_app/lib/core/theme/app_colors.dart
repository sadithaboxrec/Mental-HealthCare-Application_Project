import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand — Patient
  static const Color lavender = Color(0xFFC9B8F5);
  static const Color lavenderDeep = Color(0xFF9B7FE8);
  static const Color lavenderMist = Color(0xFFF0EBFF);
  static const Color lavenderGlow = Color(0xFFE8DFFF);

  // Brand — Doctor
  static const Color sky = Color(0xFFB8D8F0);
  static const Color skyDeep = Color(0xFF5BA3CC);
  static const Color skyMist = Color(0xFFEBF5FF);
  static const Color skyGlow = Color(0xFFD9EEFF);

  // Brand — Guardian
  static const Color mint = Color(0xFFA8E6CF);
  static const Color mintDeep = Color(0xFF4CB88A);
  static const Color mintMist = Color(0xFFEBFAF3);
  static const Color mintGlow = Color(0xFFD4F4E5);

  // Brand — Counselor
  static const Color amber = Color(0xFFFFD9A0);
  static const Color amberDeep = Color(0xFFE8A84C);
  static const Color amberMist = Color(0xFFFFF8EB);
  static const Color amberGlow = Color(0xFFFFEDD4);

  // Severity
  static const Color stable = Color(0xFFA8E6CF);
  static const Color stableDeep = Color(0xFF4CB88A);
  static const Color watch = Color(0xFFFFD9A0);
  static const Color watchDeep = Color(0xFFE8A84C);
  static const Color warning = Color(0xFFFFB8A0);
  static const Color warningDeep = Color(0xFFE8764C);
  static const Color critical = Color(0xFFFFB8C8);
  static const Color criticalDeep = Color(0xFFE8475F);

  // Neutrals
  static const Color ink = Color(0xFF1A1040);
  static const Color inkLight = Color(0xFF3D2F6B);
  static const Color slate = Color(0xFF6B5B95);
  static const Color mist = Color(0xFFF7F5FF);
  static const Color fog = Color(0xFFEEEAFF);
  static const Color cloud = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE8E2FF);

  // Mood (5-point)
  static const Color mood1 = Color(0xFFFFB8C8); // Awful
  static const Color mood2 = Color(0xFFFFD9A0); // Low
  static const Color mood3 = Color(0xFFC9B8F5); // Neutral
  static const Color mood4 = Color(0xFFA8E6CF); // Good
  static const Color mood5 = Color(0xFFB8D8F0); // Great

  static Color moodColor(int level) {
    switch (level) {
      case 1:
        return mood1;
      case 2:
        return mood2;
      case 3:
        return mood3;
      case 4:
        return mood4;
      case 5:
        return mood5;
      default:
        return mood3;
    }
  }

  static Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return critical;
      case 'warning':
        return warning;
      case 'watch':
        return watch;
      default:
        return stable;
    }
  }

  static Color severityDeepColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return criticalDeep;
      case 'warning':
        return warningDeep;
      case 'watch':
        return watchDeep;
      default:
        return stableDeep;
    }
  }

  static List<Color> roleGradient(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return [sky, mint];
      case 'guardian':
        return [mint, amber];
      case 'counselor':
        return [amber, lavender];
      default:
        return [lavender, sky]; // patient
    }
  }

  static Color rolePrimary(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return sky;
      case 'guardian':
        return mint;
      case 'counselor':
        return amber;
      default:
        return lavender;
    }
  }

  static Color roleDeep(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return skyDeep;
      case 'guardian':
        return mintDeep;
      case 'counselor':
        return amberDeep;
      default:
        return lavenderDeep;
    }
  }

  static Color roleMist(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return skyMist;
      case 'guardian':
        return mintMist;
      case 'counselor':
        return amberMist;
      default:
        return lavenderMist;
    }
  }
}
