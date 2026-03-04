import 'package:flutter/material.dart';

import '../models/zone_models.dart';
import '../services/api_service.dart';
import 'zone_apply_control_screen.dart';

class ZoneDetailScreen extends StatelessWidget {
  const ZoneDetailScreen({
    super.key,
    required this.zone,
    required this.devices,
    required this.onOpenDevice,
  });

  final Zone zone;
  final List<Device> devices;
  final ValueChanged<Device> onOpenDevice;

  @override
  Widget build(BuildContext context) {
    final zoneDevices = devices.where((d) => zone.deviceIds.contains(d.deviceId)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(zone.name),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ZoneApplyControlScreen(zone: zone, devices: devices),
                ),
              );
            },
            icon: const Icon(Icons.send),
            tooltip: 'Zone Control',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Devices (${zoneDevices.length})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...zoneDevices.map((d) => _DeviceStatusTile(device: d, onOpen: () => onOpenDevice(d))),
        ],
      ),
    );
  }
}

class _DeviceStatusTile extends StatelessWidget {
  const _DeviceStatusTile({required this.device, required this.onOpen});

  final Device device;
  final VoidCallback onOpen;

  Future<bool> _isOnline() async {
    try {
      await ApiService(baseUrl: device.baseUrl).getStatus().timeout(const Duration(seconds: 2));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FutureBuilder<bool>(
        future: _isOnline(),
        builder: (context, snapshot) {
          final online = snapshot.data == true;
          return ListTile(
            title: Text(device.name),
            subtitle: Text('${device.ip}\n${online ? 'online' : 'offline'}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpen,
          );
        },
      ),
    );
  }
}
