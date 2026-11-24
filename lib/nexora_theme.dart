import 'package:flutter/material.dart';

/// Nexora black + gold palette. Every screen should use these instead of
/// hard-coded hex values so the whole app stays visually consistent.
class NexoraColors {
  NexoraColors._();

  // Surfaces
  static const Color bg = Color(0xFF0A0804);
  static const Color bgAlt = Color(0xFF14100A);
  static const Color card = Color(0xFF17130C);
  static const Color border = Color(0xFF3A2F17);

  // Gold accent
  static const Color gold = Color(0xFFE8BA48);
  static const Color goldLight = Color(0xFFF4D67A);
  static const Color goldDark = Color(0xFFC48A0A);

  // Text / icons that sit ON a gold surface (buttons, banners)
  static const Color onGold = Color(0xFF1A1200);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, goldDark],
  );
}

class NexoraTheme {
  NexoraTheme._();

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: NexoraColors.gold,
      brightness: Brightness.dark,
    ).copyWith(
      primary: NexoraColors.gold,
      onPrimary: NexoraColors.onGold,
      secondary: NexoraColors.goldDark,
      surface: NexoraColors.bg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: NexoraColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: NexoraColors.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NexoraColors.gold,
          foregroundColor: NexoraColors.onGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NexoraColors.goldLight,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: NexoraColors.gold,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
