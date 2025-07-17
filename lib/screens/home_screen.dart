import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/sensor_data.dart';
import '../models/settings_data.dart';
import '../services/firebase_service.dart';
import '../services/ble_service.dart';
import '../widgets/sensor_card.dart';  // Make sure this exists and exports SensorCard widget

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebase = FirebaseService();
  final BleService _ble = BleService();

  SensorData? sensorData;
  SettingsData? settingsData;

  final ssidController = TextEditingController();
  final passController = TextEditingController();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchAll();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => fetchAll());
  }

  Future<void> fetchAll() async {
    try {
      final sensor = await _firebase.fetchSensorData();
      final settings = await _firebase.fetchSettingsData();

      setState(() {
        sensorData = sensor;
        settingsData = settings;
      });

      print('Fetched sensorData: $sensor');
      print('Fetched settingsData: $settings');
    } catch (e, stacktrace) {
      print('Error fetching data: $e');
      print(stacktrace);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    ssidController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (sensorData == null || settingsData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project X')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final ts = sensorData!.timestamp;
    final tsDate = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final timeAgo = timeago.format(tsDate, allowFromNow: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Project X')),
      body: RefreshIndicator(
        onRefresh: fetchAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SensorCard(
              label: 'Temperature',
              value: '${sensorData!.temperature}°C',
              icon: Icons.thermostat,
              color: Colors.redAccent,
            ),
            SensorCard(
              label: 'Humidity',
              value: '${sensorData!.humidity}%',
              icon: Icons.water_drop,
              color: Colors.blue,
            ),
            SensorCard(
              label: 'CO₂',
              value: '${sensorData!.co2} ppm',
              icon: Icons.cloud,
              color: Colors.green,
            ),
            Text('Last update: $timeAgo'),
            const SizedBox(height: 20),
            _buildSettingsForm(),
            const Divider(height: 32),
            _buildWifiSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsForm() {
    final s = settingsData!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        _buildNumberRow('CO₂ Up', s.coUp, (v) => setState(() => settingsData = s.copyWith(coUp: v))),
        _buildNumberRow('CO₂ Down', s.coDown, (v) => setState(() => settingsData = s.copyWith(coDown: v))),
        _buildNumberRow('Humidity Up', s.humUp, (v) => setState(() => settingsData = s.copyWith(humUp: v))),
        _buildNumberRow('Humidity Down', s.humDown, (v) => setState(() => settingsData = s.copyWith(humDown: v))),
        _buildSwitch('Temp Mode', s.rejimTemp, (v) => setState(() => settingsData = s.copyWith(rejimTemp: v))),
        _buildSwitch('Hum Mode', s.rejimHum, (v) => setState(() => settingsData = s.copyWith(rejimHum: v))),
        _buildSwitch('CO₂ Mode', s.rejimCo, (v) => setState(() => settingsData = s.copyWith(rejimCo: v))),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            await _firebase.updateSettings(settingsData!);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings saved")));
          },
          child: const Text('Save Settings'),
        )
      ],
    );
  }

  Widget _buildNumberRow(String label, int value, void Function(int) onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(icon: const Icon(Icons.remove), onPressed: () => onChanged(value - 1)),
        Text('$value'),
        IconButton(icon: const Icon(Icons.add), onPressed: () => onChanged(value + 1)),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, void Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildWifiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Wi‑Fi Provisioning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(controller: ssidController, decoration: const InputDecoration(labelText: 'SSID')),
        TextField(controller: passController, decoration: const InputDecoration(labelText: 'Password')),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            await _ble.sendWifiCredentials(ssidController.text.trim(), passController.text.trim());
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wi‑Fi sent over BLE")));
          },
          child: const Text('Send to ESP32 via BLE'),
        )
      ],
    );
  }
}
