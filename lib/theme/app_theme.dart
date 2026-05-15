import 'package:flutter/material.dart';

// Definimos los colores de KneeLife según el diseño
const Color primaryBlue = Color(0xFF1565C0);
const Color lightBlue = Color(0xFF42A5F5);
const Color backgroundWhite = Color(0xFFF5F9FF);
const Color errorRed = Color(0xFFC62828);

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: backgroundWhite,
    appBarTheme: const AppBarTheme(backgroundColor: primaryBlue, foregroundColor: Colors.white),
    // Los botones deben ser azules y con bordes redondeados
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}