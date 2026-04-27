import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle _jakarta({
    required double size,
    required FontWeight weight,
    Color color = AppColors.ink,
    double height = 1.3,
    double letterSpacing = 0,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    Color color = AppColors.inkLight,
    double height = 1.5,
    double letterSpacing = 0,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle get displayHero => _jakarta(
    size: 42,
    weight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -1.5,
  );
  static TextStyle get headline1 => _jakarta(
    size: 34,
    weight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -1.0,
  );
  static TextStyle get headline2 => _jakarta(
    size: 28,
    weight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );
  static TextStyle get headline3 => _jakarta(
    size: 24,
    weight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );
  static TextStyle get headline4 =>
      _jakarta(size: 20, weight: FontWeight.w600, height: 1.3);
  static TextStyle get title =>
      _jakarta(size: 17, weight: FontWeight.w600, height: 1.4);
  static TextStyle get titleSmall => _jakarta(
    size: 15,
    weight: FontWeight.w500,
    height: 1.4,
    color: AppColors.inkLight,
  );

  static TextStyle get body =>
      _inter(size: 15, weight: FontWeight.w400, height: 1.6);
  static TextStyle get bodySmall => _inter(
    size: 13,
    weight: FontWeight.w400,
    height: 1.5,
    color: AppColors.slate,
  );
  static TextStyle get label => _inter(
    size: 13,
    weight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.3,
    color: AppColors.slate,
  );
  static TextStyle get labelSmall => _inter(
    size: 11,
    weight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
    color: AppColors.slate,
  );
  static TextStyle get caption => _inter(
    size: 11,
    weight: FontWeight.w400,
    height: 1.4,
    color: AppColors.slate,
  );

  static TextStyle get dataLarge =>
      _jakarta(size: 34, weight: FontWeight.w700, height: 1.0);
  static TextStyle get dataMedium =>
      _jakarta(size: 24, weight: FontWeight.w700, height: 1.0);
  static TextStyle get dataSmall =>
      _jakarta(size: 17, weight: FontWeight.w600, height: 1.0);
}
