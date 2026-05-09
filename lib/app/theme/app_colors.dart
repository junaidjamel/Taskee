// import 'package:flutter/material.dart';

// class AppColors {
//   static Color kScaffold = Color(0xfff9f6f1);
//   static Color kLightGrey = Color.fromARGB(15, 66, 66, 66);

//   static Color kBlack = Color.fromARGB(196, 0, 0, 0);
//   static Color kOrange = Colors.orange;

//   static Color kPureBlack = Colors.black;

//   static Color kWhite = Color.fromARGB(255, 255, 255, 255);
//   static Color kgrey = Colors.grey;
//   static Color kPrimaryGrey = Color.fromARGB(255, 232, 232, 232);
// }

import 'package:flutter/material.dart';

/// Color palette for Taskee — dark notes app.
abstract final class AppColors {
  AppColors._();

  static const Color background = Color(0xFF1A1A18);

  static const Color surface = Color(0xFF242420);

  static const Color surfaceVariant = Color(0xFF2E2E2A);

  // ─── Accent ───────────────────────────────────────────────────────────────

  static const Color accent = Color(0xFFD4E157);

  static const Color accentMuted = Color(0xFF4A4A38);

  static const Color noteCard = Color(0xFFE8ECC8);

  // ─── Text ─────────────────────────────────────────────────────────────────

  static const Color textPrimary = Color(0xFFF0F0EC);

  static const Color textSecondary = Color(0xFFAAADA0);

  static const Color textMuted = Color(0xFF666860);

  static const Color textOnLight = Color(0xFF1A1A18);

  // ─── Semantic ─────────────────────────────────────────────────────────────

  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFB74D);
}
