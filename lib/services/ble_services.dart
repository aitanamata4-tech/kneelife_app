import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  // Claus UUID estàndard per a la comunicació amb l'ESP32 de la genollera
  final String serviceUuid = "4fafc201-1fb5-459e-8fcc-010101010101"; 
  final String charUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";    

  final StreamController<double> _angleController = StreamController<double>.broadcast();
  Stream<double> get angleStream => _angleController.stream;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _valueSubscription;

  // Comprova si estem connectats actualment
  bool get isConnected => _device != null;

  Future<void> connect() async {
    // 1. Demanar de manera segura els permisos de Bluetooth i ubicació de l'usuari
    await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();
    
    // 2. Iniciar l'escaneig de dispositius propers
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    
    late StreamSubscription<List<ScanResult>> subscription;
    subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        // Busquem el dispositiu que es digui KneeLife
        if (r.device.platformName == "KneeLife") { 
          await FlutterBluePlus.stopScan();
          _device = r.device;
          
          try {
            await _device!.connect();
            // Important: esperem que es descobreixin els serveis abans de tancar la subscripció
            await _discoverServices();
          } catch (e) {
            print("Error en connectar al dispositiu: $e");
          }
          
          await subscription.cancel(); 
          break;
        }
      }
    });
  }

  Future<void> _discoverServices() async {
    if (_device == null) return;
    
    List<BluetoothService> services = await _device!.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
        for (var char in service.characteristics) {
          if (char.uuid.toString().toLowerCase() == charUuid.toLowerCase()) {
            _characteristic = char;
            
            // Activem les notificacions en temps real per rebre l'angle contínuament
            await _characteristic!.setNotifyValue(true);
            
            // Cancel·lem subscripcions antigues si existissin per evitar duplicats
            await _valueSubscription?.cancel();
            
            _valueSubscription = _characteristic!.lastValueStream.listen((value) {
              if (value.isNotEmpty) {
                _parseData(utf8.decode(value));
              }
            });
          }
        }
      }
    }
  }

  void _parseData(String rawString) {
    // Si la genollera s'està calibrant o està esperant, ignorem la línia
    if (rawString == "CALIBRAT" || rawString.contains("Esperant")) return;
    
    final parts = rawString.split(',');
    if (parts.length >= 1) {
      // Agafem el primer valor (l'angle) i l'enviem a la interfície a través del Stream
      final double? angle = double.tryParse(parts[0]);
      if (angle != null) {
        _angleController.add(angle);
      }
    }
  }

  // Funció vital per tancar el Bluetooth quan sortim i no col·lapsar la genollera
  Future<void> disconnect() async {
    await _valueSubscription?.cancel();
    _valueSubscription = null;
    _characteristic = null;
    
    if (_device != null) {
      await _device!.disconnect();
      _device = null;
    }
    print("Genollera KneeLife desconnectada correctament.");
  }
}