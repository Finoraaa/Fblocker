import 'package:flutter/material.dart';

class FinoraColors {
  // Deep Blacks
  static const Color background = Color(0xFF090A0E);
  static const Color surface = Color(0xFF111319);
  static const Color card = Color(0xFF171922);
  static const Color cardHover = Color(0xFF1E212D);

  // Grays
  static const Color border = Color(0xFF2B2F3E);
  static const Color borderLight = Color(0xFF3E4357);
  static const Color textMuted = Color(0xFF888E9E);
  static const Color textSecondary = Color(0xFFB4B9C8);

  // Whites
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFF3F5FA);

  // Finora Crimson & Neon Reds
  static const Color red = Color(0xFFFF2A44);
  static const Color redDark = Color(0xFFB8152B);
  static const Color redLight = Color(0xFFFF576E);
  static const Color redGlow = Color(0x66FF2A44);

  // Status Colors
  static const Color green = Color(0xFF00E676);
  static const Color amber = Color(0xFFFFB300);
}

class FinoraTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: FinoraColors.background,
      primaryColor: FinoraColors.red,
      colorScheme: const ColorScheme.dark(
        primary: FinoraColors.red,
        secondary: FinoraColors.redLight,
        surface: FinoraColors.surface,
        onSurface: FinoraColors.textPrimary,
        error: FinoraColors.red,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: FinoraColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: FinoraColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        iconTheme: IconThemeData(color: FinoraColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: FinoraColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: FinoraColors.border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: FinoraColors.border,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return FinoraColors.white;
          }
          return FinoraColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return FinoraColors.red;
          }
          return FinoraColors.cardHover;
        }),
        trackOutlineColor: WidgetStateProperty.all(FinoraColors.border),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FinoraColors.surface,
        hintStyle: const TextStyle(color: FinoraColors.textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FinoraColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FinoraColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FinoraColors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FinoraColors.red,
          foregroundColor: FinoraColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
