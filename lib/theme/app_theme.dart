import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importante: esto conecta con Firebase

void main() async {
  // Estas dos líneas son "mágicas": preparan la app para conectarse a Internet
  WidgetsFlutterBinding.ensureInitialized();
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
      //theme: AppTheme.lightTheme,
       // Empezamos siempre por el Login
    );
  }
}