import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Llista d'exercicis reals amb enllaços d'imatges de rehabilitació mèdica
    final List<Map<String, String>> exercicis = [
      {
        "titol": "1. Lliscament de Taló (Heel Slides)",
        "descripcio": "Seu o estira't a sobre d'una estora amb les cames esteses. Fes lliscar el taló de la cama afectada lentament cap al teu cos, doblegant el genoll tant com puguis sense sentir dolor agut. Mantén la posició 5 segons i torna a estirar-la.",
        "url_imatge": "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=600&q=80", 
      },
      {
        "titol": "2. Extensió en Arc Curt (Short Arc Quads)",
        "descripcio": "Estira't de brossa o llit i col·loca un corró d'escuma o una tovallola enrotllada a sota del genoll afectat. Contreu els músculs de la cuixa (quàdriceps) i aixeca el peu fins a estirar la cama del tot. Mantén-la recta 5 segons i baixa lentament.",
        "url_imatge": "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=600&q=80",
      },
      {
        "titol": "3. Sentadilles Assistides (Chair Squats)",
        "descripcio": "Aganta't fermament al respatller d'una cadira estable o a una barana. Separa els peus a l'amplada de les espatlles i baixa el cos a poc a poc com si t'anessis a seure, flexionant els genolls sense que passin de la punta dels peus. Puja controladament.",
        "url_imatge": "https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=600&q=80",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manual d'Exercicis"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: exercicis.length,
        itemBuilder: (context, index) {
          final ex = exercicis[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: CrossFadeKeyFrame(ex: ex),
          );
        },
      ),
    );
  }
}

// Giny separat per gestionar el disseny i la càrrega asíncrona de les imatges de la xarxa
class CrossFadeKeyFrame extends StatelessWidget {
  const CrossFadeKeyFrame({
    super.key,
    required this.ex,
  });

  final Map<String, String> ex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CONTENIDOR D'IMATGE CORREGIT: Ara carrega fotos reals d'Internet de forma dinàmica
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Image.network(
            ex["url_imatge"]!,
            height: 180,
            fit: BoxFit.cover,
            // Mentre la imatge es descarrega, mostra un indicador de càrrega circular
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 180,
                color: Colors.grey[100],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            // Si Internet falla o la URL es trenca, mostra una icona d'error elegant
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 180,
                color: Colors.grey[200],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("No s'ha pogut carregar la il·lustració", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ex["titol"]!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ex["descripcio"]!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGrey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}