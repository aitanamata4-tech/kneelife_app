import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercici;
  final VoidCallback onTap;

  const ExerciseCard({super.key, required this.exercici, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String nom = exercici['nom'] ?? "Exercici sense nom";
    final String descripcio = exercici['descripcio'] ?? "Sense descripció.";
    final String descripcioCurta = descripcio.length > 60 
        ? "${descripcio.substring(0, 60)}..." 
        : descripcio;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE3F2FD),
          radius: 24,
          child: Icon(Icons.accessibility_new, color: AppTheme.primaryBlue),
        ),
        title: Text(
          nom,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(descripcioCurta, style: const TextStyle(color: AppTheme.textGrey)),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryBlue),
        onTap: onTap,
      ),
    );
  }
}