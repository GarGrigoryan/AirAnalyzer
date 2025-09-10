import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // Nordic UART custom UUIDs (used for ESP32 BLE UART)
  final Uuid serviceUuid = Uuid.parse("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  final Uuid wifiCharUuid = Uuid.parse("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");

  DiscoveredDevice? _device;
  QualifiedCharacteristic? _wifiChar;

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;

  /// 🔍 Scan for ESP32 devices with the custom service UUID
  Future<List<DiscoveredDevice>> scanForDevices() async {
    final devices = <DiscoveredDevice>[];

    // Request permissions
    final permissions = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    if (permissions.values.any((p) => !p.isGranted)) {
      print("BLE permissions not granted");
      return devices;
    }

    // Cancel previous scan
    await _scanSubscription?.cancel();

    final completer = Completer<List<DiscoveredDevice>>();

    _scanSubscription = _ble.scanForDevices(
      withServices: [serviceUuid], // only ESP32 devices exposing this service
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      // Avoid duplicates
      if (!devices.any((d) => d.id == device.id)) {
        devices.add(device);
      }
    }, onError: (e) {
      print("Scan error: $e");
      completer.completeError(e);
    });

    // Scan for 4 seconds then stop
    Future.delayed(const Duration(seconds: 4), () async {
      await _scanSubscription?.cancel();
      completer.complete(devices);
    });

    return completer.future;
  }

  /// ⏹ Stop scanning manually
  void stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  /// 🔗 Connect to a discovered device
  Future<void> connectToDevice(DiscoveredDevice device) async {
    _device = device;

    await _connectionSubscription?.cancel();

    _connectionSubscription = _ble.connectToDevice(
      id: device.id,
      servicesWithCharacteristicsToDiscover: {
        serviceUuid: [wifiCharUuid],
      },
      connectionTimeout: const Duration(seconds: 10),
    ).listen((state) {
      print('Connection state: ${state.connectionState}');
      if (state.connectionState == DeviceConnectionState.connected) {
        _wifiChar = QualifiedCharacteristic(
          serviceId: serviceUuid,
          characteristicId: wifiCharUuid,
          deviceId: device.id,
        );
        print("✅ Device connected, characteristic ready.");
      }
    }, onError: (e) {
      print("Connection error: $e");
      _device = null;
      _wifiChar = null;
    });
  }

  /// 📡 Send WiFi credentials in "ssid|password" format
  Future<void> sendWifiCredentials(String ssid, String password) async {
    if (_wifiChar == null) {
      throw Exception("WiFi characteristic not found or not connected");
    }

    final String data = "$ssid|$password";
    final List<int> bytes = utf8.encode(data);

    await _ble.writeCharacteristicWithResponse(
      _wifiChar!,
      value: bytes,
    );

    print("📤 WiFi credentials sent: $data");
  }

  /// 🧹 Dispose resources
  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _device = null;
    _wifiChar = null;
  }
}
