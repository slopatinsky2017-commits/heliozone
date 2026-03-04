import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class SunDashboardScreen extends StatefulWidget {
  const SunDashboardScreen({super.key});

  @override
  State<SunDashboardScreen> createState() => _SunDashboardScreenState();
}

class _SunDashboardScreenState extends State<SunDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..repeat(reverse: true);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = 0.20 + (_controller.value * 0.62);
        final phase = _phaseLabel(t);
        final hh = _now.hour.toString().padLeft(2, '0');
        final mm = _now.minute.toString().padLeft(2, '0');

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF05090E), Color(0xFF0A1119), Color(0xFF0E1722)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _ParticlePainter(seed: 42))),
              ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 22),
                children: [
                  SizedBox(
                    height: 290,
                    child: CustomPaint(
                      painter: _SunArcPainter(progress: t),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 52),
                            Text(
                              '$hh:$mm',
                              style: const TextStyle(
                                fontSize: 50,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              phase,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF9FC2DD),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(HZTokens.rLg),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF151E2B), Color(0xFF0F1723)],
                      ),
                      border: Border.all(color: const Color(0xFF304156)),
                    ),
                    child: CustomPaint(
                      painter: _SpectrumPainter(
                        blue: 0.42,
                        white: 0.74,
                        red: 0.63,
                        farRed: 0.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Expanded(
                        child: _GlowMetricCard(
                          label: 'PPFD',
                          value: '412',
                          unit: 'µmol/m²/s',
                          color: HZTokens.cyan,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _GlowMetricCard(
                          label: 'DLI',
                          value: '24.8',
                          unit: 'mol/m²/day',
                          color: HZTokens.mint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _GlowButton(onTap: () {}, text: 'LAMP ON'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _phaseLabel(double t) {
    if (t < 0.22) return 'Sunrise Phase';
    if (t > 0.78) return 'Sunset Phase';
    if (t > 0.42 && t < 0.58) return 'Midday Phase';
    return 'Day Phase';
  }
}

class _SunArcPainter extends CustomPainter {
  _SunArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x552D77FF), Color(0x22253B57), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(26)),
      sky,
    );

    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = size.width * 0.42;

    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..shader = const LinearGradient(
        colors: [Color(0x44FFE48A), Color(0x77FFD166), Color(0x44FF8C42)],
      ).createShader(arcRect);

    canvas.drawArc(arcRect, math.pi, math.pi, false, arcPaint);

    final sunrise = Offset(center.dx - radius, center.dy);
    final sunset = Offset(center.dx + radius, center.dy);

    final marker = Paint()..color = const Color(0xFFC8D6E5);
    canvas.drawCircle(sunrise, 4, marker);
    canvas.drawCircle(sunset, 4, marker);

    final sunAngle = math.pi + (math.pi * progress);
    final sunX = center.dx + math.cos(sunAngle) * radius;
    final sunY = center.dy + math.sin(sunAngle) * radius;
    final sun = Offset(sunX, sunY);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF1B0).withOpacity(0.95),
          const Color(0xFFFFB347).withOpacity(0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: sun, radius: 44));
    canvas.drawCircle(sun, 44, glow);

    final sunCore = Paint()..color = const Color(0xFFFFD877);
    canvas.drawCircle(sun, 11, sunCore);
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) => oldDelegate.progress != progress;
}

class _SpectrumPainter extends CustomPainter {
  _SpectrumPainter({
    required this.blue,
    required this.white,
    required this.red,
    required this.farRed,
  });

  final double blue;
  final double white;
  final double red;
  final double farRed;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = const Color(0x334A6A8A)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height - 20), Offset(size.width, size.height - 20), axis);

    _drawPeak(canvas, size, size.width * 0.18, blue, const Color(0xFF4BA7FF), '42%');
    _drawPeak(canvas, size, size.width * 0.42, white, const Color(0xFFE6F1FF), '74%');
    _drawPeak(canvas, size, size.width * 0.66, red, const Color(0xFFFF5F57), '63%');
    _drawPeak(canvas, size, size.width * 0.88, farRed, const Color(0xFFFF8A5B), '35%');
  }

  void _drawPeak(Canvas canvas, Size size, double x, double h, Color color, String text) {
    final peakHeight = (size.height - 42) * h;
    final rect = Rect.fromLTWH(x - 14, size.height - 20 - peakHeight, 28, peakHeight);

    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [color.withOpacity(0.08), color.withOpacity(0.55), color.withOpacity(0.15)],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), glow);

    final line = Paint()
      ..color = color
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x, size.height - 20), Offset(x, size.height - 20 - peakHeight), line);

    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, size.height - 20 - peakHeight - 18));
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) {
    return oldDelegate.blue != blue ||
        oldDelegate.white != white ||
        oldDelegate.red != red ||
        oldDelegate.farRed != farRed;
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final p = Paint()..color = const Color(0x22D4E8FF);
    for (int i = 0; i < 90; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 1.6;
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => false;
}

class _GlowMetricCard extends StatelessWidget {
  const _GlowMetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HZTokens.rMd),
        gradient: const LinearGradient(colors: [Color(0xFF162230), Color(0xFF101A24)]),
        border: Border.all(color: color.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.22), blurRadius: 18, spreadRadius: 0.2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          Text(unit, style: const TextStyle(color: Color(0xFF95AFC8), fontSize: 12)),
        ],
      ),
    );
  }
}

class _GlowButton extends StatefulWidget {
  const _GlowButton({required this.onTap, required this.text});

  final VoidCallback onTap;
  final String text;

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: _pressed
                ? [const Color(0xFF2CB58B), const Color(0xFF1D8F6D)]
                : [const Color(0xFF41E2B0), const Color(0xFF2EB98F)],
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFF41E2B0).withOpacity(0.36), blurRadius: 18),
          ],
        ),
        child: Text(
          widget.text,
          style: const TextStyle(
            color: Color(0xFF06120D),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
