class SettingsData {
  int tempUp;
  int tempDown;
  int humUp;
  int humDown;
  int coUp;
  int coDown;
  bool rejimTemp;
  bool rejimHum;
  bool rejimCo;

  SettingsData({
    required this.tempUp,
    required this.tempDown,
    required this.humUp,
    required this.humDown,
    required this.coUp,
    required this.coDown,
    required this.rejimTemp,
    required this.rejimHum,
    required this.rejimCo,
  });

  factory SettingsData.fromMap(Map<String, dynamic> settings, Map<String, dynamic> modes) {
    return SettingsData(
      tempUp: settings['temp_up'] ?? 0,
      tempDown: settings['temp_down'] ?? 0,
      humUp: settings['hum_up'] ?? 0,
      humDown: settings['hum_down'] ?? 0,
      coUp: settings['co_up'] ?? 0,
      coDown: settings['co_down'] ?? 0,
      rejimTemp: modes['rejim_temp'] ?? false,
      rejimHum: modes['rejim_hum'] ?? false,
      rejimCo: modes['rejim_co'] ?? false,
    );
  }

  Map<String, dynamic> toSettingsMap() {
    return {
      'temp_up': tempUp,
      'temp_down': tempDown,
      'hum_up': humUp,
      'hum_down': humDown,
      'co_up': coUp,
      'co_down': coDown,
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
