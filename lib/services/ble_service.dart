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
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  // UUIDs EXACTES coincidents amb l'ESP32
  final String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  double get currentAngle => _currentAngle;
  String get currentState => _currentState;

  // Escaneja l'espai buscant el dispositiu KneeLife de forma segura
  Future<void> startScanning() async {
    if (_isScanning) return;

    // Forcem neteja prèvia per evitar connexions fantasma a Android
    await _clearPreviousConnection();

    _isScanning = true;
    _currentState = "Escanejant buscant KneeLife...";
    notifyListeners();

    try {
      // Arrancam l'escaneig físic de l'antena
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
        withNames: ["KneeLife"], // Filtre a nivell de hardware de l'antena
      );
    } catch (e) {
      _currentState = "Error en iniciar escaneig: $e";
      _isScanning = false;
      notifyListeners();
      return;
    }

    // Escoltam els resultats de l'escaneig (Tipat esmentat en singular corregit)
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == "KneeLife" || r.advertisementData.advName == "KneeLife") {
          _targetDevice = r.device;
          
          // Cancel·lam l'escaneig immediatament per alliberar la pila de Bluetooth
          _scanSubscription?.cancel();
          await FlutterBluePlus.stopScan();
          _isScanning = false;
          _currentState = "Genollera trobada. Connectant...";
          notifyListeners();
          
          await _connectToDevice();
          break;
        }
      }
    }, onError: (error) {
      _isScanning = false;
      _currentState = "Error en flux d'escaneig.";
      notifyListeners();
    });

    // Timeout de seguretat si passats 5 segons no s'ha trobat el target
    Future.delayed(const Duration(seconds: 5), () {
      if (_isScanning && _targetDevice == null) {
        FlutterBluePlus.stopScan();
        _isScanning = false;
        _currentState = "No s'ha trobat cap genollera KneeLife a prop.";
        notifyListeners();
      }
    });
  }

  // Connecta al xip Bluetooth de l'ESP32 i assegura els canals de comunicació
  Future<void> _connectToDevice() async {
    if (_targetDevice == null) return;

    try {
      // Connexió directa amb autoConnect deshabilitat per evitar esperes infinites
      await _targetDevice!.connect(autoConnect: false);
      _isConnected = true;
      _currentState = "Genollera connectada. Buscant canals...";
      notifyListeners();

      // Cancel·lam subscripcions d'estat prèvies si existissin
      await _connectionStateSubscription?.cancel();
      
      // Escoltador acollit d'estat de connexió en temps real
      _connectionStateSubscription = _targetDevice!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

      // Descobrim els serveis del servidor Bluetooth de l'ESP32
      List<BluetoothService> services = await _targetDevice!.discoverServices();
      for (BluetoothService s in services) {
        if (s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (BluetoothCharacteristic c in s.characteristics) {
            if (c.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
              _targetCharacteristic = c;
              
              // Activem de forma robusta les notificacions (NOTIFY)
              await _targetCharacteristic!.setNotifyValue(true);
              
              await _valueSubscription?.cancel();
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
      
      // Si surt del bucle sense retornar, el servei o característica no coincideixen
      _currentState = "Error: Canals de dades no vàlids o incompatibles.";
      _handleDisconnect();

    } catch (e) {
      _currentState = "Error de connexió física: $e";
      _handleDisconnect();
    }
  }

  // RECEPTOR DE DADES OPTIMITZAT CONTRA CARÀCTERS OCULTS
  void _processarDadesESP32(List<int> value) {
    if (value.isEmpty) return;
    try {
      // 1. Convertim els bytes de la ràfega Bluetooth a text ASCII netejant extrems
      String dadaText = utf8.decode(value).trim();
      if (dadaText.isEmpty) return;

      debugPrint("📡 BYTES REBUTS (TEXT): '$dadaText'");

      if (dadaText.contains("calibrada") || dadaText == "CALIBRAT") {
        _currentState = "Calibratge completat de forma correcta.";
        notifyListeners();
        return;
      }

      // 2. NETEJA ABSOLUTA: Eliminem mitjançant Regex qualsevol cosa que no sigui un número o un punt decimal.
      // Això elimina els \n, \r o micro-basura que l'antena de l'ESP32 acobla al tramat.
      String textNet = dadaText.replaceAll(RegExp(r'[^0-9.]'), '');

      if (textNet.isNotEmpty) {
        double? angleParsejat = double.tryParse(textNet);
        if (angleParsejat != null) {
          _currentAngle = angleParsejat;
          notifyListeners(); // Alerta a la SessioScreen de que hi ha un nou angle!
        } else {
          debugPrint("⚠️ No s'ha pogut parsejar a double el text netejat: '$textNet'");
        }
      }
    } catch (e) {
      debugPrint("🚨 Error en processar trama Bluetooth: $e");
    }
  }

  // Envia l'ordre real "CALIBRAR" cap a la placa a través del buffer d'escriptura
  Future<void> enviarSenyalCalibrar() async {
    if (!_isConnected || _targetCharacteristic == null) return;
    
    _currentState = "Calibrant sensor... Mantingues la cama quieta.";
    notifyListeners();

    try {
      // Escrivim al buffer amb resposta per assegurar la recepció a l'ESP32
      await _targetCharacteristic!.write(utf8.encode("CALIBRAR\n"), withoutResponse: false);
    } catch (e) {
      _currentState = "Error en enviar el senyal de calibratge.";
      notifyListeners();
      throw Exception("No s'ha pogut transmetre l'ordre de calibratge.");
    }
  }

  // Neteja manual profunda per evitar l'acumulació de sockets fantasmes a Android
  Future<void> _clearPreviousConnection() async {
    _valueSubscription?.cancel();
    _scanSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    
    if (_targetDevice != null) {
      try {
        await _targetDevice!.disconnect();
      } catch (_) {}
      _targetDevice = null;
    }
    _targetCharacteristic = null;
    _isConnected = false;
  }

  // Gestió de desconnexió controlada per pèrdua de corrent o allunyaments
  void _handleDisconnect() {
    _isConnected = false;
    _isScanning = false;
    _currentAngle = 0.0;
    _targetCharacteristic = null;
    _valueSubscription?.cancel();
    _scanSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _currentState = "Error: S'ha perdut la connexió amb la genollera KneeLife.";
    notifyListeners();
  }

  @override
  void dispose() {
    _clearPreviousConnection();
    super.dispose();
  }
}