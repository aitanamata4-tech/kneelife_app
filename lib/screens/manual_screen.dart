import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

// --- PANTALLA 1: LLISTA D'EXERCICIS DEL MANUAL ---
class ManualScreen extends StatefulWidget {
  const ManualScreen({super.key});

  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _exercicis = [];
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _carregarExercicis();
  }

  Future<void> _carregarExercicis() async {
    try {
      final firebaseService = context.read<FirebaseService>();
      final data = await firebaseService.descarrregarExercicis();
      setState(() {
        _exercicis = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Manual d'Exercicis")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(_errorMessage, style: const TextStyle(color: AppTheme.errorRed), textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manual d'Exercicis"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: _exercicis.length,
        itemBuilder: (context, index) {
          final ex = _exercicis[index];
          final String nom = ex['nom'] ?? "Exercici sense nom";
          final String descripcio = ex['descripcio'] ?? "Sense descripció.";
          
          // Requeriment: Mostrar el títol i els primers 60 caràcters de la descripció
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
              // Avatar blau circular amb icona de genoll/accessibilitat demanat
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
              onTap: () {
                // Navegació cap al detall de l'exercici pasant les dades de Firebase
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExerciciDetallScreen(exercici: ex),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// --- PANTALLA 2: DETALL DE L'EXERCICI SELECCIONAT ---
class ExerciciDetallScreen extends StatelessWidget {
  final Map<String, dynamic> exercici;

  const ExerciciDetallScreen({super.key, required this.exercici});

  @override
  Widget build(BuildContext context) {
    final String nom = exercici['nom'] ?? "Detall de l'exercici";
    final String descripcio = exercici['descripcio'] ?? "No hi ha instruccions disponibles.";

    return Scaffold(
      appBar: AppBar(
        title: Text(nom),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Requeriment: Contenidor blau clar de 200px d'alçada com a placeholder d'imatge
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.accessibility_new, size: 80, color: AppTheme.primaryBlue),
                  SizedBox(height: 8),
                  Text(
                    "Il·lustració de l'exercici",
                    style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              "Instruccions d'execució",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            
            // Text complet amb alçada de línia confortable de 1.6 demanat per la spec
            Text(
              descripcio,
              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            
            // Chip estàtic d'informació muscular requerit al final
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                backgroundColor: Colors.grey[200],
                label: const Text(
                  "Múscul: Quàdriceps / Isquiotibials",
                  style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}