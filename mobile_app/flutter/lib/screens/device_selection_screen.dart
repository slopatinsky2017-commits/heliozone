import 'package:flutter/foundation.dart';
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
  final _manualIpController = TextEditingController();
  List<DiscoveredDevice> _devices = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _discover();
  }

  @override
  void dispose() {
    _manualIpController.dispose();
    super.dispose();
  }

  Future<void> _discover() async {
    if (kIsWeb) {
      setState(() {
        _loading = false;
        _devices = const [];
        _error = null;
      });
      return;
    }

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
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select HelioZone Controller')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Use Manual IP to access your controller on web.'),
              const SizedBox(height: 12),
              TextField(
                controller: _manualIpController,
                decoration: const InputDecoration(
                  labelText: 'Manual IP',
                  hintText: '192.168.1.44',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: null, child: const Text('Connect')),
            ],
          ),
        ),
      );
    }

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
