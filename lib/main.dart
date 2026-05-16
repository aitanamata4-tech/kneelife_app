import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Connexió nclosa i activa
import 'theme/app_theme.dart';
import 'services/firebase_service.dart';
import 'services/ble_service.dart';
import 'screens/login_screen.dart'; // Pantalla inicial oficial

void main() async {
  // Assegura que els enllaços de Flutter estiguin llestos abans d'iniciar serveis
  WidgetsFlutterBinding.ensureInitialized();
  
  // S'inicialitza el motor de Firebase real per a la validació d'usuaris
  await Firebase.initializeApp(); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Injectem el servei d'autenticació i Realtime Database
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        ),
        // Injectem el servei de Bluetooth per a la genollera KneeLife
        ChangeNotifierProvider<BleService>(
          create: (_) => BleService(),
        ),
      ],
      child: MaterialApp(
        title: 'KneeLife',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme, // Estils visuals globals de l'app
        
        // REQUISIT RESOLT: L'app arrenca directament al Login real
        // Firebase comprovarà les credencials i tancarà el pas si es posa qualsevol brossa
        home: const LoginScreen(), 
      ),
    );
  }
}