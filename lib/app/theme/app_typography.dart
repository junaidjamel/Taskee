import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A centralized typography system using Google Fonts — Poppins.

abstract final class AppTypography {
  AppTypography._();

  // ─── Base ────────────────────────────────────────────────────────────────

  static TextStyle _poppins({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.poppins(
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height ?? 1.4,
    letterSpacing: letterSpacing,
  );

  // ─── Display ─────────────────────────────────────────────────────────────

  static final TextStyle displayLg = _poppins(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
  );

  /// 32px · Bold — Section titles
  static final TextStyle displayMd = _poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  // ─── Headings ─────────────────────────────────────────────────────────────

  /// 28px · Bold
  static final TextStyle h1 = _poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  /// 24px · SemiBold
  static final TextStyle h2 = _poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle h3 = _poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle h4 = _poppins(
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  // ─── Body ─────────────────────────────────────────────────────────────────

  static final TextStyle bodyLg = _poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// 14px · Regular — Secondary body text
  static final TextStyle bodyMd = _poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static final TextStyle bodySm = _poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ─── Labels / UI ──────────────────────────────────────────────────────────

  /// 14px · SemiBold — Buttons, tabs, nav
  static final TextStyle labelLg = _poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// 12px · Medium — Chips, badges, tags
  static final TextStyle labelMd = _poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  static final TextStyle labelSm = _poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  // ─── Caption ──────────────────────────────────────────────────────────────

  static final TextStyle caption = _poppins(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
  );

  // ─── Theme Helper ─────────────────────────────────────────────────────────

  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLg,
    displayMedium: displayMd,
    headlineLarge: h1,
    headlineMedium: h2,
    headlineSmall: h3,
    titleLarge: h4,
    bodyLarge: bodyLg,
    bodyMedium: bodyMd,
    bodySmall: bodySm,
    labelLarge: labelLg,
    labelMedium: labelMd,
    labelSmall: labelSm,
  );
}
