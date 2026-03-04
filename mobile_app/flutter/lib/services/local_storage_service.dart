import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/zone_models.dart';

class LocalStorageService {
  static const _devicesKey = 'heliozone_devices';
  static const _zonesKey = 'heliozone_zones';
  static const _activeDeviceIdKey = 'heliozone_active_device_id';
  static const _tokenPrefix = 'heliozone_token_';
  static const _mqttBrokerKey = 'heliozone_mqtt_broker';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<List<Device>> loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_devicesKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Device.fromJson).toList();
  }

  Future<void> saveDevices(List<Device> devices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_devicesKey, jsonEncode(devices.map((e) => e.toJson()).toList()));
  }

  Future<List<Zone>> loadZones() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_zonesKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Zone.fromJson).toList();
  }

  Future<void> saveZones(List<Zone> zones) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_zonesKey, jsonEncode(zones.map((e) => e.toJson()).toList()));
  }

  Future<String?> loadActiveDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeDeviceIdKey);
  }

  Future<void> saveActiveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeDeviceIdKey, deviceId);
  }

  Future<String?> loadDeviceToken(String deviceId) async {
    return _secure.read(key: '$_tokenPrefix$deviceId');
  }

  Future<void> saveDeviceToken(String deviceId, String token) async {
    await _secure.write(key: '$_tokenPrefix$deviceId', value: token);
  }

  Future<void> deleteDeviceToken(String deviceId) async {
    await _secure.delete(key: '$_tokenPrefix$deviceId');
  }

  Future<String?> loadMqttBroker() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mqttBrokerKey);
  }

  Future<void> saveMqttBroker(String broker) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mqttBrokerKey, broker);
  }
}
