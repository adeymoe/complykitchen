import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for ComplyKitchen.
///
/// Colour is not decorative here: safe / warn / danger map directly to
/// whether a temperature reading is within its legal limit. Keep these
/// three semantic colours reserved for that purpose only.
class AppColors {
  static const paper = Color(0xFFE9E6DF);
  static const screen = Color(0xFFFBFAF6);
  static const ink = Color(0xFF15150F);
  static const inkSoft = Color(0xFF6C6B60);
  static const inkMute = Color(0xFF9A988C);
  static const line = Color(0xFFE7E4DA);
  static const card = Color(0xFFFFFFFF);

  static const safe = Color(0xFF1D7A4C);
  static const safeBg = Color(0xFFE2F2EA);
  static const warn = Color(0xFFA9670F);
  static const warnBg = Color(0xFFF9ECD8);
  static const danger = Color(0xFFB3261E);
  static const dangerBg = Color(0xFFFBE7E5);
}

/// The three states a logged reading (or task) can be in.
enum ComplianceStatus { safe, warn, danger }

extension ComplianceStatusColors on ComplianceStatus {
  Color get fg {
    switch (this) {
      case ComplianceStatus.safe:
        return AppColors.safe;
      case ComplianceStatus.warn:
        return AppColors.warn;
      case ComplianceStatus.danger:
        return AppColors.danger;
    }
  }

  Color get bg {
    switch (this) {
      case ComplianceStatus.safe:
        return AppColors.safeBg;
      case ComplianceStatus.warn:
        return AppColors.warnBg;
      case ComplianceStatus.danger:
        return AppColors.dangerBg;
    }
  }
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.screen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ink,
        brightness: Brightness.light,
      ),
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: AppColors.ink,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.inkSoft,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 11.5,
        color: AppColors.inkMute,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.screen,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  /// Readings and timestamps use a monospace face so digits align and read
  /// like an instrument, not body copy.
  static TextStyle mono({double size = 14, FontWeight weight = FontWeight.w600, Color? color}) {
    return GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, color: color ?? AppColors.ink);
  }
}
