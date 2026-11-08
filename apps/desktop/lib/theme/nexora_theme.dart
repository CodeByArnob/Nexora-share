import 'package:flutter/material.dart';

/// Official NEXORA Design System Theme Tokens (Desktop Windows & Linux)
/// Premium, Lightweight, Midnight Navy + Electric Blue + Signal Teal Brand Identity
class NexoraColors {
  // Brand Anchors
  static const Color midnightNavy = Color(0xFF0A0F1D);
  static const Color midnightNavySurface = Color(0xFF111A2E);
  static const Color midnightNavyElevated = Color(0xFF18233C);
  static const Color midnightNavyBorder = Color(0xFF1F2E4D);

  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color electricBlueLight = Color(0xFF60A5FA);
  static const Color electricBlueDark = Color(0xFF1D4ED8);

  static const Color signalTeal = Color(0xFF00E5FF);
  static const Color signalTealMuted = Color(0xFF06B6D4);
  static const Color signalTealDark = Color(0xFF0E7490);

  // Backgrounds & Surfaces (Light Theme)
  static const Color lightBackground = Color(0xFFF6F8FC);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Backgrounds & Surfaces (Dark Theme)
  static const Color darkBackground = midnightNavy;
  static const Color darkSurface = midnightNavySurface;
  static const Color darkSurfaceVariant = midnightNavyElevated;
  static const Color darkCard = midnightNavyElevated;
  static const Color darkBorder = midnightNavyBorder;

  // Semantic
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [electricBlue, signalTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0x333B82F6), Color(0x3300E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class NexoraTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: NexoraColors.electricBlue,
      primary: NexoraColors.electricBlue,
      onPrimary: Colors.white,
      secondary: NexoraColors.signalTealMuted,
      onSecondary: Colors.white,
      tertiary: NexoraColors.midnightNavy,
      surface: NexoraColors.lightSurface,
      onSurface: const Color(0xFF0F172A),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NexoraColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: NexoraColors.lightBackground,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: NexoraColors.lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: NexoraColors.lightBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NexoraColors.electricBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NexoraColors.electricBlue,
          side: const BorderSide(color: NexoraColors.electricBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: NexoraColors.lightBorder,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: NexoraColors.electricBlue,
      primary: NexoraColors.electricBlue,
      onPrimary: Colors.white,
      secondary: NexoraColors.signalTeal,
      onSecondary: NexoraColors.midnightNavy,
      tertiary: NexoraColors.signalTealMuted,
      surface: NexoraColors.darkSurface,
      onSurface: const Color(0xFFF1F5F9),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NexoraColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: NexoraColors.darkBackground,
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: NexoraColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: NexoraColors.darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NexoraColors.electricBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NexoraColors.signalTeal,
          side: const BorderSide(color: NexoraColors.signalTeal, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: NexoraColors.darkBorder,
        thickness: 1,
      ),
    );
  }
}
