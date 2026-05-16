import 'dart:async';
import 'dart:convert';
// import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum BleConnectionState { disconnected, scanning, connecting, connected }

class KneeLifeBleException implements Exception {
  final String message;
  KneeLifeBleException(this.message);
  @override
  String toString() => message;
}

class BleService {
  static const String deviceName = "KneeLife";
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-010101010101";
  static const String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // Patró Singleton Exigit
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;

  final _angleController = StreamController<double>.broadcast();
  final _connectionController = StreamController<BleConnectionState>.broadcast();

  StreamSubscription<List<int>>? _valueSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  BleConnectionState _currentState = BleConnectionState.disconnected;

  Stream<double> get angleStream => _angleController.stream;
  Stream<BleConnectionState> get connectionStream => _connectionController.stream;
  bool get isConnected => _currentState == BleConnectionState.connected;

  void _emitState(BleConnectionState state) {
    _currentState = state;
    _connectionController.add(state);
  }

  Future<void> connect() async {
    _emitState(BleConnectionState.scanning);

    // Gestió de permisos segons Android 12+ i iOS
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    if (statuses.values.any((status) => status.isDenied || status.isPermanentlyDenied)) {
      _emitState(BleConnectionState.disconnected);
      throw KneeLifeBleException("Permisos Bluetooth denegats. Activa'ls des de la configuració del dispositiu.");
    }

    Completer<void> completer = Completer();
    bool found = false;

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == deviceName) {
          found = true;
          await FlutterBluePlus.stopScan();
          _scanSubscription?.cancel();
          
          _emitState(BleConnectionState.connecting);
          try {
            await r.device.connect(timeout: const Duration(seconds: 5));
            _device = r.device;
            
            List<BluetoothService> services = await _device!.discoverServices();
            for (var service in services) {
              if (service.uuid.toString().toLowerCase() == serviceUuid) {
                for (var char in service.characteristics) {
                  if (char.uuid.toString().toLowerCase() == characteristicUuid) {
                    _characteristic = char;
                    break;
                  }
                }
              }
            }

            if (_characteristic != null) {
              _emitState(BleConnectionState.connected);
              _startNotifications();
            } else {
              await _device!.disconnect();
              _emitState(BleConnectionState.disconnected);
              throw KneeLifeBleException("Canal de la genollera no compatible.");
            }
            if (!completer.isCompleted) completer.complete();
          } catch (e) {
            _emitState(BleConnectionState.disconnected);
            if (!completer.isCompleted) completer.completeError(KneeLifeBleException("Error en connectar al KneeLife."));
          }
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    await Future.delayed(const Duration(seconds: 10));
    if (!found && !completer.isCompleted) {
      _emitState(BleConnectionState.disconnected);
      _scanSubscription?.cancel();
      completer.completeError(KneeLifeBleException("Dispositiu KneeLife no trobat. Assegura't que està encès i a prop."));
    }

    return completer.future;
  }

  void _startNotifications() async {
    if (_characteristic == null) return;
    await _characteristic!.setNotifyValue(true);
    
    _valueSubscription = _characteristic!.lastValueStream.listen((value) {
      if (value.isEmpty) return;
      String rawString = utf8.decode(value).trim();

      // Excepcions especificades al document de text
      if (rawString == "CALIBRAT") return;
      if (rawString.startsWith("Esperant")) return;

      try {
        final parts = rawString.split(',');
        if (parts.length >= 3) {
          final double alpha = double.parse(parts[0]);
          _angleController.add(alpha);
        }
      } catch (_) {
        // Ignorem fallades de parseig puntuals
      }
    });

    _device?.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _emitState(BleConnectionState.disconnected);
        _valueSubscription?.cancel();
      }
    });
  }

  Future<void> sendCalibrate() async {
    if (_characteristic == null || _currentState != BleConnectionState.connected) {
      throw KneeLifeBleException("No hi ha connexió BLE activa.");
    }
    await _characteristic!.write(utf8.encode("CALIBRAR"), withoutResponse: false);
  }

  Future<void> disconnect() async {
    _valueSubscription?.cancel();
    _scanSubscription?.cancel();
    await _device?.disconnect();
    _device = null;
    _characteristic = null;
    _emitState(BleConnectionState.disconnected);
  }

  void dispose() {
    _valueSubscription?.cancel();
    _scanSubscription?.cancel();
    _angleController.close();
    _connectionController.close();
  }
}