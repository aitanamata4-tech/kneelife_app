import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

enum SessioPhase { preparacio, exercici, questionnaire, resum }

class SessioScreen extends StatefulWidget {
  const SessioScreen({super.key});

  @override
  State<SessioScreen> createState() => _SessioScreenState();
}

class _SessioScreenState extends State<SessioScreen> {
  SessioPhase _currentPhase = SessioPhase.preparacio;

  int _currentExerciseIndex = 0; 
  int _totalRepsExigides = 3; 
  
  double _angleObjectiuDinamic = 45.0; 
  double _maxAngleAssolit = 0.0;
  int _selectedPainLevel = 5; 
  bool _isSavingFirebase = false;

  int _localRepetitions = 0;
  bool _haPassatObjectiu = false;
  bool _isDisconnectDialogShown = false;

  // Estructures de control dinàmic d'acord amb la base de dades Firebase
  List<String> _llistaExercicisAsignats = []; 
  final Map<String, Map<String, dynamic>> _historialSessioActual = {}; 

  @override
  void initState() {
    super.initState();
    _carregarObjectiuClinic();
  }

  Future<void> _carregarObjectiuClinic() async {
    try {
      final firebaseService = context.read<FirebaseService>();
      final assignacio = await firebaseService.obtenirAssignacioClinica();
      
      if (assignacio != null) {
        setState(() {
          // Extraiem i ordenem les claus reals del JSON (Ex: ["ex1", "ex2", "ex3", "ex4", "ex5"])
          _llistaExercicisAsignats = assignacio.keys.where((k) => k.startsWith('ex')).toList()..sort();
          
          if (_llistaExercicisAsignats.isNotEmpty && _currentExerciseIndex < _llistaExercicisAsignats.length) {
            String exActualKey = _llistaExercicisAsignats[_currentExerciseIndex];
            _angleObjectiuDinamic = double.tryParse(assignacio[exActualKey]['angleObjectiu'].toString()) ?? 45.0;
            _totalRepsExigides = int.tryParse(assignacio[exActualKey]['repeticions'].toString()) ?? 3;
          }
        });
      }
    } catch (_) {
      setState(() {
        _llistaExercicisAsignats = ["ex1", "ex2", "ex3"]; // Fallback de seguretat
        _angleObjectiuDinamic = 45.0; 
        _totalRepsExigides = 3;
      });
    }
  }

