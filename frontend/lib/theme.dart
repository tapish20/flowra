import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Global theme notifier — listened to by MyApp in main.dart
// ─────────────────────────────────────────────────────────────────────────────
enum FlowraTheme { light, dark, lavender }

class ThemeNotifier extends ValueNotifier<FlowraTheme> {
  ThemeNotifier() : super(FlowraTheme.light);
}

// Singleton instance accessible app-wide without provider
final themeNotifier = ThemeNotifier();

class AppTheme {
  static const Color primary = Color(0xFFEA4C89); // pink
  static const Color accent = Color(0xFF6C5CE7); // purple
  static const Color bg = Color(0xFFFCF9FA);

  // Gradient definitions for visual elements
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFEA4C89), Color(0xFFF06292)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF8E2DE2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundMesh = LinearGradient(
    colors: [Color(0xFFFFF0F5), Color(0xFFF3E5F5), Color(0xFFFDFBFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData lightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF6A1B4D),
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFFEA4C89)),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF2D3748)),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2D3748)),
        bodyMedium: const TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
        labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 2,
          shadowColor: primary.withValues(alpha: 0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFFEA4C89).withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        labelStyle: TextStyle(color: Colors.grey.shade500),
      ),
    );
  }

  // ── Dark Theme ──────────────────────────────────────────────────────────────
  static ThemeData darkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
        surface: const Color(0xFF1E1E2E),
      ),
      cardColor: const Color(0xFF1E1E2E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFFFB3D0),
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFFEA4C89)),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFFECEFF4)),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFECEFF4)),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFECEFF4)),
        bodyMedium: const TextStyle(fontSize: 14, color: Color(0xFFB2BFCC)),
        labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A3E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3A3A50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        labelStyle: const TextStyle(color: Color(0xFF8899AA)),
      ),
    );
  }

  // ── Lavender Night Theme ────────────────────────────────────────────────────
  static ThemeData lavenderTheme() {
    final base = ThemeData.dark();
    const lavPrimary = Color(0xFFCB9FE5);
    const lavBg = Color(0xFF1A1428);
    const lavSurface = Color(0xFF261E3A);
    return base.copyWith(
      primaryColor: lavPrimary,
      scaffoldBackgroundColor: lavBg,
      colorScheme: base.colorScheme.copyWith(
        primary: lavPrimary,
        secondary: const Color(0xFFA78BFA),
        surface: lavSurface,
      ),
      cardColor: lavSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFE0D4F7),
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: lavPrimary),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFFE8DEFF)),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFE8DEFF)),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE8DEFF)),
        bodyMedium: const TextStyle(fontSize: 14, color: Color(0xFFB8A9D4)),
        labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lavPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2E2448),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4A3A6A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lavPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        labelStyle: const TextStyle(color: Color(0xFF9980C4)),
      ),
    );
  }

  static ThemeData forMode(FlowraTheme mode) {
    switch (mode) {
      case FlowraTheme.dark:
        return darkTheme();
      case FlowraTheme.lavender:
        return lavenderTheme();
      case FlowraTheme.light:
        return lightTheme();
    }
  }
}

