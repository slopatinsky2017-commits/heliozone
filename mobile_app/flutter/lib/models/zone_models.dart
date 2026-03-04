class Device {
  const Device({
    required this.deviceId,
    required this.name,
    required this.host,
    required this.ip,
    required this.fw,
    required this.lastSeen,
  });

  final String deviceId;
  final String name;
  final String host;
  final String ip;
  final String fw;
  final DateTime lastSeen;

  String get baseUrl => 'http://$ip';

  Device copyWith({
    String? name,
    String? host,
    String? ip,
    String? fw,
    DateTime? lastSeen,
  }) {
    return Device(
      deviceId: deviceId,
      name: name ?? this.name,
      host: host ?? this.host,
      ip: ip ?? this.ip,
      fw: fw ?? this.fw,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'name': name,
        'host': host,
        'ip': ip,
        'fw': fw,
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        deviceId: json['deviceId']?.toString() ?? '',
        name: json['name']?.toString() ?? 'HelioZone',
        host: json['host']?.toString() ?? '',
        ip: json['ip']?.toString() ?? '',
        fw: json['fw']?.toString() ?? 'unknown',
        lastSeen: DateTime.tryParse(json['lastSeen']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class Zone {
  const Zone({
    required this.zoneId,
    required this.name,
    required this.deviceIds,
  });

  final String zoneId;
  final String name;
  final List<String> deviceIds;

  Zone copyWith({String? name, List<String>? deviceIds}) {
    return Zone(
      zoneId: zoneId,
      name: name ?? this.name,
      deviceIds: deviceIds ?? this.deviceIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'zoneId': zoneId,
        'name': name,
        'deviceIds': deviceIds,
      };

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
        zoneId: json['zoneId']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Zone',
        deviceIds: ((json['deviceIds'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );
}

class ZoneCommand {
  const ZoneCommand({
    this.mode,
    this.power,
    this.ppfdTarget,
    this.dliTarget,
    this.sunrise,
    this.sunset,
    this.white,
    this.blue,
    this.red,
    this.farRed,
  });

  final String? mode;
  final bool? power;
  final double? ppfdTarget;
  final double? dliTarget;
  final String? sunrise;
  final String? sunset;
  final double? white;
  final double? blue;
  final double? red;
  final double? farRed;
}

class DeviceCommandResult {
  const DeviceCommandResult({
    required this.deviceId,
    required this.deviceName,
    required this.success,
    this.error,
  });

  final String deviceId;
  final String deviceName;
  final bool success;
  final String? error;
}
