import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  // Singleton pattern
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  final Uuid serviceUuid = Uuid.parse("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  final Uuid ssidCharUuid = Uuid.parse("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
  final Uuid passCharUuid = Uuid.parse("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");

  DiscoveredDevice? _device;
  QualifiedCharacteristic? _ssidChar;
  QualifiedCharacteristic? _passChar;

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;

  /// Start scanning and connect to first matching device with service UUID
  Future<void> connect() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      print('Location permission denied');
      return;
    }

    await _scanSubscription?.cancel();
    _scanSubscription = _ble.scanForDevices(
      withServices: [serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (device.name.isNotEmpty) {
        _device = device;
        _scanSubscription?.cancel();
        print('Found device: ${device.name}, connecting...');
        _connectToDevice();
      }
    });
  }

  /// Internal connect helper
  void _connectToDevice() {
    if (_device == null) {
      print('No device found to connect');
      return;
    }

    _connectionSubscription?.cancel();
    _connectionSubscription = _ble.connectToDevice(
      id: _device!.id,
      servicesWithCharacteristicsToDiscover: {
        serviceUuid: [ssidCharUuid, passCharUuid],
      },
    ).listen((state) {
      print('Connection state: ${state.connectionState}');
      if (state.connectionState == DeviceConnectionState.connected) {
        _ssidChar = QualifiedCharacteristic(
          serviceId: serviceUuid,
          characteristicId: ssidCharUuid,
          deviceId: _device!.id,
        );

        _passChar = QualifiedCharacteristic(
          serviceId: serviceUuid,
          characteristicId: passCharUuid,
          deviceId: _device!.id,
        );

        print('Device connected, ready to send data.');
      } else if (state.connectionState == DeviceConnectionState.disconnected) {
        print('Device disconnected');
        _device = null;
        _ssidChar = null;
        _passChar = null;
      }
    });
  }

  /// Send WiFi credentials over BLE (connects if not connected)
  Future<void> sendWifiCredentials(String ssid, String password) async {
    if (_device == null || _ssidChar == null || _passChar == null) {
      print('Device not connected, attempting to connect first...');
      await connect();
      // Wait a moment for connection to establish
      await Future.delayed(const Duration(seconds: 3));
    }
    if (_ssidChar == null || _passChar == null) {
      print('BLE characteristics not found, cannot send credentials.');
      return;
    }

    try {
      await _ble.writeCharacteristicWithResponse(_ssidChar!, value: utf8.encode(ssid));
      await _ble.writeCharacteristicWithResponse(_passChar!, value: utf8.encode(password));
      print('WiFi credentials sent successfully via BLE.');

      // Disconnect after sending
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      _device = null;
      _ssidChar = null;
      _passChar = null;
    } catch (e) {
      print('Error sending WiFi credentials via BLE: $e');
    }
  }

  /// Dispose all subscriptions (call when needed)
  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await _connectionSubscription?.cancel();
  }
}
