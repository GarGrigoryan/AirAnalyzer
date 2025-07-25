import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/ble_service.dart';
import '../models/sensor_data.dart';
import '../models/settings_data.dart';
import 'dart:async';

String _formatTimeAgo(int? timestamp) {
  if (timestamp == null) return 'Never';
  
  final now = DateTime.now().millisecondsSinceEpoch;
  final timestampMs = timestamp * 1000;
  final difference = now - timestampMs;
  
  if (difference < 60000) {
    return 'Just now';
  } else if (difference < 3600000) {
    return '${(difference / 60000).round()}m ago';
  } else if (difference < 86400000) {
    return '${(difference / 3600000).round()}h ago';
  } else {
    return '${(difference / 86400000).round()}d ago';
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final BleService _bleService = BleService();

  Timer? _updateTimer;

  SensorData? _sensorData;
  SettingsData? _settingsData;
  bool _showSettings = false;

  // Controllers for numeric input fields
  final TextEditingController _tempUpController = TextEditingController();
  final TextEditingController _tempDownController = TextEditingController();
  final TextEditingController _humUpController = TextEditingController();
  final TextEditingController _humDownController = TextEditingController();
  final TextEditingController _coUpController = TextEditingController();
  final TextEditingController _coDownController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoUpdate();
  }

  void _startAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  bool _isDataFresh(int? timestamp) {
    if (timestamp == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final timestampMs = timestamp * 1000;
    return (now - timestampMs) < 5 * 60 * 1000; // 5 minutes in milliseconds
  }

  Future<void> _loadData() async {
    try {
      print("Loading sensor data from Firebase...");
      final sensor = await _firebaseService.fetchSensorData();
      print("Sensor data fetched: $sensor");

      print("Loading settings data from Firebase...");
      final settings = await _firebaseService.fetchSettingsData();
      print("Settings data fetched: $settings");

      if (mounted) {
        setState(() {
          _sensorData = sensor;
          _settingsData = settings;
          // Initialize controllers with current values
          _tempUpController.text = settings?.tempUp.toString() ?? '0';
          _tempDownController.text = settings?.tempDown.toString() ?? '0';
          _humUpController.text = settings?.humUp.toString() ?? '0';
          _humDownController.text = settings?.humDown.toString() ?? '0';
          _coUpController.text = settings?.coUp.toString() ?? '0';
          _coDownController.text = settings?.coDown.toString() ?? '0';
        });
      }
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, "/login");
  }

  void _connectBLE() async {
    await _bleService.connect();
  }

  void _saveSettings() async {
    if (_settingsData != null) {
      // Update settings from text fields
      _settingsData!.tempUp = int.tryParse(_tempUpController.text) ?? 0;
      _settingsData!.tempDown = int.tryParse(_tempDownController.text) ?? 0;
      _settingsData!.humUp = int.tryParse(_humUpController.text) ?? 0;
      _settingsData!.humDown = int.tryParse(_humDownController.text) ?? 0;
      _settingsData!.coUp = int.tryParse(_coUpController.text) ?? 0;
      _settingsData!.coDown = int.tryParse(_coDownController.text) ?? 0;

      print("Saving settings: $_settingsData");
      await _firebaseService.updateSettings(_settingsData!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Settings updated")),
      );
    }
  }

  void _showWifiDialog() {
    final ssidController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Send WiFi Credentials"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ssidController,
                decoration: const InputDecoration(
                  labelText: "WiFi SSID",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passController,
                decoration: const InputDecoration(
                  labelText: "WiFi Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final ssid = ssidController.text.trim();
                final password = passController.text.trim();
                
                if (ssid.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter SSID and Password")),
                  );
                  return;
                }
                
                Navigator.pop(context);
                await _bleService.sendWifiCredentials(ssid, password);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("WiFi credentials sent via BLE")),
                );
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _stopAutoUpdate();
    _tempUpController.dispose();
    _tempDownController.dispose();
    _humUpController.dispose();
    _humDownController.dispose();
    _coUpController.dispose();
    _coDownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensor = _sensorData ?? SensorData(temperature: 0, humidity: 0, co2: 0);
    final settings = _settingsData ??
        SettingsData(
          tempUp: 0,
          tempDown: 0,
          humUp: 0,
          humDown: 0,
          coUp: 0,
          coDown: 0,
          rejimTemp: false,
          rejimHum: false,
          rejimCo: false,
        );

    final isFresh = _isDataFresh(sensor.timestamp);
    final timeText = _formatTimeAgo(sensor.timestamp);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Air Analyzer"),
        actions: [
          IconButton(
            onPressed: _showWifiDialog,
            icon: const Icon(Icons.wifi),
            tooltip: "Send WiFi credentials",
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            }, 
            icon: const Icon(Icons.settings), 
            tooltip: "Settings",
          ),
          IconButton(
            onPressed: _connectBLE, 
            icon: const Icon(Icons.bluetooth),
            tooltip: "Connect BLE",
          ),
          IconButton(
            onPressed: _logout, 
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    "Temperature: ${sensor.temperature.toStringAsFixed(1)} °C",
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 10),
                  Text("Humidity: ${sensor.humidity} %", style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 10),
                  Text("CO₂: ${sensor.co2} ppm", style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi,
                        color: isFresh ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeText,
                        style: TextStyle(
                          color: isFresh ? Colors.green : Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_showSettings)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Temperature Up (replaced with text field)
                  const Text("Temperature Up:"),
                  TextField(
                    controller: _tempUpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter value',
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Temperature Down (replaced with text field)
                  const Text("Temperature Down:"),
                  TextField(
                    controller: _tempDownController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter value',
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Humidity Up (replaced with text field)
                  const Text("Humidity Up:"),
                  TextField(
                    controller: _humUpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter value',
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Humidity Down (replaced with text field)
                  const Text("Humidity Down:"),
                  TextField(
                    controller: _humDownController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter value',
                    ),
                  ),

                  const SizedBox(height: 15),

                  // CO₂ Up (replaced with text field)
                  const Text("CO₂ Up:"),
                  TextField(
                    controller: _coUpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter value',
                    ),
                  ),

                  const SizedBox(height: 15),

                  // CO₂ Down (replaced with text field)
                  const Text("CO₂ Down:"),
                  TextField(
                    controller: _coDownController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter value',
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Auto Temperature (replaced with dropdown)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Auto Temperature',
                      border: OutlineInputBorder(),
                    ),
                    value: settings.rejimTemp ? 'H' : 'C',
                    items: const [
                      DropdownMenuItem(value: 'H', child: Text('H')),
                      DropdownMenuItem(value: 'C', child: Text('C')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        settings.rejimTemp = value == 'H';
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  // Auto Humidity (replaced with dropdown)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Auto Humidity',
                      border: OutlineInputBorder(),
                    ),
                    value: settings.rejimHum ? 'H' : 'C',
                    items: const [
                      DropdownMenuItem(value: 'H', child: Text('H')),
                      DropdownMenuItem(value: 'C', child: Text('C')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        settings.rejimHum = value == 'H';
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  // Auto CO₂ (replaced with dropdown)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Auto CO₂',
                      border: OutlineInputBorder(),
                    ),
                    value: settings.rejimCo ? 'H' : 'C',
                    items: const [
                      DropdownMenuItem(value: 'H', child: Text('H')),
                      DropdownMenuItem(value: 'C', child: Text('C')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        settings.rejimCo = value == 'H';
                      });
                    },
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text("Save Settings"),
                  ),
                ],
              ),          
          ],
        ),
      ),
    );
  }
}