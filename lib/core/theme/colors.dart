import 'package:flutter/material.dart';

/// Scorely Design Token System — single source of truth for all colors.
///
/// Light palette  →  Home, Teams, Profile, Settings screens.
/// Dark palette   →  Scoring, Scorecard, Results, Discovery screens.
class AppColors {
  AppColors._();

  // ─── Brand ────────────────────────────────────────────────────────────────
  static const Color primary     = Color(0xFFBA0013); // Scorely Crimson Red
  static const Color primaryDark = Color(0xFF8B000E); // pressed / deeper
  static const Color primaryGlow = Color(0xFFE5001A); // hover / highlight

  // ─── Accent ───────────────────────────────────────────────────────────────
  /// Victory / success green — scoring highs (4s, 6s, wins)
  static const Color success     = Color(0xFF00E676);
  static const Color successDark = Color(0xFF006B1B);

  /// Extras / warning amber — wides & no-balls
  static const Color warning     = Color(0xFFCA8A04);

  // ─── Light Surface Palette (Home · Teams · Profile) ───────────────────────
  static const Color lightBg             = Color(0xFFF7F9FC);
  static const Color lightSurface        = Color(0xFFFFFFFF);
  static const Color lightSurface2       = Color(0xFFF0F2F8);
  static const Color lightBorder         = Color(0xFFDDE0E8);
  static const Color lightTextPrimary    = Color(0xFF191C1E);
  static const Color lightTextSecondary  = Color(0xFF575D78);
  static const Color lightTextMuted      = Color(0xFF8E95A5);
  static const Color lightAccentBg       = Color(0xFFFDE8E8);

  // ─── Dark Surface Palette (Scoring · Scoreboard · Results) ────────────────
  static const Color darkBg             = Color(0xFF0B0F19);
  static const Color darkNavBg          = Color(0xFF131824);
  static const Color darkCard           = Color(0xFF1E293B);
  static const Color darkCard2          = Color(0xFF202A46);
  static const Color darkBorder         = Color(0x0DFFFFFF); // white 5%
  static const Color darkTextPrimary    = Color(0xFFFFFFFF);
  static const Color darkTextSecondary  = Color(0xFF94A3B8);
  static const Color darkTextMuted      = Color(0xFF64748B);

  // ─── Shared Semantic ──────────────────────────────────────────────────────
  static const Color onPrimary  = Color(0xFFFFFFFF);
  static const Color error      = primary;

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient redGradient = LinearGradient(
    colors: [primary, Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkHeaderGradient = LinearGradient(
    colors: [darkNavBg, darkBg],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Legacy aliases (backward-compat) ─────────────────────────────────────
  static const Color background  = lightBg;
  static const Color surface     = lightSurface;
  static const Color darkSurface = Color(0xFF1A2138);
  static const Color secondary   = lightTextSecondary;
  static const Color tertiary    = successDark;
  static const Color onBackground = lightTextPrimary;
  static const Color onSurface   = lightTextPrimary;
  static const Color glassSurface = Color(0x1A1A2138);
}
