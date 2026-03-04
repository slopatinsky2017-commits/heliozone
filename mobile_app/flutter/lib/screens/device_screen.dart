import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import '../widgets/metric_card.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key, required this.api});

  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([api.getStatus(), api.getHealth()]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.length < 2) {
          return Center(child: Text('Failed to load device info: ${snapshot.error}'));
        }

        final status = snapshot.data![0] as StatusData;
        final health = snapshot.data![1] as HealthData;

        final critical = health.degraded || !health.lastSensorOk || health.heap < 60000;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (critical)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: const ListTile(
                  leading: Icon(Icons.warning_amber_rounded),
                  title: Text('Device health degraded'),
                  subtitle: Text('Check sensor connectivity, Wi-Fi quality, and heap usage.'),
                ),
              ),
            MetricCard(title: 'WiFi Status', value: status.device.wifiStatus),
            MetricCard(title: 'IP Address', value: status.device.ip),
            MetricCard(title: 'Firmware Version', value: status.device.firmwareVersion),
            const SizedBox(height: 12),
            Text('Health', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            MetricCard(title: 'Uptime', value: health.uptime.toString(), unit: 's'),
            MetricCard(title: 'Free Heap', value: health.heap.toString(), unit: 'bytes'),
            MetricCard(title: 'WiFi RSSI', value: health.wifiRssi.toString(), unit: 'dBm'),
            MetricCard(
              title: 'Sensor OK',
              value: health.lastSensorOk ? 'Yes' : 'No',
            ),
            MetricCard(
              title: 'Sensor age',
              value: health.lastSensorOkAgeSeconds.toString(),
              unit: 's',
            ),
            MetricCard(title: 'Last NTP Sync', value: health.lastNtpSync.toString()),
            MetricCard(title: 'OTA Last Result', value: health.otaLastResult),
            MetricCard(title: 'Health State', value: health.degraded ? 'Degraded' : 'Online'),
          ],
        );
      },
    );
  }
}
