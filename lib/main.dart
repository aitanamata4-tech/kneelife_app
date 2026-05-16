import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'services/ble_service.dart';
import 'screens/login_screen.dart';
import 'screens/menu_pacient_screen.dart';
import 'services/firebase_service.dart'; // <--- AFEGEIX AQUEST IMPORT AQUÍ!
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // NOTA: Si encara no has lligat Firebase al projecte amb la teva companya,
  // pots comentar la línia de Firebase.initializeApp() momentàniament per provar la UI.
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        Provider<BleService>(
          create: (_) => BleService(),
          dispose: (_, service) => service.dispose(),
        ),
        // Aquí s'afegirà el FirebaseService quan creeu el fitxer:
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        )
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
      title: 'KneeLife',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // Flux d'autenticació reactiu basat en la guia
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Si l'usuari està loguejat, va al menú; si no, al Login
          if (snapshot.hasData && snapshot.data != null) {
            return const MenuPacientScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}