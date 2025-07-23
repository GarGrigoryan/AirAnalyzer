class SensorData {
  final double temperature; // changed to double for float values
  final int humidity;
  final int co2;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.co2,
  });

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: map['humidity'] ?? 0,
      co2: map['co2'] ?? 0,
    );
  }
}
