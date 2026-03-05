import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// App Theme Configuration — built from [design_tokens.dart].
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBg,
      colorScheme: const ColorScheme.dark(
        primary: kAccent,
        secondary: kAccent,
        surface: kSurface,
        error: kAccent,
        onPrimary: kTextPrimary,
        onSecondary: kTextPrimary,
        onSurface: kTextPrimary,
        outline: kBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kBg,
        foregroundColor: kTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: kSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
          side: const BorderSide(color: kBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kAccent),
        ),
        labelStyle: const TextStyle(color: kTextSecondary, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: kTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: kTextPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: kAccent),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(kRadius)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
          side: const BorderSide(color: kBorder),
        ),
        titleTextStyle: const TextStyle(
          color: kTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: kTextPrimary),
        displayMedium: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: kTextPrimary),
        displaySmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: kTextPrimary),
        headlineSmall: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: kTextPrimary),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: kTextPrimary),
        titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: kTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: kTextPrimary),
        bodySmall: TextStyle(fontSize: 12, color: kTextSecondary),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: kTextPrimary),
      ),
    );
  }
}
