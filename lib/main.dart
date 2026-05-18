import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// Importacions dels teus serveis
import 'services/ble_service.dart';
import 'services/firebase_service.dart';

// Importacions de les teves pantalles
import 'screens/login_screen.dart';
import 'screens/menu_pacient_screen.dart'; // Aquí és on es necessita l'import ara!
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inicialitza Firebase a l'arrancar la app
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleService()),
        Provider(create: (_) => FirebaseService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KneeLife',
      theme: AppTheme.lightTheme, // El teu tema actual (adapta el nom si és diferent)
      debugShowCheckedModeBanner: false,
      
      // El controlador reactiu que es quedarà escoltant a Firebase en segon pla
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          
          // 1. Si Firebase està comprovant la sessió al principi, mostrem el cercle de càrrega
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // 2. Si l'usuari s'ha loguejat correctament (Snapshot té dades), saltem al menú
          if (snapshot.hasData && snapshot.data != null) {
            return const MenuPacientScreen();
          }
          
          // 3. Si no hi ha cap usuari o s'ha tancat sessió, es queda al Login
          return const LoginScreen();
        },
      ),
    );
  }
}