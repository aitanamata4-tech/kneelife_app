import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:kneelife_app/theme/app_theme.dart';
import 'package:kneelife_app/services/ble_services.dart';
import 'package:kneelife_app/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialitza Firebase correctament fent servir el google-services.json
  await Firebase.initializeApp(); 
  
  runApp(
    MultiProvider(
      providers: [
        Provider<BleService>(
          create: (_) => BleService(),
          dispose: (_, bleService) => bleService.disconnect(),
        ),
      ],
      child: const KneeLifeApp(),
    ),
  );
}

class KneeLifeApp extends StatelessWidget {
  const KneeLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KneeLife',
      
      // Activem el vostre tema visual corporatiu sense errors
      theme: AppTheme.lightTheme, 
      
      home: const LoginScreen(),
    );
  }
}