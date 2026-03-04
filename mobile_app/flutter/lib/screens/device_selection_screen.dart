import 'package:flutter/material.dart';

import '../services/device_discovery_service.dart';

class DeviceSelectionScreen extends StatefulWidget {
  const DeviceSelectionScreen({super.key, required this.onSelect});

  final ValueChanged<DiscoveredDevice> onSelect;

  @override
  State<DeviceSelectionScreen> createState() => _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends State<DeviceSelectionScreen> {
  final _discoveryService = DeviceDiscoveryService();
  List<DiscoveredDevice> _devices = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _discover();
  }

  Future<void> _discover() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final devices = await _discoveryService.discover();
      if (!mounted) return;
      setState(() => _devices = devices);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select HelioZone Controller')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Discovery failed: $_error'))
              : RefreshIndicator(
                  onRefresh: _discover,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _devices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final d = _devices[index];
                      return Card(
                        child: ListTile(
                          title: Text(d.deviceName),
                          subtitle: Text('${d.ipAddress}\n${d.hostname}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => widget.onSelect(d),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _discover,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
