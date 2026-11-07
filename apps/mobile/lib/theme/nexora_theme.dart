import 'package:flutter/material.dart';

/// Official NEXORA Design System Theme Tokens
class NexoraColors {
  static const Color midnightNavy = Color(0xFF14243B);
  static const Color electricBlue = Color(0xFF3978F6);
  static const Color signalTeal = Color(0xFF39C6B0);

  // Backgrounds & Surfaces
  static const Color lightBackground = Color(0xFFF5F7FB);
  static const Color lightSurface = Colors.white;
  static const Color darkBackground = Color(0xFF0D1420);
  static const Color darkSurface = Color(0xFF17243A);
  static const Color darkSurfaceVariant = Color(0xFF1F2F4B);

  // Semantic
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF39C6B0);
}

class NexoraTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: NexoraColors.electricBlue,
      primary: NexoraColors.electricBlue,
      secondary: NexoraColors.signalTeal,
      tertiary: NexoraColors.midnightNavy,
      surface: NexoraColors.lightSurface,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NexoraColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: NexoraColors.lightBackground,
        foregroundColor: NexoraColors.midnightNavy,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: NexoraColors.lightSurface,
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: NexoraColors.lightSurface,
        indicatorColor: NexoraColors.electricBlue.withValues(alpha: 0.15),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: NexoraColors.electricBlue,
      primary: NexoraColors.electricBlue,
      secondary: NexoraColors.signalTeal,
      tertiary: NexoraColors.midnightNavy,
      surface: NexoraColors.darkSurface,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NexoraColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: NexoraColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: NexoraColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF223554), width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: NexoraColors.darkSurface,
        indicatorColor: NexoraColors.electricBlue.withValues(alpha: 0.25),
      ),
    );
  }
}
