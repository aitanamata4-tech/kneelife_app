import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Llista de 5 exercicis reals coordinats amb la base de dades de Firebase
    final List<Map<String, String>> exercicis = [
      {
        "titol": "1. Lliscament de Taló (Heel Slides)",
        "descripcio": "Estirat boca amunt, llisca el taló pel llit apropant-lo al gluti de forma lenta i controlada.",
        "url_imatge": "https://www.shutterstock.com/image-vector/woman-doing-laying-heel-slides-260nw-2275854571.jpg", 
      },
      {
        "titol": "2. Extensió en Arc Curt (Short Arc Quads)",
        "descripcio": "Col·loca un corró o tovallola sota el genoll. Estira la cama completament aixecant el taló i mantén la posició uns segons.",
        "url_imatge": "https://www.arthritis-uk.org/media/n5ick14o/short-arc-quad-500x500.jpg",
      },
      {
        "titol": "3. Sentadilles Assistides (Chair Squats)",
        "descripcio": "Agafa't a una cadira o barana estable per seguretat. Baixa el maluc a poc a poc com si t'anessis a seure i torna a pujar.",
        "url_imatge": "https://i0.wp.com/courtneymedicalgroupaz.com/wp-content/uploads/2018/10/img_4642.jpg?fit=960%2C640&ssl=1",
      },
      {
        "titol": "4. Flexió de Genoll en Bipedestació",
        "descripcio": "Dret, agafat a una taula o cadira per no perdre l'equilibri. Doblega el genoll cap enrere intentant portar el taló cap al gluti, sans moure la cuixa.",
        "url_imatge": "https://berkmanmd.com/wp-content/uploads/2020/02/flexion-img-1.jpg",
      },
      {
        "titol": "5. Extensió de Genoll Assegut",
        "descripcio": "Seu en una cadira amb l'esquena recta. Estira la cama cap endavant fins a deixar-la completament recta i paral·lela a terra, mantén 2 segons i baixa a poc a poc.",
        "url_imatge": "https://traumatologiahellin.wordpress.com/wp-content/uploads/2011/10/flexo-extension-rodillas-sentado.jpg",
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
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Image.network(
            ex["url_imatge"]!,
            height: 180,
            fit: BoxFit.cover,
            // Mentre la imatge es descarrega de la xarxa, mostra un indicador de càrrega
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
            // Si la URL falla o no hi ha Internet, mostra una icona d'error elegant
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