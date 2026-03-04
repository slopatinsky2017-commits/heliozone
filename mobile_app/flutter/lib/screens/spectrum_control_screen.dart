import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import '../widgets/channel_slider.dart';

class SpectrumControlScreen extends StatefulWidget {
  const SpectrumControlScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<SpectrumControlScreen> createState() => _SpectrumControlScreenState();
}

class _SpectrumControlScreenState extends State<SpectrumControlScreen> {
  double white = 40;
  double blue = 20;
  double red = 30;
  double farRed = 10;

  bool cloudEnabled = true;
  double cloudiness = 25;
  double minFactor = 0.7;
  double maxFactor = 0.95;
  double avgInterval = 180;

  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadCloud();
  }

  Future<void> _loadCloud() async {
    try {
      final c = await widget.api.getCloud();
      if (!mounted) return;
      setState(() {
        cloudEnabled = c.enabled;
        cloudiness = c.cloudiness.toDouble();
        minFactor = c.minFactor;
        maxFactor = c.maxFactor;
        avgInterval = c.avgIntervalS.toDouble();
      });
    } catch (_) {
      // ignore bootstrap errors
    }
  }

  Future<void> _apply() async {
    setState(() => saving = true);
    try {
      await widget.api.postControl(
        white: white / 100,
        blue: blue / 100,
        red: red / 100,
        farRed: farRed / 100,
      );

      await widget.api.setCloudConfig(
        CloudData(
          enabled: cloudEnabled,
          cloudiness: cloudiness.toInt(),
          minFactor: minFactor,
          maxFactor: maxFactor,
          avgIntervalS: avgInterval.toInt(),
          currentFactor: 1.0,
          dipActive: false,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Spectrum and cloud settings updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update settings: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ChannelSlider(label: 'White', value: white, onChanged: (v) => setState(() => white = v)),
        ChannelSlider(label: 'Blue', value: blue, onChanged: (v) => setState(() => blue = v)),
        ChannelSlider(label: 'Red', value: red, onChanged: (v) => setState(() => red = v)),
        ChannelSlider(label: 'Far Red', value: farRed, onChanged: (v) => setState(() => farRed = v)),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enable Cloud Simulation'),
          value: cloudEnabled,
          onChanged: (v) => setState(() => cloudEnabled = v),
        ),
        ChannelSlider(label: 'Cloudiness', value: cloudiness, onChanged: (v) => setState(() => cloudiness = v)),
        ChannelSlider(
          label: 'Min Factor',
          value: minFactor * 100,
          onChanged: (v) => setState(() => minFactor = (v / 100).clamp(0.1, maxFactor)),
        ),
        ChannelSlider(
          label: 'Max Factor',
          value: maxFactor * 100,
          onChanged: (v) => setState(() => maxFactor = (v / 100).clamp(minFactor, 1.0)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Avg Interval (s)'),
            Text(avgInterval.toStringAsFixed(0)),
          ],
        ),
        Slider(
          value: avgInterval,
          min: 5,
          max: 600,
          onChanged: (v) => setState(() => avgInterval = v),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: saving ? null : _apply,
          child: Text(saving ? 'Applying...' : 'Apply Spectrum + Clouds'),
        ),
      ],
    );
  }
}
