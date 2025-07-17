import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  final _ble = FlutterReactiveBle();

  final Uuid serviceUuid = Uuid.parse("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  final Uuid ssidCharUuid = Uuid.parse("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
  final Uuid passCharUuid = Uuid.parse("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");

  late DiscoveredDevice _device;
  late QualifiedCharacteristic _ssidChar;
  late QualifiedCharacteristic _passChar;

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;

  Future<void> sendWifiCredentials(String ssid, String password) async {
    await Permission.location.request();
    if (!await Permission.location.isGranted) return;

    _scanSubscription = _ble.scanForDevices(withServices: [serviceUuid], scanMode: ScanMode.lowLatency).listen((device) {
      if (device.name.isNotEmpty) {
        _device = device;
        _scanSubscription?.cancel();
        _connectAndSend(ssid, password);
      }
    });
  }

  Future<void> _connectAndSend(String ssid, String password) async {
    _connectionSubscription = _ble.connectToDevice(
      id: _device.id,
      servicesWithCharacteristicsToDiscover: {
        serviceUuid: [ssidCharUuid, passCharUuid],
      },
    ).listen((state) async {
      if (state.connectionState == DeviceConnectionState.connected) {
        _ssidChar = QualifiedCharacteristic(
          serviceId: serviceUuid,
          characteristicId: ssidCharUuid,
          deviceId: _device.id,
        );

        _passChar = QualifiedCharacteristic(
          serviceId: serviceUuid,
          characteristicId: passCharUuid,
          deviceId: _device.id,
        );

        await _ble.writeCharacteristicWithResponse(_ssidChar, value: utf8.encode(ssid));
        await _ble.writeCharacteristicWithResponse(_passChar, value: utf8.encode(password));

        await _connectionSubscription?.cancel();
      }
    });
  }
}
