import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';
import '../models/settings_data.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref(); // Use ref() instead of reference()
  String? _uid;

  /// Login using Firebase Email/Password
  Future<void> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _uid = result.user?.uid;
  }

  /// Get device ID (UID), fallback for testing
  String get deviceId => _uid ?? "dAxXdU5e4PVqpvre1iXZWIWRl5k1";

  /// Firebase DB ref for current device
  DatabaseReference get _deviceRef => _db.child("devices").child(deviceId);

  /// Fetch live sensor data
  Future<SensorData?> fetchSensorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final deviceId = user.uid; // Assuming device ID == Firebase UID
    final ref = FirebaseDatabase.instance.ref('devices/$deviceId/sensors');

    final snapshot = await ref.get();
    if (!snapshot.exists) {
      print("No sensor data found for user: $deviceId");
      return null;
    }

    final data = snapshot.value as Map;

    return SensorData(
      temperature: (data['temperature'] ?? 0).toDouble(),
      humidity: (data['humidity'] ?? 0).toInt(),
      co2: (data['co2'] ?? 0).toInt(),
      timestamp: (data['timestamp'] ?? 0).toInt(),
    );
  }

  /// Fetch both settings and modes
  Future<SettingsData?> fetchSettingsData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final deviceId = user.uid;
  final ref = FirebaseDatabase.instance.ref('devices/$deviceId/settings');

  final snapshot = await ref.get();
  if (!snapshot.exists) {
    print("No settings data found for user: $deviceId");
    return null;
  }

  final data = snapshot.value as Map;

  return SettingsData(
    tempUp: (data['temp_up'] ?? data['tempUp'] ?? 0).toInt(),
    tempDown: (data['temp_down'] ?? data['tempDown'] ?? 0).toInt(),
    humUp: (data['hum_up'] ?? data['humUp'] ?? 0).toInt(),
    humDown: (data['hum_down'] ?? data['humDown'] ?? 0).toInt(),
    coUp: (data['co_up'] ?? data['coUp'] ?? 0).toInt(),
    coDown: (data['co_down'] ?? data['coDown'] ?? 0).toInt(),
    rejimTemp: (data['rejim_temp'] ?? false),
    rejimHum: (data['rejim_hum'] ?? false),
    rejimCo: (data['rejim_co'] ?? false),
  );
}


  /// Save updated settings + modes
  Future<void> updateSettings(SettingsData data) async {
    await _deviceRef.child("settings").set(data.toSettingsMap());
    await _deviceRef.child("modes").set(data.toModesMap());
  }

  /// Used to check last timestamp of sensor update
  Future<int?> getLastTimestamp() async {
    final snapshot = await _deviceRef.child("sensors/timestamp").once();
    return snapshot.snapshot.value as int?;
  }
}
