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

  final Uuid serviceUuid = Uuid.parse("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  final Uuid wifiCharUuid = Uuid.parse("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");

  DiscoveredDevice? _device;
  QualifiedCharacteristic? _wifiChar;

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;

  void startScan(void Function(DiscoveredDevice) onDeviceFound) async {
    final status = await Permission.location.request();
    if (!status.isGranted) return;

    await _scanSubscription?.cancel();
    _scanSubscription = _ble.scanForDevices(
      withServices: [serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen(onDeviceFound);
  }

  void stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  Future<void> connectToDevice(String deviceId) async {
    _connectionSubscription?.cancel();

    _device ??= DiscoveredDevice(
      id: deviceId,
      name: "",
      serviceData: {},
      rssi: 0,
      manufacturerData: Uint8List(0),
      serviceUuids: [],
    );

    _connectionSubscription = _ble.connectToDevice(
      id: _device!.id,
      servicesWithCharacteristicsToDiscover: {
        serviceUuid: [wifiCharUuid],
      },
    ).listen((state) {
      print('Connection state: ${state.connectionState}');
      if (state.connectionState == DeviceConnectionState.connected) {
        _wifiChar = QualifiedCharacteristic(
          serviceId: serviceUuid,
          characteristicId: wifiCharUuid,
          deviceId: _device!.id,
        );
        print('Device connected, ready to send data.');
      } else if (state.connectionState == DeviceConnectionState.disconnected) {
        print('Device disconnected');
        _device = null;
        _wifiChar = null;
      }
    });
  }

  Future<void> sendWifiCredentials(String ssid, String password) async {
    if (_device == null || _wifiChar == null) {
      print('Device not connected, attempting to connect first...');
      await connectToDevice(_device?.id ?? "");
      await Future.delayed(const Duration(seconds: 3));
    }

    if (_wifiChar == null) {
      print('BLE characteristic not found, cannot send credentials.');
      return;
    }

    try {
      String combined = "$ssid|$password";
      await _ble.writeCharacteristicWithResponse(
        _wifiChar!,
        value: utf8.encode(combined),
      );
      print('WiFi credentials sent in one packet via BLE.');

      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      _device = null;
      _wifiChar = null;
    } catch (e) {
      print('Error sending WiFi credentials via BLE: $e');
    }
  }

  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await _connectionSubscription?.cancel();
  }
}
