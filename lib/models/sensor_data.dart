class SensorData {
  final double temperature;
  final double humidity;
  final int co2;
  final int timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.co2,
    required this.timestamp,
  });

  factory SensorData.fromMap(Map<String, dynamic> data) {
    return SensorData(
      temperature: (data['temperature'] ?? 0).toDouble(),
      humidity: (data['humidity'] ?? 0).toDouble(),
      co2: data['co2'] ?? 0,
      timestamp: data['timestamp'] ?? 0,
    );
  }
}
