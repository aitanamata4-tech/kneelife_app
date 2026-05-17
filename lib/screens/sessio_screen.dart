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
  final int _totalRepsExigides = 3; 
  
  double _angleObjectiuDinamic = 45.0; 
  double _maxAngleAssolit = 0.0;
  int _selectedPainLevel = 5; 
  bool _isSavingFirebase = false;

  // COMPTATGE ADAPTATIU I CLINICAMENT COMPASSIU
  int _localRepetitions = 0;
  bool _haPassatObjectiu = false;

  bool _isDisconnectDialogShown = false;
  Timer? _interfaceUpdater;

  @override
  void initState() {
    super.initState();
    _carregarObjectiuClinic();
    _startBluetoothWatcher();
  }

  Future<void> _carregarObjectiuClinic() async {
    try {
      final firebaseService = context.read<FirebaseService>();
      final assignacio = await firebaseService.obtenirAssignacioClinica();
      if (assignacio != null && assignacio['ex${_currentExerciseIndex + 1}'] != null) {
        setState(() {
          _angleObjectiuDinamic = double.tryParse(assignacio['ex${_currentExerciseIndex + 1}']['angleObjectiu'].toString()) ?? 45.0;
        });
      }
    } catch (_) {
      setState(() {
        _angleObjectiuDinamic = 45.0; 
      });
    }
  }

  void _startBluetoothWatcher() {
    // Sincronitzat a 50ms amb l'ESP32 per a un moviment en temps real totalment continu
    _interfaceUpdater = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final bleService = context.read<BleService>();
      
      if (bleService.isConnected) {
        if (_currentPhase == SessioPhase.exercici) {
          final double angleActual = bleService.currentAngle;

          // Guardem el pic real maxxim que flexiona el pacient de veritat (ex: els 45 graus)
          if (angleActual > _maxAngleAssolit) {
            _maxAngleAssolit = angleActual;
          }

          // LÒGICA DE RECOMPTE ADAPTATIVA:
          // 1. El pacient inicia la flexió i supera un llindar funcional de seguretat (25°) 
          // per registrar intenció, sense obligar-lo a arribar al límit del metge si no pot.
          if (angleActual >= 25.0 && !_haPassatObjectiu) {
            _haPassatObjectiu = true;
          }
          
          // 2. La repetició es valida quan la cama torna a estar estirada (< 22°)
          if (_haPassatObjectiu && angleActual < 22.0) {
            _localRepetitions += 1;
            _haPassatObjectiu = false; // Reset per a la pròxima flexió

            if (_localRepetitions >= _totalRepsExigides) {
              _onExerciseComplete();
            }
          }
        }
      } else {
        if (_currentPhase == SessioPhase.exercici) {
          _showDisconnectDialog();
        }
      }
      
      if (mounted) setState(() {});
    });
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
                await bleService.startScanning();
                if (!mounted) return;
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _isDisconnectDialogShown = false;
              } catch (_) {}
            },
            child: const Text("Reconnectar"),
          )
        ],
      ),
    );
  }

  void _onExerciseComplete() {
    _interfaceUpdater?.cancel();

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
    setState(() {
      _localRepetitions = 0; 
      _haPassatObjectiu = false;
      _maxAngleAssolit = 0.0;
      _currentExerciseIndex += 1;

      if (_currentExerciseIndex >= 3) {
        _currentPhase = SessioPhase.questionnaire;
      } else {
        _carregarObjectiuClinic(); 
        _startBluetoothWatcher();
      }
    });
  }

  Future<void> _enviarDadesADataubase() async {
    final firebaseService = context.read<FirebaseService>();
    
    setState(() => _isSavingFirebase = true);
    try {
      await firebaseService.pujarSessio(
        exerciciId: "ex${_currentExerciseIndex + 1}",
        repeticionsFetes: _totalRepsExigides,
        angleMaxim: _maxAngleAssolit, // Puja el pic real assolit (ex: 45)
        nivellDolor: _selectedPainLevel,
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
  void dispose() {
    _interfaceUpdater?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleService = context.watch<BleService>();

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
                color: bleService.isConnected ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
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
        final double alpha = bleService.currentAngle;
        final int currentReps = _localRepetitions; 

        Color angleColor = AppTheme.errorRed;
        if (alpha >= 5.0 && alpha < _angleObjectiuDinamic) angleColor = Colors.orange;
        if (alpha >= _angleObjectiuDinamic) angleColor = Colors.green;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Exercici ${_currentExerciseIndex + 1} de 3", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_currentExerciseIndex + 1) / 3,
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
              "Repeticions: $currentReps / $_totalRepsExigides", 
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