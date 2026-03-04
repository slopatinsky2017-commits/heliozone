import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../models/api_models.dart';

class MqttService {
  MqttService({required this.brokerHost, this.port = 1883});

  final String brokerHost;
  final int port;
  MqttServerClient? _client;
  final _telemetryController = StreamController<TelemetryData>.broadcast();

  Stream<TelemetryData> telemetryStream(String deviceId) {
    _ensureConnected();
    _client?.subscribe('heliozone/$deviceId/telemetry', MqttQos.atMostOnce);
    return _telemetryController.stream;
  }

  Future<void> publishDeviceCommand(String deviceId, Map<String, dynamic> command) async {
    await _ensureConnected();
    final payload = jsonEncode(command);
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client?.publishMessage('heliozone/$deviceId/cmd', MqttQos.atLeastOnce, builder.payload!);
  }

  Future<void> _ensureConnected() async {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      return;
    }

    final client = MqttServerClient(brokerHost, 'heliozone_mobile_${DateTime.now().millisecondsSinceEpoch}');
    client.port = port;
    client.keepAlivePeriod = 20;
    client.logging(on: false);
    client.autoReconnect = true;
    client.onConnected = () {};

    await client.connect();
    client.updates?.listen((events) {
      for (final event in events) {
        final rec = event.payload;
        if (rec is! MqttPublishMessage) {
          continue;
        }
        final msg = MqttPublishPayload.bytesToStringAsString(rec.payload.message);
        try {
          final dynamic decoded = jsonDecode(msg);
          if (decoded is Map<String, dynamic>) {
            _telemetryController.add(TelemetryData.fromJson(decoded));
          }
        } catch (_) {
          // ignore malformed payloads
        }
      }
    });

    _client = client;
  }

  Future<void> dispose() async {
    await _telemetryController.close();
    _client?.disconnect();
  }
}
