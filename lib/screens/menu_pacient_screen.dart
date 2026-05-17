import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importem Firebase per fer el logout reactiu
import 'sessio_screen.dart';
import 'manual_screen.dart';
import 'progress_screen.dart';
import 'login_screen.dart';

class MenuPacientScreen extends StatelessWidget {
  const MenuPacientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Agafem el color primari directament de l'AppTheme configurat al main
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("KneeLife", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // Botó de tancar sessió reactiu
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Cridem a Firebase per tancar sessió. El StreamBuilder del main.dart 
              // s'adonarà del canvi d'estat immediatament i ens retornarà al Login de forma automàtica.
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              // 2. Tornem a la pantalla de Login fent neteja de la ruta
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false, // Això esborra l'historial perquè no puguin tirar enrere amb el botó del mòbil
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hola, Pacient!", 
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor)
            ),
            const Text("Què vols fer avui?", style: TextStyle(color: Colors.grey, fontSize: 16)),
            
            const SizedBox(height: 32),
            
            // TARGETA 1: SESSIÓ D'AVUI (ENLLAÇADA)
            _buildMenuCard(
              context, 
              "Sessió d'Avui", 
              "Comença el teu entrenament", 
              Icons.fitness_center,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SessioScreen()),
                );
              }
            ),
            
            // TARGETA 2: MANUAL D'EXERCICIS (ENLLAÇADA)
            _buildMenuCard(
              context, 
              "Manual d'Exercicis", 
              "Consulta com faire cada exercici", 
              Icons.menu_book,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManualScreen()),
                );
              }
            ),
            
            // TARGETA 3: EL TEU PROGRÉS (ENLLAÇADA)
            _buildMenuCard(
              context, 
              "El Teu Progrés", 
              "Veure la teva evolució", 
              Icons.show_chart,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProgressScreen()),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  // Giny reutilitzable per les targetes del menú
  Widget _buildMenuCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    final primaryColor = Theme.of(context).primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2, // Li dona una miqueta d'ombra elegant
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 40, color: primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}