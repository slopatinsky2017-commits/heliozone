import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ZoneControlScreen extends StatefulWidget {
  const ZoneControlScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<ZoneControlScreen> createState() => _ZoneControlScreenState();
}

class _ZoneControlScreenState extends State<ZoneControlScreen> {
  final _sunriseController = TextEditingController(text: '06:00');
  final _sunsetController = TextEditingController(text: '18:00');
  final _photoperiodController = TextEditingController(text: '12');
  final _targetPpfdController = TextEditingController(text: '450');
  final _targetDliController = TextEditingController(text: '10');

  bool _saving = false;

  @override
  void dispose() {
    _sunriseController.dispose();
    _sunsetController.dispose();
    _photoperiodController.dispose();
    _targetPpfdController.dispose();
    _targetDliController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final targetPpfd = double.tryParse(_targetPpfdController.text) ?? 0;
      final targetDli = double.tryParse(_targetDliController.text) ?? 0;
      final photoperiod = double.tryParse(_photoperiodController.text) ?? 12;

      await widget.api.postControl(
        sunrise: _sunriseController.text,
        sunset: _sunsetController.text,
        photoperiodHours: photoperiod,
      );
      await widget.api.setParTarget(targetPpfd);
      await widget.api.setDliTarget(targetDli);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zone settings updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update settings: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(controller: _photoperiodController, decoration: const InputDecoration(labelText: 'Photoperiod (hours)')),
        TextField(controller: _sunriseController, decoration: const InputDecoration(labelText: 'Sunrise (HH:MM)')),
        TextField(controller: _sunsetController, decoration: const InputDecoration(labelText: 'Sunset (HH:MM)')),
        TextField(controller: _targetPpfdController, decoration: const InputDecoration(labelText: 'Target PPFD')),
        TextField(controller: _targetDliController, decoration: const InputDecoration(labelText: 'Target DLI')),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Apply Zone Settings'),
        ),
      ],
    );
  }
}
