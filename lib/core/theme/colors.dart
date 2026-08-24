import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFBA0013); // Scorely Crimson Red
  static const Color primaryDark = Color(0xFF8B000E);
  static const Color background = Color(0xFFF7F9FC); // Sleek Light Background
  static const Color surface = Color(0xFFFFFFFF); // Card Surface
  static const Color darkSurface = Color(0xFF1A2138); // Dark Navy Accent
  static const Color secondary = Color(0xFF575D78); // Slate Secondary
  static const Color tertiary = Color(0xFF006B1B); // Victory/Success Green
  
  static const Color onBackground = Color(0xFF191C1E); // Primary Dark Text
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onPrimary = Colors.white;
  
  static const Color error = Color(0xFFBA0013);
  static const Color glassSurface = Color(0x1A1A2138);
  
  static const LinearGradient redGradient = LinearGradient(
    colors: [primary, Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
