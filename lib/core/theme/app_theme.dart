import 'package:flutter/material.dart';

/// App Theme Configuration — light & dark variants.
class AppTheme {
  AppTheme._();

  // ── Dark Theme ─────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const bg = Color(0xFF0D0D0D);
    const surface = Color(0xFF1A1A1A);
    const border = Color(0xFF2A2A2A);
    const accent = Color(0xFFE53935);
    const textPrimary = Color(0xFFFFFFFF);
    const textSecondary = Color(0xFF9E9E9E);
    const radius = 16.0;

    return _buildTheme(
      brightness: Brightness.dark,
      bg: bg,
      surface: surface,
      border: border,
      accent: accent,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      radius: radius,
    );
  }

  // ── Light Theme ────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const bg = Color(0xFFF5F5F5);
    const surface = Color(0xFFFFFFFF);
    const border = Color(0xFFE0E0E0);
    const accent = Color(0xFFE53935);
    const textPrimary = Color(0xFF1A1A1A);
    const textSecondary = Color(0xFF757575);
    const radius = 16.0;

    return _buildTheme(
      brightness: Brightness.light,
      bg: bg,
      surface: surface,
      border: border,
      accent: accent,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      radius: radius,
    );
  }

  // ── Shared builder ─────────────────────────────────────────────────────
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color border,
    required Color accent,
    required Color textPrimary,
    required Color textSecondary,
    required double radius,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: isDark ? textPrimary : Colors.white,
        secondary: accent,
        onSecondary: isDark ? textPrimary : Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: accent,
        onError: Colors.white,
        outline: border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent),
        ),
        labelStyle: TextStyle(color: textSecondary, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border),
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: textSecondary),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
    );
  }
}
