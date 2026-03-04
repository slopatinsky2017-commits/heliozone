import 'package:flutter/material.dart';

import '../models/zone_models.dart';
import '../services/zone_control_service.dart';

class ZoneApplyControlScreen extends StatefulWidget {
  const ZoneApplyControlScreen({
    super.key,
    required this.zone,
    required this.devices,
  });

  final Zone zone;
  final List<Device> devices;

  @override
  State<ZoneApplyControlScreen> createState() => _ZoneApplyControlScreenState();
}

class _ZoneApplyControlScreenState extends State<ZoneApplyControlScreen> {
  final _modeController = TextEditingController(text: 'AUTO');
  final _ppfdController = TextEditingController(text: '450');
  final _dliController = TextEditingController(text: '10');
  final _sunriseController = TextEditingController(text: '06:00');
  final _sunsetController = TextEditingController(text: '18:00');
  final _whiteController = TextEditingController(text: '0.4');
  final _blueController = TextEditingController(text: '0.2');
  final _redController = TextEditingController(text: '0.3');
  final _farRedController = TextEditingController(text: '0.1');
  bool _power = true;
  bool _running = false;
  List<DeviceCommandResult> _results = const [];

  @override
  void dispose() {
    _modeController.dispose();
    _ppfdController.dispose();
    _dliController.dispose();
    _sunriseController.dispose();
    _sunsetController.dispose();
    _whiteController.dispose();
    _blueController.dispose();
    _redController.dispose();
    _farRedController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    setState(() => _running = true);
    try {
      final command = ZoneCommand(
        mode: _modeController.text.trim().isEmpty ? null : _modeController.text.trim(),
        power: _power,
        ppfdTarget: double.tryParse(_ppfdController.text),
        dliTarget: double.tryParse(_dliController.text),
        sunrise: _sunriseController.text.trim(),
        sunset: _sunsetController.text.trim(),
        white: double.tryParse(_whiteController.text),
        blue: double.tryParse(_blueController.text),
        red: double.tryParse(_redController.text),
        farRed: double.tryParse(_farRedController.text),
      );

      final results = await ZoneControlService().applyToZone(
        zone: widget.zone,
        devices: widget.devices,
        command: command,
      );

      if (!mounted) return;
      setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Apply to ${widget.zone.name}')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(controller: _modeController, decoration: const InputDecoration(labelText: 'Mode (AUTO/MANUAL)')),
          SwitchListTile(value: _power, onChanged: (v) => setState(() => _power = v), title: const Text('Power')),
          TextField(controller: _ppfdController, decoration: const InputDecoration(labelText: 'PPFD target')),
          TextField(controller: _dliController, decoration: const InputDecoration(labelText: 'DLI target')),
          TextField(controller: _sunriseController, decoration: const InputDecoration(labelText: 'Sunrise HH:MM')),
          TextField(controller: _sunsetController, decoration: const InputDecoration(labelText: 'Sunset HH:MM')),
          TextField(controller: _whiteController, decoration: const InputDecoration(labelText: 'White ratio')),
          TextField(controller: _blueController, decoration: const InputDecoration(labelText: 'Blue ratio')),
          TextField(controller: _redController, decoration: const InputDecoration(labelText: 'Red ratio')),
          TextField(controller: _farRedController, decoration: const InputDecoration(labelText: 'Far Red ratio')),
          const SizedBox(height: 12),
          FilledButton(onPressed: _running ? null : _apply, child: Text(_running ? 'Applying...' : 'Apply to Zone')),
          const SizedBox(height: 16),
          const Text('Per-device results'),
          ..._results.map(
            (r) => ListTile(
              dense: true,
              leading: Icon(r.success ? Icons.check_circle : Icons.error, color: r.success ? Colors.green : Colors.red),
              title: Text(r.deviceName),
              subtitle: Text(r.success ? 'Success' : (r.error ?? 'Failed')),
            ),
          ),
        ],
      ),
    );
  }
}
