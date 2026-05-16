import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';

enum SessioPhase { preparacio, exercici, questionnaire, resum }

class SessioScreen extends StatefulWidget {
  const SessioScreen({super.key});

  @override
  State<SessioScreen> createState() => _SessioScreenState();
}

class _SessioScreenState extends State<SessioScreen> {
  SessioPhase _currentPhase = SessioPhase.preparacio;

  // Variables de sessió immutables a la desconnexió
  int _currentExerciseIndex = 0; 
  final int _totalRepsExigides = 3; 
  final double _angleObjectiu = 60.0;
  
  bool _isDisconnectDialogShown = false;
  Timer? _interfaceUpdater;

  @override
  void initState() {
    super.initState();
    // Escoltem de forma contínua el servei per si hi ha una caiguda de Bluetooth
    _startBluetoothWatcher();
  }

  void _startBluetoothWatcher() {
    _interfaceUpdater = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      final bleService = context.read<BleService>();
      
      // Control d'Async Gaps i desconnexió: Si es perd la connexió en ple exercici, es congela
      if (!bleService.isConnected && _currentPhase == SessioPhase.exercici) {
        _showDisconnectDialog();
      }
      
      // Actualitzem la interfície reactivament per comprovar el recompte de l'ESP32
      if (_currentPhase == SessioPhase.exercici && bleService.repetitions >= _totalRepsExigides) {
        _onExerciseComplete();
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
        title: const Text("Connexió perduda"),
        content: const Text("S'ha perdut la connexió amb la genollera. Prem 'Reconnectar' per continuar sense perdre el teu progrés."),
        actions: [
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final bleService = context.read<BleService>();

              try {
                // Intenta restablir l'enllaç de la genollera KneeLife
                await bleService.startScanning();
                
                if (!mounted) return;
                
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                _isDisconnectDialogShown = false;
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text("Reconnectar"),
          )
        ],
      ),
    );
  }

  void _onExerciseComplete() {
    // Netegem les repeticions locals del servei per al següent exercici de la sèrie
    _advanceExercise();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Exercici completat! 💪"),
        content: const Text("Has assolit l'objectiu clínic fixat d'aquest exercici."),
        actions: [
          TextButton(
            onPressed: () async {
              final bleService = context.read<BleService>();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              try {
                await bleService.enviarSenyalCalibrar();
              } catch (_) {}
            },
            child: const Text("Continuar"),
          ),
        ],
      ),
    );
  }

  void _advanceExercise() {
    setState(() {
      _currentExerciseIndex += 1;

      if (_currentExerciseIndex >= 3) {
        _currentPhase = SessioPhase.questionnaire;
      }
    });
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
                bleService.currentState,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: bleService.isConnected ? Colors.green[800] : Colors.orange[800]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: bleService.isScanning
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await bleService.startScanning();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
              child: Text(bleService.isScanning ? "Escanejant..." : "Connectar genollera"),
            ),
            const SizedBox(height: 12),
            
            OutlinedButton(
              onPressed: bleService.isConnected
                  ? () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await bleService.enviarSenyalCalibrar();
                        
                        // CORREGIT: Eliminat el botó "Iniciar Sessió" redundant. 
                        // El flux canvia automàticament a la fase d'exercici després de calibrar el dispositiu
                        setState(() {
                          _currentPhase = SessioPhase.exercici;
                        });
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  : null,
              child: const Text("Calibrar i Començar"),
            ),
          ],
        );

      case SessioPhase.exercici:
        final alpha = bleService.currentAngle;
        Color angleColor = AppTheme.errorRed;
        if (alpha >= 5.0 && alpha < _angleObjectiu) angleColor = Colors.orange;
        if (alpha >= _angleObjectiu) angleColor = Colors.green;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Exercici ${_currentExerciseIndex + 1} de 3", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
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
            Text("Angle objectiu: $_angleObjectiu°", style: const TextStyle(color: AppTheme.textGrey, fontSize: 16)),
            const SizedBox(height: 40),
            Text(
              "Repeticions: ${bleService.repetitions} / $_totalRepsExigides", 
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textDark)
            ),
          ],
        );

      case SessioPhase.questionnaire:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Com t'has sentit?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => setState(() => _currentPhase = SessioPhase.resum),
              child: const Text("Finalitzar Sessió"),
            )
          ],
        );

      case SessioPhase.resum:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Sessió completada! 🎉", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textDark), textAlign: TextAlign.center),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Al finalitzar la sessió, restablim el comptador global per a la següent vegada
                Navigator.pop(context);
              },
              child: const Text("Tornar al menú"),
            ),
          ],
        );
    }
  }
}