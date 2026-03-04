class HealthData {
  final int uptime;
  final int heap;
  final int wifiRssi;
  final double temperatureC;
  final bool lastSensorOk;
  final int lastSensorOkAgeSeconds;
  final int lastNtpSync;
  final String otaLastResult;
  final bool degraded;

  const HealthData({
    required this.uptime,
    required this.heap,
    required this.wifiRssi,
    required this.temperatureC,
    required this.lastSensorOk,
    required this.lastSensorOkAgeSeconds,
    required this.lastNtpSync,
    required this.otaLastResult,
    required this.degraded,
  });

  factory HealthData.fromJson(Map<String, dynamic> json) {
    final src = (json['health'] is Map<String, dynamic>) ? (json['health'] as Map<String, dynamic>) : json;

    return HealthData(
      uptime: (src['uptime'] as num?)?.toInt() ?? 0,
      heap: (src['heap'] as num?)?.toInt() ?? 0,
      wifiRssi: (src['wifi_rssi'] as num?)?.toInt() ?? 0,
      temperatureC: (src['temperature_c'] as num?)?.toDouble() ?? -1,
      lastSensorOk: src['last_sensor_ok'] == true,
      lastSensorOkAgeSeconds: (src['last_sensor_ok_age_seconds'] as num?)?.toInt() ?? 0,
      lastNtpSync: (src['last_ntp_sync'] as num?)?.toInt() ?? 0,
      otaLastResult: src['ota_last_result']?.toString() ?? 'unknown',
      degraded: src['degraded'] == true,
    );
  }
}

class CloudData {
  final bool enabled;
  final int cloudiness;
  final double minFactor;
  final double maxFactor;
  final int avgIntervalS;
  final double currentFactor;
  final bool dipActive;

  const CloudData({
    required this.enabled,
    required this.cloudiness,
    required this.minFactor,
    required this.maxFactor,
    required this.avgIntervalS,
    required this.currentFactor,
    required this.dipActive,
  });

  factory CloudData.fromJson(Map<String, dynamic> json) {
    final src = (json['cloud'] is Map<String, dynamic>) ? (json['cloud'] as Map<String, dynamic>) : json;
    return CloudData(
      enabled: src['enabled'] == true,
      cloudiness: (src['cloudiness'] as num?)?.toInt() ?? 0,
      minFactor: (src['min_factor'] as num?)?.toDouble() ?? 0.7,
      maxFactor: (src['max_factor'] as num?)?.toDouble() ?? 0.95,
      avgIntervalS: (src['avg_interval_s'] as num?)?.toInt() ?? 180,
      currentFactor: (src['current_factor'] as num?)?.toDouble() ?? 1.0,
      dipActive: src['dip_active'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'cloudiness': cloudiness,
        'min_factor': minFactor,
        'max_factor': maxFactor,
        'avg_interval_s': avgIntervalS,
      };
}

class ParData {
  final double ppfd;
  final double target;

  const ParData({required this.ppfd, required this.target});

  factory ParData.fromJson(Map<String, dynamic> json) {
    return ParData(
      ppfd: (json['ppfd'] as num?)?.toDouble() ?? 0,
      target: (json['target'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DliData {
  final double currentDli;
  final double targetDli;

  const DliData({required this.currentDli, required this.targetDli});

  factory DliData.fromJson(Map<String, dynamic> json) {
    return DliData(
      currentDli: (json['current_dli'] as num?)?.toDouble() ?? 0,
      targetDli: (json['target_dli'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DeviceData {
  final String wifiStatus;
  final String ip;
  final String firmwareVersion;

  const DeviceData({
    required this.wifiStatus,
    required this.ip,
    required this.firmwareVersion,
  });
}

class TelemetryData {
  final double ppfd;
  final double dli;
  final double targetPpfd;
  final double targetDli;
  final double powerPercent;
  final String sunPhase;
  final int uptime;
  final int wifiRssi;
  final double cloudFactor;
  final int cloudiness;

  const TelemetryData({
    required this.ppfd,
    required this.dli,
    required this.targetPpfd,
    required this.targetDli,
    required this.powerPercent,
    required this.sunPhase,
    required this.uptime,
    required this.wifiRssi,
    required this.cloudFactor,
    required this.cloudiness,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      ppfd: (json['ppfd'] as num?)?.toDouble() ?? 0,
      dli: (json['dli'] as num?)?.toDouble() ?? 0,
      targetPpfd: (json['target_ppfd'] as num?)?.toDouble() ?? 0,
      targetDli: (json['target_dli'] as num?)?.toDouble() ?? 0,
      powerPercent: ((json['power_percent'] ?? json['led_power']) as num?)?.toDouble() ?? 0,
      sunPhase: json['sun_phase']?.toString() ?? 'day',
      uptime: (json['uptime'] as num?)?.toInt() ?? 0,
      wifiRssi: (json['wifi_rssi'] as num?)?.toInt() ?? 0,
      cloudFactor: (json['cloud_factor'] as num?)?.toDouble() ?? 1.0,
      cloudiness: (json['cloudiness'] as num?)?.toInt() ?? 0,
    );
  }
}

class StatusData {
  final double ledPower;
  final double sunBrightness;
  final ParData par;
  final DliData dli;
  final DeviceData device;
  final CloudData cloud;

  const StatusData({
    required this.ledPower,
    required this.sunBrightness,
    required this.par,
    required this.dli,
    required this.device,
    required this.cloud,
  });

  factory StatusData.fromJson(Map<String, dynamic> json) {
    final channels = (json['channels'] as Map<String, dynamic>?) ?? {};
    final sun = (json['sun'] as Map<String, dynamic>?) ?? {};
    final parJson = (json['par'] as Map<String, dynamic>?) ?? {};
    final dliJson = (json['dli'] as Map<String, dynamic>?) ?? {};
    final cloudJson = (json['cloud'] as Map<String, dynamic>?) ?? {};

    final white = (channels['white'] as num?)?.toDouble() ?? 0;
    final blue = (channels['blue'] as num?)?.toDouble() ?? 0;
    final red = (channels['red'] as num?)?.toDouble() ?? 0;
    final farRed = (channels['far_red'] as num?)?.toDouble() ?? 0;

    return StatusData(
      ledPower: (((white + blue + red + farRed) / 4).clamp(0, 100) as num).toDouble(),
      sunBrightness: (sun['brightness'] as num?)?.toDouble() ?? 0,
      par: ParData.fromJson(parJson),
      dli: DliData.fromJson(dliJson),
      cloud: CloudData.fromJson(cloudJson),
      device: DeviceData(
        wifiStatus: (json['wifi_connected'] == true) ? 'Connected' : 'Disconnected',
        ip: json['ip']?.toString() ?? '-',
        firmwareVersion: json['fw_version']?.toString() ?? 'unknown',
      ),
    );
  }
}
