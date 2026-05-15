import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la rodillera inteligente
            const Icon(Icons.accessibility_new, size: 80, color: Colors.blue),
            const Text(
              "KneeLife",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const Text("La teva rehabilitació intel·ligent", style: TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 48),
            
            // Campo de Email en catalán
            const TextField(
              decoration: InputDecoration(
                labelText: "Correu electrònic",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Campo de Contraseña
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Contrasenya",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Botón de Iniciar Sesión (Estilo KneeLife)
            ElevatedButton(
              onPressed: () {
                // Aquí conectaremos con Firebase Auth más adelante
              },
              child: const Text("Iniciar Sessió"),
            ),
          ],
        ),
      ),
    );
  }
}