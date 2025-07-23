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
    final snapshot = await _deviceRef.child("sensors").once();
    final data = snapshot.snapshot.value;
    if (data == null) {
      print('No sensor data found');
      return null;
    }
    return SensorData.fromMap(Map<String, dynamic>.from(data as Map));
  }

  /// Fetch both settings and modes
  Future<SettingsData?> fetchSettingsData() async {
    final settingsSnap = await _deviceRef.child("settings").once();
    final modesSnap = await _deviceRef.child("modes").once();

    final settings = settingsSnap.snapshot.value;
    final modes = modesSnap.snapshot.value;

    if (settings == null || modes == null) {
      print('No settings or modes found');
      return null;
    }

    return SettingsData.fromMap(
      Map<String, dynamic>.from(settings as Map),
      Map<String, dynamic>.from(modes as Map),
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
