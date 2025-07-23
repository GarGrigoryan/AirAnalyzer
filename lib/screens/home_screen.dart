import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/ble_service.dart';
import '../models/sensor_data.dart';
import '../models/settings_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final BleService _bleService = BleService();

  SensorData? _sensorData;
  SettingsData? _settingsData;
  bool _showSettings = false;

  final _ssidController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
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

  void _sendWifiViaBLE() async {
    final ssid = _ssidController.text.trim();
    final password = _passController.text.trim();
    if (ssid.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter SSID and Password")),
      );
      return;
    }

    await _bleService.sendWifiCredentials(ssid, password);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("WiFi credentials sent via BLE")),
    );
  }

  void _connectBLE() async {
    await _bleService.connect();
  }

  void _saveSettings() async {
    if (_settingsData != null) {
      print("Saving settings: $_settingsData");
      await _firebaseService.updateSettings(_settingsData!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Settings updated")),
      );
    }
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Defensive: provide default SensorData & SettingsData if null
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Air Analyzer"),
        actions: [
          IconButton(onPressed: _connectBLE, icon: const Icon(Icons.bluetooth)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
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
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
              child: Text(_showSettings ? "Hide Settings" : "Show Settings"),
            ),
            if (_showSettings)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Temp Up
                  Text("Temp Up: ${settings.tempUp}"),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (settings.tempUp > 0) {
                            setState(() {
                              settings.tempUp--;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            settings.tempUp++;
                          });
                        },
                      ),
                    ],
                  ),

                  // Temp Down
                  Text("Temp Down: ${settings.tempDown}"),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (settings.tempDown > 0) {
                            setState(() {
                              settings.tempDown--;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            settings.tempDown++;
                          });
                        },
                      ),
                    ],
                  ),

                  // Humidity Up
                  Text("Humidity Up: ${settings.humUp}"),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (settings.humUp > 0) {
                            setState(() {
                              settings.humUp--;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            settings.humUp++;
                          });
                        },
                      ),
                    ],
                  ),

                  // Humidity Down
                  Text("Humidity Down: ${settings.humDown}"),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (settings.humDown > 0) {
                            setState(() {
                              settings.humDown--;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            settings.humDown++;
                          });
                        },
                      ),
                    ],
                  ),

                  // CO2 Up
                  Text("CO₂ Up: ${settings.coUp}"),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (settings.coUp > 0) {
                            setState(() {
                              settings.coUp--;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            settings.coUp++;
                          });
                        },
                      ),
                    ],
                  ),

                  // CO2 Down
                  Text("CO₂ Down: ${settings.coDown}"),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (settings.coDown > 0) {
                            setState(() {
                              settings.coDown--;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            settings.coDown++;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text("Auto Temperature"),
                    value: settings.rejimTemp,
                    onChanged: (val) {
                      setState(() {
                        settings.rejimTemp = val;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text("Auto Humidity"),
                    value: settings.rejimHum,
                    onChanged: (val) {
                      setState(() {
                        settings.rejimHum = val;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text("Auto CO₂"),
                    value: settings.rejimCo,
                    onChanged: (val) {
                      setState(() {
                        settings.rejimCo = val;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text("Save Settings"),
                  ),
                ],
              ),

            const Divider(height: 40),
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(labelText: "WiFi SSID"),
            ),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(labelText: "WiFi Password"),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendWifiViaBLE,
              child: const Text("Send WiFi to ESP32 via BLE"),
            ),
          ],
        ),
      ),
    );
  }
}
