import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  final String serviceUuid = "4fafc201-1fb5-459e-8fcc-010101010101"; //
  final String charUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";    //

  final StreamController<double> _angleController = StreamController<double>.broadcast();
  Stream<double> get angleStream => _angleController.stream;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;

  Future<void> connect() async {
    await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    
    late StreamSubscription<List<ScanResult>> subscription;
    subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == "KneeLife") { //
          await FlutterBluePlus.stopScan();
          _device = r.device;
          await _device!.connect();
          _discoverServices();
          await subscription.cancel(); 
          break;
        }
      }
    });
  }

  void _discoverServices() async {
    List<BluetoothService> services = await _device!.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == serviceUuid) {
        for (var char in service.characteristics) {
          if (char.uuid.toString() == charUuid) {
            _characteristic = char;
            await _characteristic!.setNotifyValue(true);
            _characteristic!.lastValueStream.listen((value) {
              _parseData(utf8.decode(value));
            });
          }
        }
      }
    }
  }

  void _parseData(String rawString) {
    if (rawString == "CALIBRAT" || rawString.contains("Esperant")) return;
    final parts = rawString.split(',');
    if (parts.length >= 3) {
      _angleController.add(double.tryParse(parts[0]) ?? 0.0);
    }
  }
}