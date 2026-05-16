import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de colors corporatius de KneeLife
  static const Color primaryBlue    = Color(0xFF1565C0);
  static const Color lightBlue      = Color(0xFF42A5F5);
  static const Color backgroundWhite = Color(0xFFF5F9FF);
  static const Color cardWhite      = Color(0xFFFFFFFF);
  static const Color textDark       = Color(0xFF1A237E);
  static const Color textGrey       = Color(0xFF757575);
  static const Color successGreen   = Color(0xFF2E7D32);
  static const Color warningOrange  = Color(0xFFE65100);
  static const Color errorRed       = Color(0xFFC62828);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: lightBlue,
        error: errorRed,
        surface: cardWhite,
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}