import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';
import '../models/settings_data.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();
  String? _uid;

  /// Login using Firebase Email/Password
  Future<void> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _uid = result.user?.uid;
    print("Logged in with UID: $_uid");
  }

  /// Get device ID (UID), fallback for testing
  String get deviceId => _uid ?? "dAxXdU5e4PVqpvre1iXZWIWRl5k1";

  /// Firebase DB ref for current device
  DatabaseReference get _deviceRef => _db.child("devices").child(deviceId);

  /// Fetch live sensor data
  Future<SensorData?> fetchSensorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No logged in user");
      return null;
    }

    final ref = _db.child("devices").child(user.uid).child("sensors");
    final snapshot = await ref.get();
    print("Sensor snapshot: ${snapshot.value}");

    if (!snapshot.exists || snapshot.value == null) {
      print("No sensor data found for user: ${user.uid}");
      return null;
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    return SensorData(
      temperature: (data['temperature'] ?? 0).toDouble(),
      humidity: (data['humidity'] ?? 0).toInt(),
      co2: (data['co2'] ?? 0).toInt(),
      timestamp: (data['timestamp'] ?? 0).toInt(),
    );
  }

  /// Fetch settings + modes
  Future<SettingsData?> fetchSettingsData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No logged in user");
      return null;
    }

    final settingsRef = _db.child("devices").child(user.uid).child("settings");
    final modesRef = _db.child("devices").child(user.uid).child("modes");

    final settingsSnap = await settingsRef.get();
    final modesSnap = await modesRef.get();

    print("Settings snapshot: ${settingsSnap.value}");
    print("Modes snapshot: ${modesSnap.value}");

    if (!settingsSnap.exists || settingsSnap.value == null) {
      print("No settings data found for user: ${user.uid}");
      return null;
    }

    final settingsData = Map<String, dynamic>.from(settingsSnap.value as Map);
    final modesData = modesSnap.exists && modesSnap.value != null
        ? Map<String, dynamic>.from(modesSnap.value as Map)
        : {};

    return SettingsData(
      tempUp: (settingsData['temp_up'] ?? settingsData['tempUp'] ?? 0).toDouble(),
      tempDown: (settingsData['temp_down'] ?? settingsData['tempDown'] ?? 0).toDouble(),
      humUp: (settingsData['hum_up'] ?? settingsData['humUp'] ?? 0).toInt(),
      humDown: (settingsData['hum_down'] ?? settingsData['humDown'] ?? 0).toInt(),
      coUp: (settingsData['co_up'] ?? settingsData['coUp'] ?? 0).toInt(),
      coDown: (settingsData['co_down'] ?? settingsData['coDown'] ?? 0).toInt(),
      rejimTemp: (modesData['rejim_temp'] ?? modesData['rejimTemp'] ?? false),
      rejimHum: (modesData['rejim_hum'] ?? modesData['rejimHum'] ?? false),
      rejimCo: (modesData['rejim_co'] ?? modesData['rejimCo'] ?? false),
    );
  }

  /// Save updated settings + modes
  Future<void> updateSettings(SettingsData data) async {
    print("Updating settings: ${data.toSettingsMap()}");
    print("Updating modes: ${data.toModesMap()}");
    await _deviceRef.child("settings").set(data.toSettingsMap());
    await _deviceRef.child("modes").set(data.toModesMap());
  }

  /// Check last sensor timestamp
  Future<int?> getLastTimestamp() async {
    final snapshot = await _deviceRef.child("sensors/timestamp").once();
    print("Last timestamp snapshot: ${snapshot.snapshot.value}");
    return snapshot.snapshot.value as int?;
  }
}
