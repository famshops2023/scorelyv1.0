import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.barlowCondensed(
        fontSize: 64,
        fontWeight: FontWeight.w800,
        color: AppColors.onBackground,
        height: 1.0,
      );

  static TextStyle get headlineLarge => GoogleFonts.barlowCondensed(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.onBackground,
        height: 1.2,
      );

  static TextStyle get headlineMedium => GoogleFonts.barlowCondensed(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.onBackground,
        height: 1.2,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.onBackground,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onBackground,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onBackground,
        height: 1.5,
      );

  static TextStyle get labelCaps => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 1.2,
      );

  static TextStyle get scoreDisplay => GoogleFonts.barlowCondensed(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        height: 1.0,
      );
}
