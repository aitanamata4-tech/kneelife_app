import 'package:flutter/material.dart';

class MenuPacientScreen extends StatelessWidget {
  const MenuPacientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KneeLife"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hola, Pacient!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Text("Què vols fer avui?", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            
            // Les tres targetes que vau demanar
            _buildMenuCard(context, "Sessió d'Avui", "Comença el teu entrenament", Icons.fitness_center),
            _buildMenuCard(context, "Manual d'Exercicis", "Consulta com fer cada exercici", Icons.menu_book),
            _buildMenuCard(context, "El Teu Progrés", "Veure la teva evolució", Icons.show_chart),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String subtitle, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 40, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Aquí anirem a cada pantalla
        },
      ),
    );
  }
}