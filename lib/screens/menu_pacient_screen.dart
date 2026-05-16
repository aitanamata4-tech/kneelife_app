import 'package:flutter/material.dart';
import 'login_screen.dart'; // Importem el login per poder-hi tornar

class MenuPacientScreen extends StatelessWidget {
  const MenuPacientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Agafem el color primari directament del vostre AppTheme configurat al main
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("KneeLife", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // Botó de tancar sessió actiu
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Ens desplaça cap enrere i esborra l'historial per seguretat perquè torni al Login
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
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
            
            // Unim les teves targetes originals amb accions pròpies
            _buildMenuCard(
              context, 
              "Sessió d'Avui", 
              "Comença el teu entrenament", 
              Icons.fitness_center,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Connectant amb la genollera KneeLife... En breu comença l'exercici!")),
                );
                // Més endavant, aquí farem: Navigator.push(context, MaterialPageRoute(builder: (context) => const ExerciciScreen()));
              }
            ),
            
            _buildMenuCard(
              context, 
              "Manual d'Exercicis", 
              "Consulta com fer cada exercici", 
              Icons.menu_book,
              () {
                // Acció futura
              }
            ),
            
            _buildMenuCard(
              context, 
              "El Teu Progrés", 
              "Veure la teva evolució", 
              Icons.show_chart,
              () {
                // Acció futura
              }
            ),
          ],
        ),
      ),
    );
  }

  // Hem afegit la variable 'onTap' perquè cada targeta pugui fer una acció diferent
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