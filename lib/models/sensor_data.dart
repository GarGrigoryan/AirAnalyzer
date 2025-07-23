class SensorData {
  final double temperature;
  final int humidity;
  final int co2;
  final int? timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.co2,
    this.timestamp,
  });

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: map['humidity'] ?? 0,
      co2: map['co2'] ?? 0,
      timestamp: map['timestamp']?.toInt(), 
    );
  }
}