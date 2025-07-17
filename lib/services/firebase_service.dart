import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';
import '../models/settings_data.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.reference();
  String? _uid;

  /// Login using Firebase Email/Password
  Future<void> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _uid = result.user?.uid;
  }

  /// Returns the current device ID (UID)
  String get deviceId => _uid ?? "dAxXdU5e4PVqpvre1iXZWIWRl5k1"; // fallback for testing

  /// Shortcut to device reference in database
  DatabaseReference get _deviceRef => _db.child("devices").child(deviceId);

  /// Fetch live sensor data
  Future<SensorData?> fetchSensorData() async {
  final snapshot = await _deviceRef.child("sensors").once();
  if (snapshot.snapshot.value == null) {
    print('No sensor data found');
    return null;
  }
  final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
  return SensorData.fromMap(data);
}

  /// Fetch both settings and modes as SettingsData
  Future<SettingsData?> fetchSettingsData() async {
  final settingsSnap = await _deviceRef.child("settings").once();
  final modesSnap = await _deviceRef.child("modes").once();

  if (settingsSnap.snapshot.value == null || modesSnap.snapshot.value == null) {
    print('No settings or modes data found');
    return null;
  }

  final settings = Map<String, dynamic>.from(settingsSnap.snapshot.value as Map);
  final modes = Map<String, dynamic>.from(modesSnap.snapshot.value as Map);
  return SettingsData.fromMap(settings, modes);
}

  /// Update settings and modes in Firebase
  Future<void> updateSettings(SettingsData settings) async {
    await _deviceRef.child("settings").set(settings.toSettingsMap());
    await _deviceRef.child("modes").set(settings.toModesMap());
  }

  /// Get last sensor timestamp (for offline detection)
  Future<int?> getLastTimestamp() async {
    final snapshot = await _deviceRef.child("sensors/timestamp").once();
    return snapshot.snapshot.value as int?;
  }

  /// Used by widgets or services that expect this structure
  Future<SensorData> getSensorData(String deviceId) async {
    final ref = _db.child('devices/$deviceId/sensors');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return SensorData.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
    } else {
      throw Exception('Sensor data not found');
    }
  }

  Future<SettingsData> getSettingsData(String deviceId) async {
    final settingsSnap = await _db.child('devices/$deviceId/settings').get();
    final modesSnap = await _db.child('devices/$deviceId/modes').get();

    if (settingsSnap.exists && modesSnap.exists) {
      final settings = Map<String, dynamic>.from(settingsSnap.value as Map);
      final modes = Map<String, dynamic>.from(modesSnap.value as Map);
      return SettingsData.fromMap(settings, modes);
    } else {
      throw Exception('Settings or modes not found');
    }
  }

  Future<void> updateSettingsData(String deviceId, SettingsData data) async {
    await _db.child('devices/$deviceId/settings').set(data.toSettingsMap());
    await _db.child('devices/$deviceId/modes').set(data.toModesMap());
  }
}
