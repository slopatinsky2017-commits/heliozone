import 'package:flutter/material.dart';

import 'models/api_models.dart';
import 'models/zone_models.dart';
import 'screens/dashboard_screen.dart';
import 'screens/device_screen.dart';
import 'screens/device_selection_screen.dart';
import 'screens/spectrum_control_screen.dart';
import 'screens/zone_control_screen.dart';
import 'screens/zones_screen.dart';
import 'services/api_service.dart';
import 'services/device_discovery_service.dart';
import 'services/local_storage_service.dart';
import 'services/mqtt_service.dart';

void main() {
  runApp(const HelioZoneApp());
}

class HelioZoneApp extends StatelessWidget {
  const HelioZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelioZone',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const AppBootstrap(),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  final _storage = LocalStorageService();
  List<Device> _devices = const [];
  Device? _active;
  String? _mqttBroker;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final devices = await _storage.loadDevices();
    final activeId = await _storage.loadActiveDeviceId();
    final broker = await _storage.loadMqttBroker();

    Device? active;
    if (activeId != null) {
      for (final d in devices) {
        if (d.deviceId == activeId) {
          active = d;
          break;
        }
      }
    }
    active ??= devices.isNotEmpty ? devices.first : null;

    if (!mounted) return;
    setState(() {
      _devices = devices;
      _active = active;
      _mqttBroker = broker;
      _loading = false;
    });
  }

  Future<void> _selectDiscovered(DiscoveredDevice d) async {
    final now = DateTime.now();
    final deviceId = d.hostname.toLowerCase();
    final existingIdx = _devices.indexWhere((e) => e.deviceId == deviceId);
    final updated = Device(
      deviceId: deviceId,
      name: d.deviceName,
      host: d.hostname,
      ip: d.ipAddress,
      fw: 'unknown',
      lastSeen: now,
    );

    final devices = [..._devices];
    if (existingIdx >= 0) {
      devices[existingIdx] = updated;
    } else {
      devices.add(updated);
    }

    try {
      var token = await _storage.loadDeviceToken(updated.deviceId);
      if (token == null || token.isEmpty) {
        final pairingApi = ApiService(baseUrl: updated.baseUrl);
        token = await pairingApi.pair();
        await _storage.saveDeviceToken(updated.deviceId, token);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pairing failed: $e')),
      );
      return;
    }

    await _storage.saveDevices(devices);
    await _storage.saveActiveDeviceId(updated.deviceId);

    if (!mounted) return;
    setState(() {
      _devices = devices;
      _active = updated;
    });
  }

  Future<void> _openDevice(Device device) async {
    await _storage.saveActiveDeviceId(device.deviceId);
    if (!mounted) return;
    setState(() => _active = device);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_active == null) {
      return DeviceSelectionScreen(onSelect: _selectDiscovered);
    }

    return HomeShell(
      activeDevice: _active!,
      devices: _devices,
      storage: _storage,
      mqttBroker: _mqttBroker,
      onOpenDevice: _openDevice,
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.activeDevice,
    required this.devices,
    required this.storage,
    required this.mqttBroker,
    required this.onOpenDevice,
  });

  final Device activeDevice;
  final List<Device> devices;
  final LocalStorageService storage;
  final String? mqttBroker;
  final ValueChanged<Device> onOpenDevice;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  late ApiService api;
  MqttService? _mqtt;
  Stream<TelemetryData>? _mqttTelemetry;

  @override
  void initState() {
    super.initState();
    api = ApiService(baseUrl: widget.activeDevice.baseUrl, deviceId: widget.activeDevice.deviceId);
    _setupControlPlane();
  }

  Future<void> _setupControlPlane() async {
    final token = await widget.storage.loadDeviceToken(widget.activeDevice.deviceId);
    final broker = widget.mqttBroker;
    if (broker != null && broker.isNotEmpty) {
      final mqtt = MqttService(brokerHost: broker);
      _mqtt = mqtt;
      _mqttTelemetry = mqtt.telemetryStream(widget.activeDevice.deviceId);
      api = ApiService(
        baseUrl: widget.activeDevice.baseUrl,
        authToken: token,
        deviceId: widget.activeDevice.deviceId,
        mqttCommandSender: mqtt.publishDeviceCommand,
      );
    } else {
      api = ApiService(
        baseUrl: widget.activeDevice.baseUrl,
        authToken: token,
        deviceId: widget.activeDevice.deviceId,
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeDevice.deviceId != widget.activeDevice.deviceId || oldWidget.mqttBroker != widget.mqttBroker) {
      _mqtt?.dispose();
      _mqtt = null;
      _mqttTelemetry = null;
      _setupControlPlane();
    }
  }

  @override
  void dispose() {
    _mqtt?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(api: api, telemetryStream: _mqttTelemetry),
      const SizedBox.shrink(),
      ZoneControlScreen(api: api),
      SpectrumControlScreen(api: api),
      DeviceScreen(api: api),
    ];

    screens[1] = ZonesScreen(devices: widget.devices, onOpenDevice: widget.onOpenDevice);

    const titles = ['Dashboard', 'Zones', 'Zone Control', 'Spectrum', 'Device'];

    return Scaffold(
      appBar: AppBar(
        title: Text('HelioZone • ${titles[index]}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                widget.activeDevice.ip,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Zones'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Zone Ctrl'),
          NavigationDestination(icon: Icon(Icons.gradient), label: 'Spectrum'),
          NavigationDestination(icon: Icon(Icons.router), label: 'Device'),
        ],
      ),
    );
  }
}
