import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart'; // Importante: esto trae tu nueva pantalla

void main() {
  runApp(const KneeLifeApp());
}

class KneeLifeApp extends StatelessWidget {
  const KneeLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KneeLife',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // Cambiamos el placeholder por la pantalla real
      home: const LoginScreen(), 
    );
  }
}