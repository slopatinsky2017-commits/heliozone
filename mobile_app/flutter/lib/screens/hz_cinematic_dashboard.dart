import 'dart:async';

import 'package:flutter/material.dart';

import '../painters/hz_spectrum_painter.dart';
import '../painters/hz_sun_arc_painter.dart';
import '../theme/hz_effects.dart';
import '../theme/hz_tokens.dart';
import '../widgets/hz_bottom_nav.dart';
import '../widgets/hz_glass.dart';
import '../widgets/hz_glow_button.dart';
import '../widgets/hz_metric_tile.dart';
import '../widgets/hz_toggle_pill.dart';
import '../widgets/hz_zone_selector.dart';

class HzCinematicDashboard extends StatefulWidget {
  const HzCinematicDashboard({super.key});

  @override
  State<HzCinematicDashboard> createState() => _HzCinematicDashboardState();
}

class _HzCinematicDashboardState extends State<HzCinematicDashboard>
    with TickerProviderStateMixin {
  late final AnimationController _sun;
  late final AnimationController _shimmer;
  late final Timer _clock;

  int _tab = 0;
  bool _auto = true;
  String _zone = 'Zone 1';
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _sun = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat(reverse: true);
    _shimmer = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _sun.dispose();
    _shimmer.dispose();
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: HzTokens.cosmicBg),
        child: Stack(
          children: [
            const Positioned.fill(child: HzParticleField(seed: 10)),
            const Positioned.fill(child: IgnorePointer(child: Opacity(opacity: 0.35, child: HzNoiseOverlay(opacity: 0.04)))),
            SafeArea(
              child: IndexedStack(
                index: _tab,
                children: [
                  _buildHome(),
                  _placeholder('Zones'),
                  _placeholder('Control'),
                  _placeholder('Sun'),
                  _placeholder('Analytics'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: HzBottomNav(index: _tab, onChanged: (v) => setState(() => _tab = v)),
    );
  }

  Widget _buildHome() {
    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');

    return AnimatedBuilder(
      animation: Listenable.merge([_sun, _shimmer]),
      builder: (context, _) {
        final sunProgress = 0.18 + _sun.value * 0.64;
        final shimmer = _shimmer.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
          children: [
            Row(
              children: [
                Expanded(child: HzZoneSelector(value: _zone, onChanged: (v) => setState(() => _zone = v ?? _zone))),
                const SizedBox(width: 10),
                const _StatusDot(),
                const SizedBox(width: 10),
                const Icon(Icons.wifi_rounded, size: 20, color: Color(0xFFAEC0D6)),
                const SizedBox(width: 8),
                const Icon(Icons.battery_5_bar_rounded, size: 20, color: Color(0xFFAEC0D6)),
              ],
            ),
            const SizedBox(height: 14),
            HzGlass(
              radius: HzTokens.rLg,
              child: SizedBox(
                height: 330,
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: HzSunArcPainter(progress: sunProgress))),
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 54),
                          Text('$hh:$mm', style: Theme.of(context).textTheme.displaySmall),
                          const SizedBox(height: 8),
                          Text(_phaseText(sunProgress), style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('Flowers — Seedling', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Positioned(left: 8, bottom: 8, child: Text('06:30', style: TextStyle(color: Color(0xFF95AAC2), fontSize: 12))),
                    const Positioned(right: 8, bottom: 8, child: Text('20:30', style: TextStyle(color: Color(0xFF95AAC2), fontSize: 12))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            HzGlass(
              radius: HzTokens.rLg,
              child: SizedBox(
                height: 190,
                child: CustomPaint(
                  painter: HzSpectrumPainter(cw: 0.14, ww: 0.35, r660: 0.40, r730: 0.22, shimmer: shimmer),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: HzMetricTile(label: 'PPFD', value: '420', unit: 'μmol/m²/s', color: HzTokens.cyan)),
                SizedBox(width: 12),
                Expanded(child: HzMetricTile(label: 'DLI', value: '18.6', unit: 'mol/m²/day', color: HzTokens.amber)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: HzGlowButton(text: 'LAMP ON', onTap: () {})),
                const SizedBox(width: 12),
                HzTogglePill(enabled: _auto, onChanged: (v) => setState(() => _auto = v), label: 'AUTO'),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _placeholder(String name) {
    return Center(
      child: HzGlass(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('$name coming next', style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }

  String _phaseText(double p) {
    if (p < 0.24) return 'Sunrise Phase';
    if (p > 0.76) return 'Sunset Phase';
    if (p > 0.45 && p < 0.58) return 'Midday Phase';
    return 'Day Phase';
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF41E2B0),
        boxShadow: [BoxShadow(color: const Color(0xFF41E2B0).withOpacity(0.5), blurRadius: 10)],
      ),
    );
  }
}
