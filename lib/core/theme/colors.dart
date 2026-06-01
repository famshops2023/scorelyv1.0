import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF131313);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color primary = Color(0xFFCCFF00); // Neon Green
  static const Color secondary = Color(0xFFC8C6C5);
  static const Color tertiary = Color(0xFF62FAE3); // Teal
  
  static const Color onBackground = Color(0xFFE5E2E1);
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onPrimary = Color(0xFF283500);
  
  static const Color error = Color(0xFFFFB4AB);
  static const Color glassSurface = Color(0x1AFFFFFF);
  
  static const LinearGradient neonGradient = LinearGradient(
    colors: [primary, Color(0xFF99FF00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
