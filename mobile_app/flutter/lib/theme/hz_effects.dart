import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class HzEffects {
  static Widget glass({required Widget child, BorderRadius? radius}) {
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: child,
      ),
    );
  }
}

class HzNoiseOverlay extends StatelessWidget {
  const HzNoiseOverlay({super.key, this.opacity = 0.06});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _NoisePainter(opacity: opacity));
  }
}

class HzParticleField extends StatelessWidget {
  const HzParticleField({super.key, this.seed = 3});
  final int seed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ParticlePainter(seed: seed));
  }
}

class _NoisePainter extends CustomPainter {
  _NoisePainter({required this.opacity});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final p = Paint()..color = Color.fromRGBO(255, 255, 255, opacity);
    for (int i = 0; i < 1800; i++) {
      canvas.drawRect(Rect.fromLTWH(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height, 1, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) => false;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final p = Paint()..color = const Color(0x22D7E8FF);
    for (int i = 0; i < 80; i++) {
      canvas.drawCircle(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height), rnd.nextDouble() * 1.6, p);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => false;
}
