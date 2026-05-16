import 'package:flutter/material.dart';

class AppTheme {
  // 1. Definició de la teva paleta de colors constants de KneeLife
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color backgroundWhite = Color(0xFFF5F9FF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A237E);
  static const Color textGrey = Color(0xFF757575);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color warningOrange = Color(0xFFE65100);
  static const Color errorRed = Color(0xFFC62828);

  // 2. El mètode oficial que necessita el main.dart per aplicar els estils globals
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundWhite,
      primaryColor: primaryBlue,
      
      // Estil per a les barres superiors de les pantalles
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.bold, 
          color: Colors.white
        ),
      ),

      // CORREGIT: Utilitzem 'CardThemeData' en lloc de 'CardTheme' per complir amb Flutter
      cardTheme: const CardThemeData(
        color: cardWhite,
        surfaceTintColor: cardWhite,
      ),

      // Estil per als botons principals (com 'Connectar genollera' o 'Finalitzar')
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // Estil per als botons secundaris (com 'Calibrar')
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      
      // Estil per a la barra de càrrega del progrés dels exercicis
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
        linearTrackColor: Color(0xFFE0E0E0),
      ),
    );
  }
}