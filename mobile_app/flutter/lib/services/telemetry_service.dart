import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_models.dart';

class TelemetryService {
  TelemetryService({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Stream<TelemetryData> subscribe() async* {
    var reconnectDelay = const Duration(seconds: 1);

    while (true) {
      try {
        final request = http.Request('GET', _uri('/api/v1/stream'));
        request.headers['Accept'] = 'text/event-stream';
        request.headers['Cache-Control'] = 'no-cache';

        final response = await _client.send(request);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('SSE connection failed: ${response.statusCode}');
        }

        reconnectDelay = const Duration(seconds: 1);

        await for (final line
            in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
          if (line.startsWith(':')) {
            continue;
          }
          if (!line.startsWith('data:')) {
            continue;
          }

          final payload = line.substring(5).trim();
          if (payload.isEmpty) {
            continue;
          }

          final dynamic decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            yield TelemetryData.fromJson(decoded);
          }
        }
      } catch (_) {
        // reconnect with backoff
      }

      await Future<void>.delayed(reconnectDelay);
      final nextSeconds = (reconnectDelay.inSeconds * 2).clamp(1, 16);
      reconnectDelay = Duration(seconds: nextSeconds);
    }
  }

  void dispose() {
    _client.close();
  }
}
