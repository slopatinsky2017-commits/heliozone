import 'dart:math';

import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../models/zone_models.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import 'zone_detail_screen.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({
    super.key,
    required this.devices,
    required this.onOpenDevice,
  });

  final List<Device> devices;
  final ValueChanged<Device> onOpenDevice;

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  final _storage = LocalStorageService();
  List<Zone> _zones = const [];
  final Map<String, HealthData> _healthByDeviceId = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final zones = await _storage.loadZones();
    await _refreshHealth();
    if (!mounted) return;
    setState(() => _zones = zones);
  }

  Future<void> _refreshHealth() async {
    final next = <String, HealthData>{};
    for (final d in widget.devices) {
      try {
        final token = await _storage.loadDeviceToken(d.deviceId);
        final api = ApiService(baseUrl: d.baseUrl, authToken: token, deviceId: d.deviceId);
        final health = await api.getHealth();
        next[d.deviceId] = health;
      } catch (_) {
        // offline/unreachable
      }
    }
    _healthByDeviceId
      ..clear()
      ..addAll(next);
  }

  Future<void> _save() async {
    await _storage.saveZones(_zones);
    if (mounted) setState(() {});
  }

  Future<void> _createZone() async {
    final nameCtl = TextEditingController();
    final selected = <String>{};

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Create zone'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Zone name')),
                  const SizedBox(height: 8),
                  ...widget.devices.map(
                    (d) => CheckboxListTile(
                      value: selected.contains(d.deviceId),
                      onChanged: (v) {
                        setStateDialog(() {
                          if (v == true) {
                            selected.add(d.deviceId);
                          } else {
                            selected.remove(d.deviceId);
                          }
                        });
                      },
                      title: Text(d.name),
                      subtitle: Text(d.ip),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final zone = Zone(
      zoneId: 'zone_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
      name: nameCtl.text.trim().isEmpty ? 'Zone ${_zones.length + 1}' : nameCtl.text.trim(),
      deviceIds: selected.toList(),
    );

    _zones = [..._zones, zone];
    await _save();
  }

  Future<void> _deleteZone(Zone zone) async {
    _zones = _zones.where((z) => z.zoneId != zone.zoneId).toList();
    await _save();
  }

  ({int online, int offline, int degraded}) _countsForZone(Zone zone) {
    int online = 0;
    int degraded = 0;
    int offline = 0;

    for (final id in zone.deviceIds) {
      final h = _healthByDeviceId[id];
      if (h == null) {
        offline++;
      } else if (h.degraded) {
        degraded++;
      } else {
        online++;
      }
    }

    return (online: online, offline: offline, degraded: degraded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            ..._zones.map(
              (z) {
                final c = _countsForZone(z);
                return Card(
                  child: ListTile(
                    title: Text(z.name),
                    subtitle: Text(
                      '${z.deviceIds.length} devices • online ${c.online} • degraded ${c.degraded} • offline ${c.offline}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteZone(z)),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ZoneDetailScreen(
                            zone: z,
                            devices: widget.devices,
                            onOpenDevice: widget.onOpenDevice,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            if (_zones.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No zones yet. Create your first zone.'),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _createZone, child: const Icon(Icons.add)),
    );
  }
}
