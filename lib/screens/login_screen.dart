import 'package:flutter/material.dart';
import 'menu_pacient_screen.dart'; // Importem la pantalla a la qual anirem

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Els "controladors" serveixen per capturar el text que escriu l'usuari
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Funció simulada de login (més endavant es connectarà a Firebase Auth amb un try/catch)
  void _intentarLogin() {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      // Si algun camp està buit, mostrem un avís a baix de tot
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Si us plau, omple tots els camps")),
      );
      return;
    }

    // De moment, com que estem fent proves i no volem dependre de registrar usuaris
    // a la base de dades a cada moment, si posen qualsevol dada, passem de pantalla:
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MenuPacientScreen()),
    );
  }

  @override
  void dispose() {
    // Netegem els controladors de la memòria de l'ordinador quan sortim de la pantalla
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la genollera intel·ligent 
            const Icon(Icons.accessibility_new, size: 80, color: Colors.blue),
            const Text(
              "KneeLife",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const Text("La teva rehabilitació intel·ligent", style: TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 48),
            
            // Camp de Email (Ara connectat al controlador)
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Correu electrònic",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Camp de Contrasenya (Ara connectat al controlador)
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Contrasenya",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Botó de Iniciar Sessió actiu
            ElevatedButton(
              onPressed: _intentarLogin, // Executa la funció de dalt en fer clic
              child: const Text("Iniciar Sessió"),
            ),
          ],
        ),
      ),
    );
  }
}