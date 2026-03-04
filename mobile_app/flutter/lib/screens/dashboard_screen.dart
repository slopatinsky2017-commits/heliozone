import 'dart:async';

import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import '../services/telemetry_service.dart';
import '../widgets/metric_card.dart';
import '../widgets/sun_curve_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.api, this.telemetryStream});

  final ApiService api;
  final Stream<TelemetryData>? telemetryStream;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StatusData? _status;
  TelemetryData? _telemetry;
  String? _error;
  StreamSubscription<TelemetryData>? _sub;
  TelemetryService? _telemetryService;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _startTelemetry();
  }

  Future<void> _loadInitial() async {
    try {
      final status = await widget.api.getStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load dashboard: $e');
    }
  }

  void _startTelemetry() {
    final customTelemetry = widget.telemetryStream;
    if (customTelemetry != null) {
      _sub = customTelemetry.listen(
        (event) {
          if (!mounted) return;
          setState(() {
            _telemetry = event;
            _error = null;
          });
        },
        onError: (e) {
          if (!mounted) return;
          setState(() => _error = 'Telemetry stream error: $e');
        },
      );
      return;
    }

    _telemetryService = TelemetryService(baseUrl: widget.api.baseUrl);
    _sub = _telemetryService!.subscribe().listen(
      (event) {
        if (!mounted) return;
        setState(() {
          _telemetry = event;
          _error = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _error = 'Telemetry stream error: $e');
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _telemetryService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) {
      if (_error != null) {
        return Center(child: Text(_error!));
      }
      return const Center(child: CircularProgressIndicator());
    }

    final currentPpfd = _telemetry?.ppfd ?? status.par.ppfd;
    final currentDli = _telemetry?.dli ?? status.dli.currentDli;
    final ledPower = _telemetry?.powerPercent ?? status.ledPower;
    final cloudiness = _telemetry?.cloudiness ?? status.cloud.cloudiness;
    final cloudFactor = _telemetry?.cloudFactor ?? status.cloud.currentFactor;

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 170,
                child: MetricCard(
                  title: 'Current PPFD',
                  value: currentPpfd.toStringAsFixed(1),
                  unit: 'µmol/m²/s',
                ),
              ),
              SizedBox(
                width: 170,
                child: MetricCard(
                  title: 'Current DLI',
                  value: currentDli.toStringAsFixed(2),
                  unit: 'mol/day',
                ),
              ),
              SizedBox(
                width: 170,
                child: MetricCard(
                  title: 'Target PPFD',
                  value: (_telemetry?.targetPpfd ?? status.par.target).toStringAsFixed(0),
                ),
              ),
              SizedBox(
                width: 170,
                child: MetricCard(
                  title: 'Target DLI',
                  value: (_telemetry?.targetDli ?? status.dli.targetDli).toStringAsFixed(1),
                ),
              ),
              SizedBox(
                width: 170,
                child: MetricCard(
                  title: 'LED Power',
                  value: ledPower.toStringAsFixed(1),
                  unit: '%',
                ),
              ),
              SizedBox(
                width: 170,
                child: MetricCard(
                  title: 'Sun Phase',
                  value: (_telemetry?.sunPhase ?? 'day').toUpperCase(),
                ),
              ),
              SizedBox(
                width: 170,
                child: MetricCard(
                  title: 'Cloudiness',
                  value: cloudiness.toString(),
                  unit: '%',
                ),
              ),
              SizedBox(
                width: 170,
                child: MetricCard(
                  title: 'Cloud Factor',
                  value: cloudFactor.toStringAsFixed(2),
                ),
              ),
              SizedBox(
                width: 170,
                child: MetricCard(
                  title: 'WiFi RSSI',
                  value: (_telemetry?.wifiRssi ?? 0).toString(),
                  unit: 'dBm',
                ),
              ),
              SizedBox(
                width: 170,
                child: MetricCard(
                  title: 'Uptime',
                  value: (_telemetry?.uptime ?? 0).toString(),
                  unit: 's',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SunCurveWidget(intensityPercent: status.sunBrightness),
        ],
      ),
    );
  }
}
