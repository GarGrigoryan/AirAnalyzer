class SettingsData {
  final int coUp;
  final int coDown;
  final int humUp;
  final int humDown;
  final bool rejimCo;
  final bool rejimHum;
  final bool rejimTemp;

  SettingsData({
    required this.coUp,
    required this.coDown,
    required this.humUp,
    required this.humDown,
    required this.rejimCo,
    required this.rejimHum,
    required this.rejimTemp,
  });

  SettingsData copyWith({
  int? coUp,
  int? coDown,
  int? humUp,
  int? humDown,
  bool? rejimCo,
  bool? rejimHum,
  bool? rejimTemp,
}) {
  return SettingsData(
    coUp: coUp ?? this.coUp,
    coDown: coDown ?? this.coDown,
    humUp: humUp ?? this.humUp,
    humDown: humDown ?? this.humDown,
    rejimCo: rejimCo ?? this.rejimCo,
    rejimHum: rejimHum ?? this.rejimHum,
    rejimTemp: rejimTemp ?? this.rejimTemp,
  );
}

  factory SettingsData.fromMap(Map<String, dynamic> settings, Map<String, dynamic> modes) {
    return SettingsData(
      coUp: settings['co_up'] ?? 0,
      coDown: settings['co_down'] ?? 0,
      humUp: settings['hum_up'] ?? 0,
      humDown: settings['hum_down'] ?? 0,
      rejimCo: modes['rejim_co'] ?? false,
      rejimHum: modes['rejim_hum'] ?? false,
      rejimTemp: modes['rejim_temp'] ?? false,
    );
  }

  Map<String, dynamic> toSettingsMap() {
    return {
      'co_up': coUp,
      'co_down': coDown,
      'hum_up': humUp,
      'hum_down': humDown,
      'rejim_co': rejimCo,
      'rejim_hum': rejimHum,
    };
  }

  Map<String, dynamic> toModesMap() {
    return {
      'rejim_temp': rejimTemp,
      'rejim_hum': rejimHum,
      'rejim_co': rejimCo,
    };
  }
}
