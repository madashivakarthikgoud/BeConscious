import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Spacing Tokens ──
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // ── Base Palette ──
  static const Color backgroundDark = Color(0xFF0A140F);
  static const Color backgroundDark2 = Color(0xFF12241A);
  static const Color surfaceDark = Color(0xFF0F1D14);
  static const Color cardDark = Color(0xFF152A1C);

  // ── Accent Tokens ──
  static const Color accent1 = Color(0xFFD4FF50); // Lime green
  static const Color accent2 = Color(0xFFC599FF); // Lavender
  static const Color primaryColor = accent1;
  static const Color secondaryColor = accent2;

  // ── Semantic Colors ──
  static const Color incomeColor = Color(0xFF4ADE80);
  static const Color expenseColor = Color(0xFFFF6B6B);
  static const Color loanTakenColor = Color(0xFFFFB347);
  static const Color loanGivenColor = Color(0xFF60A5FA);
  static const Color savingsColor = Color(0xFFC599FF);

  // ── Glass Tokens ──
  static const double glassBlur = 24.0;
  static const double glassOpacity = 0.08;
  static const double glassBorderOpacity = 0.12;
  static const double cornerRadius = 28.0;
  static const double cornerRadiusSmall = 20.0;

  // ── Text Colors ──
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8BA898);
  static const Color textMuted = Color(0xFF5A7A66);

  // ── Semantic TextStyles ──
  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textSecondary,
      );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textMuted,
      );

  static TextStyle get amountLarge => GoogleFonts.plusJakartaSans(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      );

  static TextStyle get amountMedium => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      );

  // ── Edge Insets Helpers ──
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets cardPadding = EdgeInsets.all(20);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(16);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: accent1,
        secondary: accent2,
        surface: surfaceDark,
        error: expenseColor,
        onPrimary: Color(0xFF0A140F),
        onSecondary: Colors.white,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      cardTheme: CardTheme(
        color: Colors.white.withOpacity(glassOpacity),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          side: BorderSide(color: Colors.white.withOpacity(glassBorderOpacity)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadiusSmall),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadiusSmall),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadiusSmall),
          borderSide: const BorderSide(color: accent1, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent1,
          foregroundColor: backgroundDark,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadiusSmall),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent1,
          side: BorderSide(color: accent1.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadiusSmall),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent1,
        foregroundColor: backgroundDark,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: accent1,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withOpacity(0.06),
        selectedColor: accent1.withOpacity(0.2),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadiusSmall),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF152A1C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          side: BorderSide(color: Colors.white.withOpacity(glassBorderOpacity)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A3324),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.06),
        thickness: 1,
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;
}
