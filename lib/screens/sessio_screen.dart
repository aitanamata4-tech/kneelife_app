import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';

enum SessioPhase { preparacio, exercici, questionnaire, resum }
enum RepState { waitingForUp, waitingForDown }

class SessioScreen extends StatefulWidget {
  const SessioScreen({super.key});

  @override
  State<SessioScreen> createState() => _SessioScreenState();
}

class _SessioScreenState extends State<SessioScreen> {
  SessioPhase _currentPhase = SessioPhase.preparacio;
  BleConnectionState _connectionState = BleConnectionState.disconnected;

  // Variables de sessió immutables a la desconnexió
  String? _sessionId;
  int _currentExerciseIndex = 0; 
  int _currentReps = 0;
  double _currentMaxAngle = 0.0;
  RepState _repState = RepState.waitingForUp;

  final int _totalRepsExigides = 3; // Exemple de l'especificació
  final double _angleObjectiu = 60.0;

  StreamSubscription<BleConnectionState>? _connectionSub;
  StreamSubscription<double>? _angleSub;
  bool _isDisconnectDialogShown = false;

  @override
  void initState() {
    super.initState();
    final bleService = context.read<BleService>();
    
    _connectionSub = bleService.connectionStream.listen((state) {
      setState(() => _connectionState = state);

      if (state == BleConnectionState.disconnected && _currentPhase == SessioPhase.exercici) {
        _pauseAngleStream();
        _showDisconnectDialog();
      }
    });
  }

  void _startListeningAngles() {
    _angleSub?.cancel();
    _angleSub = context.read<BleService>().angleStream.listen((alpha) {
      if (_currentPhase != SessioPhase.exercici) return;

      setState(() {
        if (alpha > _currentMaxAngle) _currentMaxAngle = alpha;

        // Màquina de repeticions estricta: llindars 15.0 i 5.0
        if (_repState == RepState.waitingForUp) {
          if (alpha > 15.0) {
            _repState = RepState.waitingForDown;
          }
        } else if (_repState == RepState.waitingForDown) {
          if (alpha < 5.0) {
            _currentReps += 1;
            _repState = RepState.waitingForUp;

            if (_currentReps >= _totalRepsExigides) {
              _onExerciseComplete();
            }
          }
        }
      });
    });
  }

  void _pauseAngleStream() {
    _angleSub?.cancel();
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
              // Capturem el messenger abans de la línia asíncrona (Això evita l'async gap)
              final messenger = ScaffoldMessenger.of(context);
              final bleService = context.read<BleService>();

              try {
                await bleService.connect();
                
                // Comprovem primer si la pantalla encara existeix
                if (!mounted) return;
                _startListeningAngles();
                
                // Comprovem si el context del propi diàleg segueix actiu abans de tancar-lo
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
    _pauseAngleStream();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Exercici completat! 💪"),
        content: Text("Angle màxim assolit: ${_currentMaxAngle.toStringAsFixed(1)}°"),
        actions: [
          TextButton(
            onPressed: () async {
              final bleService = context.read<BleService>();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              try {
                await bleService.sendCalibrate();
              } catch (_) {}
              _advanceExercise();
            },
            child: const Text("Calibrar i continuar"),
          ),
          TextButton(
            onPressed: () {
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              _advanceExercise();
            },
            child: const Text("Continuar sense calibrar"),
          ),
        ],
      ),
    );
  }

  void _advanceExercise() {
    setState(() {
      _currentReps = 0;
      _currentMaxAngle = 0.0;
      _repState = RepState.waitingForUp;
      _currentExerciseIndex += 1;

      if (_currentExerciseIndex >= 3) {
        _currentPhase = SessioPhase.questionnaire;
      } else {
        _startListeningAngles();
      }
    });
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _angleSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleService = context.read<BleService>();

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
          children: [
            Text("Estat: $_connectionState", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connectionState == BleConnectionState.scanning
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await bleService.connect();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
              child: const Text("Connectar genollera"),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _connectionState == BleConnectionState.connected
                  ? () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await bleService.sendCalibrate();
                        messenger.showSnackBar(
                          const SnackBar(content: Text("Calibratge enviat. Mantén el genoll recte.")),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  : null,
              child: const Text("Calibrar"),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _connectionState == BleConnectionState.connected
                  ? () {
                      setState(() {
                        _sessionId = "sessio_local"; 
                        debugPrint("ID de sessió inicialitzada: $_sessionId");
                        _currentPhase = SessioPhase.exercici;
                      });
                      _startListeningAngles();
                    }
                  : null,
              child: const Text("Iniciar Sessió"),
            ),
          ],
        );

      case SessioPhase.exercici:
        return StreamBuilder<double>(
          stream: bleService.angleStream,
          initialData: 0.0,
          builder: (context, snapshot) {
            final alpha = snapshot.data ?? 0.0;
            Color angleColor = Colors.red;
            if (alpha >= 5.0 && alpha < _angleObjectiu) angleColor = Colors.orange;
            if (alpha >= _angleObjectiu) angleColor = Colors.green;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Exercici ${_currentExerciseIndex + 1} de 3", style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: (_currentExerciseIndex + 1) / 3),
                const SizedBox(height: 40),
                Text(
                  "${alpha.toStringAsFixed(1)}°",
                  style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: angleColor),
                ),
                Text("Angle objectiu: $_angleObjectiu°", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                Text("Repeticions: $_currentReps / $_totalRepsExigides", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            );
          },
        );

      case SessioPhase.questionnaire:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Com t'has sentit?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
          children: [
            const Text("Sessió completada! 🎉", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tornar al menú"),
            ),
          ],
        );
    }
  }
}