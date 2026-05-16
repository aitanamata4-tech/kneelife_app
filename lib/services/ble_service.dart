import 'dart:async';
import 'package:flutter/material.dart';

class BleService with ChangeNotifier {
  bool _isScanning = false;
  bool _isConnected = false;
  int _repetitions = 0;
  double _currentAngle = 0.0;
  String _currentState = "Fase 1: Inicial (Cama estesa < 5°)";

  // Getters per poder llegir les dades des de les pantalles
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  int get repetitions => _repetitions;
  double get currentAngle => _currentAngle;
  String get currentState => _currentState;

  // Simula l'escaneig de la genollera KneeLife
  Future<void> startScanning() async {
    _isScanning = true;
    notifyListeners(); 

    await Future.delayed(const Duration(seconds: 2));
    _isScanning = false;
    _isConnected = true;
    _currentState = "Genollera KneeLife Connectada. Esperant calibratge...";
    notifyListeners();
  }

  // Envia el senyal de calibratge a l'ESP32
  Future<void> enviarSenyalCalibrar() async {
    if (!_isConnected) return;
    _currentState = "Calibrant sensor... Mantingues la cama quieta.";
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    _currentState = "Calibratge completat. Pots començar l'exercici.";
    notifyListeners();
    
    // Inicia la simulació del flux de dades reals del sensor
    _simularFluxDadesESP32();
  }

  // Simula la recepció de cadenes "alpha,omega,calibrated" enviades per l'ESP32
  void _simularFluxDadesESP32() {
    Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }

      // Simulem una seqüència de moviment de flexió/extensió 
      if (_repetitions >= 3) {
        _currentState = "Entrenament finalitzat amb èxit!";
        timer.cancel();
        notifyListeners();
        return;
      }

      // Simulació ràpida de canvi d'angle per a la màquina d'estats
      if (_currentAngle < 16.0) {
        _currentAngle += 4.0; // Pujant cap al límit de 15°
      } else {
        _currentAngle = 0.0;  // Torna a baixar del límit de 5° per comptar la repetició
        _repetitions++;
      }

      // Logica de la màquina d'estats simplificada pel mòbil
      if (_currentAngle >= 15.0) {
        _currentState = "Fase 2: Flexió màxima assolida (> 15°)";
      } else if (_currentAngle <= 5.0) {
        _currentState = "Fase 1: Cama estesa (< 5°)";
      }

      notifyListeners(); 
    });
  }

  // NOM CORREGIT SENSE ACCENTS NI CARÀCTERS IL·LEGALS PER EVITAR L'ERROR DE DART
  void forcarDesconnexio() {
    _isConnected = false;
    _currentState = "Error: S'ha perdut la connexió amb la genollera KneeLife.";
    notifyListeners();
  }
}