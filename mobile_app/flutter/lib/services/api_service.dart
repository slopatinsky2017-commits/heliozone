import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_models.dart';

class ApiService {
  ApiService({String? baseUrl, this.authToken, this.deviceId, this.mqttCommandSender})
      : baseUrl = baseUrl ?? 'http://heliozone.local';

  final String baseUrl;
  final String? deviceId;
  final Future<void> Function(String deviceId, Map<String, dynamic> command)? mqttCommandSender;
  String? authToken;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _authHeaders([Map<String, String>? headers]) {
    final merged = <String, String>{...?headers};
    final token = authToken;
    if (token != null && token.isNotEmpty) {
      merged['Authorization'] = 'Bearer $token';
    }
    return merged;
  }

  Future<bool> _sendViaMqttIfConfigured(Map<String, dynamic> command) async {
    if (mqttCommandSender == null || deviceId == null || deviceId!.isEmpty) {
      return false;
    }
    await mqttCommandSender!(deviceId!, command);
    return true;
  }

  Future<StatusData> getStatus() async {
    final response = await http.get(_uri('/api/v1/status'), headers: _authHeaders());
    final json = _decode(response);
    return StatusData.fromJson(json);
  }

  Future<ParData> getPar() async {
    final response = await http.get(_uri('/api/v1/par'), headers: _authHeaders());
    final json = _decode(response);
    return ParData.fromJson(json);
  }

  Future<DliData> getDli() async {
    final response = await http.get(_uri('/api/v1/dli'), headers: _authHeaders());
    final json = _decode(response);
    return DliData.fromJson(json);
  }

  Future<HealthData> getHealth() async {
    final response = await http.get(_uri('/api/v1/health'), headers: _authHeaders());
    final json = _decode(response);
    return HealthData.fromJson(json);
  }

  Future<CloudData> getCloud() async {
    final response = await http.get(_uri('/api/v1/cloud'), headers: _authHeaders());
    final json = _decode(response);
    return CloudData.fromJson(json);
  }

  Future<void> setCloudConfig(CloudData cloud) async {
    final response = await http.post(
      _uri('/api/v1/cloud'),
      headers: _authHeaders({'Content-Type': 'application/json'}),
      body: jsonEncode(cloud.toJson()),
    );
    _decode(response);
  }

  Future<void> setPower(bool power) async {
    if (await _sendViaMqttIfConfigured({'power': power})) {
      return;
    }

    final response = await http.post(
      _uri('/api/v1/control/power'),
      headers: _authHeaders({'Content-Type': 'application/json'}),
      body: jsonEncode({'power': power}),
    );
    _decode(response);
  }

  Future<void> setParTarget(double target) async {
    if (await _sendViaMqttIfConfigured({'target_ppfd': target})) {
      return;
    }

    final response = await http.post(
      _uri('/api/v1/par/target'),
      headers: _authHeaders({'Content-Type': 'application/json'}),
      body: jsonEncode({'target': target}),
    );
    _decode(response);
  }

  Future<void> setDliTarget(double targetDli) async {
    if (await _sendViaMqttIfConfigured({'target_dli': targetDli})) {
      return;
    }

    final response = await http.post(
      _uri('/api/v1/dli/target'),
      headers: _authHeaders({'Content-Type': 'application/json'}),
      body: jsonEncode({'target_dli': targetDli}),
    );
    _decode(response);
  }

  Future<void> postControl({
    String? mode,
    String? sunrise,
    String? sunset,
    double? photoperiodHours,
    double? white,
    double? blue,
    double? red,
    double? farRed,
  }) async {
    final payload = <String, dynamic>{
      if (mode != null) 'mode': mode,
      if (sunrise != null) 'sunrise_time': sunrise,
      if (sunset != null) 'sunset_time': sunset,
      if (photoperiodHours != null) 'photoperiod_hours': photoperiodHours,
      if (white != null || blue != null || red != null || farRed != null)
        'channels': {
          if (white != null) 'white': white,
          if (blue != null) 'blue': blue,
          if (red != null) 'red': red,
          if (farRed != null) 'far_red': farRed,
        },
      if (white != null || blue != null || red != null || farRed != null)
        'channel_ratios': {
          if (white != null) 'white': white,
          if (blue != null) 'blue': blue,
          if (red != null) 'red': red,
          if (farRed != null) 'far_red': farRed,
        },
    };

    if (await _sendViaMqttIfConfigured(payload)) {
      return;
    }

    final response = await http.post(
      _uri('/api/v1/control'),
      headers: _authHeaders({'Content-Type': 'application/json'}),
      body: jsonEncode(payload),
    );

    _decode(response);
  }

  Future<String> pair() async {
    final response = await http.post(_uri('/api/v1/auth/pair'));
    final json = _decode(response);
    final token = json['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw Exception('Pairing failed: missing token');
    }
    authToken = token;
    return token;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final dynamic parsed = jsonDecode(response.body.isEmpty ? '{}' : response.body);
    if (parsed is Map<String, dynamic>) {
      return parsed;
    }
    return {};
  }
}
