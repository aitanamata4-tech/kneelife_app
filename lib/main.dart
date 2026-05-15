import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Això inicialitza Firebase fent servir el google-services.json
  await Firebase.initializeApp(); 
  runApp(const KneeLifeApp());
}

class KneeLifeApp extends StatelessWidget {
  const KneeLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KneeLife',
      // theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}