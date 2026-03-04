import 'dart:math' as math;

import 'package:flutter/material.dart';

class HzSunArcPainter extends CustomPainter {
  HzSunArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.92);
    final radius = size.width * 0.42;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x444C76FF), Color(0x2234445F), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28)), sky);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = const LinearGradient(colors: [Color(0x55FFD48B), Color(0xAAFFC46B), Color(0x55FF8D5A)]).createShader(rect);
    canvas.drawArc(rect, math.pi, math.pi, false, arc);

    final start = Offset(center.dx - radius, center.dy);
    final end = Offset(center.dx + radius, center.dy);
    final m = Paint()..color = const Color(0xFFDFECFA);
    canvas.drawCircle(start, 3.5, m);
    canvas.drawCircle(end, 3.5, m);

    final angle = math.pi + (math.pi * progress);
    final sun = Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);

    final g = Paint()
      ..shader = RadialGradient(colors: [const Color(0xFFFFF4C3).withOpacity(0.96), const Color(0xFFFFB54F).withOpacity(0.24), Colors.transparent])
          .createShader(Rect.fromCircle(center: sun, radius: 50));
    canvas.drawCircle(sun, 50, g);
    canvas.drawCircle(sun, 11, Paint()..color = const Color(0xFFFFD97E));
  }

  @override
  bool shouldRepaint(covariant HzSunArcPainter oldDelegate) => oldDelegate.progress != progress;
}
