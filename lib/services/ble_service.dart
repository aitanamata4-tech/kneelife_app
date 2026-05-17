import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService with ChangeNotifier {
  bool _isScanning = false;
  bool _isConnected = false;
  double _currentAngle = 0.0;
  String _currentState = "Desconnectat. Encén la genollera.";

  BluetoothDevice? _targetDevice;
  BluetoothCharacteristic? _targetCharacteristic;
  StreamSubscription<List<int>>? _valueSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // UUIDs exactament iguals als configurats a l'ESP32
  final String serviceUuid = "4fafc201-1fb5-459e-8fcc-010101010101";
  final String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // Getters que utilitza la teva SessioScreen
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  double get currentAngle => _currentAngle;
  String get currentState => _currentState;

  // Escaneja l'espai buscant el dispositiu anomenat "KneeLife"
  Future<void> startScanning() async {
    if (_isScanning) return;
    
    _isScanning = true;
    _currentState = "Escanejant buscant KneeLife...";
    notifyListeners();

    // Arrancam l'escaneig físic de l'antena del mòbil durant 5 segons
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == "KneeLife" || r.advertisementData.advName == "KneeLife") {
          _targetDevice = r.device;
          await FlutterBluePlus.stopScan();
          _isScanning = false;
          _currentState = "Genollera trobada. Connectant...";
          notifyListeners();
          
          await _connectToDevice();
          break;
        }
      }
    });

    // Control de temps per si no la troba
    await Future.delayed(const Duration(seconds: 5));
    if (_targetDevice == null) {
      _isScanning = false;
      _currentState = "No s'ha trobat cap genollera KneeLife a prop.";
      notifyListeners();
    }
  }

  // Connecta al xip Bluetooth de l'ESP32
  Future<void> _connectToDevice() async {
    if (_targetDevice == null) return;

    try {
      await _targetDevice!.connect();
      _isConnected = true;
      _currentState = "Genollera connectada. Buscant canals...";
      notifyListeners();

      // Escoltador actiu per si la placa es desconnecta o es queda sense bateria
      _targetDevice!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

      // Descobrim els serveis i característiques de la placa
      List<BluetoothService> services = await _targetDevice!.discoverServices();
      for (BluetoothService s in services) {
        if (s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (BluetoothCharacteristic c in s.characteristics) {
            if (c.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
              _targetCharacteristic = c;
              
              // Ens subscrivim oficialment al canal de NOTIFY de l'ESP32 (Cada 50ms)
              await _targetCharacteristic!.setNotifyValue(true);
              _valueSubscription = _targetCharacteristic!.onValueReceived.listen((value) {
                _processarDadesESP32(value);
              });

              _currentState = "Genollera KneeLife a punt. Esperant calibratge...";
              notifyListeners();
              return;
            }
          }
        }
      }
    } catch (e) {
      _handleDisconnect();
    }
  }

  // RECEPTOR REAL DE LES DADES DE L'ESP32
  void _processarDadesESP32(List<int> value) {
    try {
      // Converteix els bytes de la ràfega Bluetooth a text ASCII (Ex: "34.2,1.2,1")
      String dadaText = utf8.decode(value).trim();
      if (dadaText.isEmpty) return;

      // Escolta si la placa ha respost a l'ordre de calibrar
      if (dadaText == "CALIBRAT") {
        _currentState = "Calibratge completat. Pots començar l'exercici.";
        notifyListeners();
        return;
      }

      // Tallem el text per la coma [angle, velocitat, calibrat]
      List<String> parts = dadaText.split(',');
      if (parts.isNotEmpty) {
        // Agafem la primera posició que és l'angle de flexió calculat pel filtre de l'ESP32
        _currentAngle = double.tryParse(parts[0]) ?? _currentAngle;
        notifyListeners();
      }
    } catch (_) {}
  }

  // Envia l'ordre real "CALIBRAR" cap a la placa
  Future<void> enviarSenyalCalibrar() async {
    if (!_isConnected || _targetCharacteristic == null) return;
    
    _currentState = "Calibrant sensor... Mantingues la cama quieta.";
    notifyListeners();

    try {
      // Escriu directament al buffer de recepció de l'ESP32
      await _targetCharacteristic!.write(utf8.encode("CALIBRAR"));
    } catch (_) {
      _currentState = "Error en enviar el senyal de calibratge.";
      notifyListeners();
    }
  }

  // Neteja de memòria segura si es talla la comunicació
  void _handleDisconnect() {
    _isConnected = false;
    _isScanning = false;
    _currentAngle = 0.0;
    _targetCharacteristic = null;
    _valueSubscription?.cancel();
    _scanSubscription?.cancel();
    _currentState = "Error: S'ha perdut la connexió amb la genollera KneeLife.";
    notifyListeners();
  }

  @override
  void dispose() {
    _valueSubscription?.cancel();
    _scanSubscription?.cancel();
    super.dispose();
  }
}