  void _showDisconnectDialog() {
    if (_isDisconnectDialogShown) return;
    _isDisconnectDialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Connexió de seguretat"),
        content: const Text("S'ha perdut la recepció de dades de la genollera. Comprova que l'ESP32 tingui bateria o prem 'Reconnectar'."),
        actions: [
          TextButton(
            onPressed: () async {
              final bleService = context.read<BleService>();
              try {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _isDisconnectDialogShown = false;
                await bleService.startScanning();
              } catch (_) {}
            },
            child: const Text("Reconnectar"),
          )
        ],
      ),
    );
  }

  void _onExerciseComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Exercici completat! 💪"),
        content: Text("Has assolit les $_totalRepsExigides repeticions de l'exercici ${_currentExerciseIndex + 1}."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _advanceExercise();
            },
            child: const Text("Continuar"),
          ),
        ],
      ),
    );
  }

  void _advanceExercise() {
    // Si la llista encara no ha carregat correctament, evitem el buidat erroni
    if (_llistaExercicisAsignats.isEmpty) return;

    String exActualKey = _llistaExercicisAsignats[_currentExerciseIndex];
    
    // Guardem les mètriques reals d'aquest exercici en memòria abans de passar al següent
    _historialSessioActual[exActualKey] = {
      'angle_maxim': _maxAngleAssolit,
      'repeticions': _localRepetitions,
    };

    setState(() {
      _localRepetitions = 0; 
      _haPassatObjectiu = false;
      _maxAngleAssolit = 0.0;
      _currentExerciseIndex += 1;

      // El límit de tancament ja no és un 3 estàtic, és la llargada real del JSON
      if (_currentExerciseIndex >= _llistaExercicisAsignats.length) {
        _currentPhase = SessioPhase.questionnaire;
      } else {
        _carregarObjectiuClinic(); 
      }
    });
  }

  Future<void> _enviarDadesADataubase() async {
    final firebaseService = context.read<FirebaseService>();
    
    setState(() => _isSavingFirebase = true);
    try {
      // Injectem el nivell de dolor seleccionat a cadascun dels blocs completats
      _historialSessioActual.forEach((key, value) {
        value['dolor'] = _selectedPainLevel;
      });

      // Enviem el mapa net i estructurat directament al servei de Firebase Realtime
      await firebaseService.pujarSessio(
        resultatsExercicis: _historialSessioActual,
        nivellDolorGeneral: _selectedPainLevel,
      );

      if (!mounted) return;

      setState(() {
        _isSavingFirebase = false;
        _currentPhase = SessioPhase.resum;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingFirebase = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error guardant a Firebase: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escolta activa i centralitzada dels canvis que emet el BleService
    final bleService = context.watch<BleService>();

    // Execució de l'algorisme de control cinemàtic mitjançant el Provider actiu
    if (bleService.isConnected && _currentPhase == SessioPhase.exercici) {
      double angleActual = bleService.currentAngle;
      if (angleActual > 140.0) angleActual = 0.0;

      if (angleActual > _maxAngleAssolit) {
        _maxAngleAssolit = angleActual;
      }

      if (angleActual >= _angleObjectiuDinamic && !_haPassatObjectiu) {
        _haPassatObjectiu = true;
      }
      
      if (_haPassatObjectiu && angleActual < 22.0) {
        _localRepetitions += 1;
        _haPassatObjectiu = false; 

        if (_localRepetitions >= _totalRepsExigides) {
          Future.microtask(() => _onExerciseComplete());
        }
      }
    } else if (!bleService.isConnected && _currentPhase == SessioPhase.exercici) {
      Future.microtask(() => _showDisconnectDialog());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Sessió de Genoll")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildPhaseContent(bleService),
      ),
    );
  }

  Widget _buildPhaseContent(BleService bleService) {
    switch (_currentPhase) {
      case SessioPhase.preparacio:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bleService.isConnected ? Colors.green.withAlpha(25) : Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bleService.isConnected ? "Genollera Connectada correctament" : "Dispositiu desconnectat. Encén la genollera KneeLife.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: bleService.isConnected ? Colors.green[800] : Colors.orange[800]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: bleService.isScanning
                  ? null
                  : () async {
                      try {
                        await bleService.startScanning();
                      } catch (_) {}
                    },
              child: Text(bleService.isScanning ? "Escanejant..." : "Connectar via Bluetooth"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
              onPressed: bleService.isConnected 
                ? () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await bleService.enviarSenyalCalibrar();
                      setState(() {
                        _localRepetitions = 0;
                        _haPassatObjectiu = false;
                        _currentPhase = SessioPhase.exercici;
                      });
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Error al calibrar: $e")),
                      );
                    }
                  }
                : null, 
              child: const Text("Calibrar i Començar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );

      case SessioPhase.exercici:
        double alpha = bleService.currentAngle;
        if (alpha > 140.0) alpha = 0.0; 

        Color angleColor = AppTheme.errorRed;
        if (alpha >= 5.0 && alpha < _angleObjectiuDinamic) angleColor = Colors.orange;
        if (alpha >= _angleObjectiuDinamic) angleColor = Colors.green;

        // Nombre total d'exercicis reals extrets de la llista calculada
        final totalExercicis = _llistaExercicisAsignats.isEmpty ? 3 : _llistaExercicisAsignats.length;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Exercici ${_currentExerciseIndex + 1} de $totalExercicis", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_currentExerciseIndex + 1) / totalExercicis,
              backgroundColor: Colors.grey[200],
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 40),
            Text(
              "${alpha.toStringAsFixed(1)}°",
              style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: angleColor),
            ),
            Text("Angle objectiu d'aquest exercici: ${_angleObjectiuDinamic.toStringAsFixed(0)}°", style: const TextStyle(color: AppTheme.textGrey, fontSize: 16)),
            const SizedBox(height: 30),
            Text(
              "Repeticions: $_localRepetitions / $_totalRepsExigides", 
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textDark)
            ),
            const Spacer(),
            const Text(
              "Recepció de dades IMU activa. Flexiona el genoll per moure l'angle.", 
              style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case SessioPhase.questionnaire:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Qüestionari de Dolor Clínic",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Indica quin nivell de dolor has sentit al genoll durant els exercicis:",
              style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            Center(
              child: Text(
                "$_selectedPainLevel",
                style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Color.lerp(Colors.green, Colors.red, _selectedPainLevel / 10)),
              ),
            ),
            
            Slider(
              value: _selectedPainLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _selectedPainLevel.toString(),
              activeColor: Color.lerp(Colors.green, Colors.red, _selectedPainLevel / 10),
              onChanged: (value) {
                setState(() => _selectedPainLevel = value.toInt());
              },
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sense dolor (1)", style: TextStyle(fontSize: 11, color: Colors.green)),
                Text("Dolor insuportable (10)", style: TextStyle(fontSize: 11, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 50),
            
            ElevatedButton(
              onPressed: _isSavingFirebase ? null : _enviarDadesADataubase,
              child: _isSavingFirebase 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Desar dades i Finalitzar"),
            )
          ],
        );

      case SessioPhase.resum:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text("Sessió guardada correctament! 🎉", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text("Les teves dades ja estan actualitzades a la consola del metge de Firebase.", style: TextStyle(fontSize: 14, color: AppTheme.textGrey), textAlign: TextAlign.center),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Tornar al menú principal"),
            ),
          ],
        );
    }
  }
}