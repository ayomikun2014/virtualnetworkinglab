import 'package:flutter/material.dart';

/// Cyber-Networking Modern Dark Theme System for VirtuaNetLab
class AppTheme {
  AppTheme._();

  // Primary Cyber Color Palette
  static const Color backgroundMidnight = Color(0xFF0D1117);
  static const Color surfaceGlass = Color(0xFF161B22);
  static const Color primaryCyan = Color(0xFF00F2FE);
  static const Color primaryBlue = Color(0xFF4FACFE);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentCrimson = Color(0xFFEF4444);
  static const Color textBright = Color(0xFFF0F6FC);
  static const Color textMuted = Color(0xFF8B949E);
  static const Color borderSubtle = Color(0xFF30363D);

  /// Modern Dark Cyber Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundMidnight,
      primaryColor: primaryCyan,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: primaryBlue,
        surface: surfaceGlass,
        error: accentCrimson,
        onPrimary: backgroundMidnight,
        onSurface: textBright,
      ),

      // Card Glassmorphism Styling
      cardTheme: CardThemeData(
        color: surfaceGlass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),

      // Input Form Fields Styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGlass,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentCrimson),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
      ),

      // Elevated Buttons Styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: backgroundMidnight,
          backgroundColor: primaryCyan,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // AppBar Styling
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundMidnight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textBright,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textBright),
      ),

      // Typography
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textBright,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textBright,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: textBright,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textBright,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: textBright, fontSize: 16),
        bodyMedium: TextStyle(color: textMuted, fontSize: 14),
      ),
    );
  }
}
