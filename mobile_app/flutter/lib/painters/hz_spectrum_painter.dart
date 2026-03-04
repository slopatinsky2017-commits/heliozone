import 'package:flutter/material.dart';

class HzSpectrumPainter extends CustomPainter {
  HzSpectrumPainter({required this.cw, required this.ww, required this.r660, required this.r730, required this.shimmer});

  final double cw;
  final double ww;
  final double r660;
  final double r730;
  final double shimmer;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()..color = const Color(0x334D6786);
    canvas.drawLine(Offset(0, size.height - 20), Offset(size.width, size.height - 20), axis);

    _peak(canvas, size, size.width * 0.16, cw, const Color(0xFF55C5FF), '14%', shimmer);
    _peak(canvas, size, size.width * 0.39, ww, const Color(0xFFFFE6B8), '35%', shimmer);
    _peak(canvas, size, size.width * 0.64, r660, const Color(0xFFFF5B5B), '40%', shimmer);
    _peak(canvas, size, size.width * 0.88, r730, const Color(0xFFB6363B), '22%', shimmer);

    _label(canvas, const Offset(22, 6), '380', const Color(0xFF55C5FF));
    _label(canvas, Offset(size.width * 0.31, 6), 'WW', const Color(0xFFFFE6B8));
    _label(canvas, Offset(size.width * 0.58, 6), '660', const Color(0xFFFF5B5B));
    _label(canvas, Offset(size.width * 0.82, 6), '730', const Color(0xFFB6363B));
  }

  void _peak(Canvas c, Size size, double x, double h, Color color, String pct, double shimmer) {
    final height = (size.height - 44) * h;
    final rect = Rect.fromLTWH(x - 15, size.height - 20 - height, 30, height);

    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [color.withOpacity(0.08), color.withOpacity(0.56 + shimmer * 0.1), color.withOpacity(0.18)],
      ).createShader(rect);
    c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), glow);

    c.drawLine(Offset(x, size.height - 20), Offset(x, size.height - 20 - height), Paint()..color = color..strokeWidth = 2);

    final tp = TextPainter(
      text: TextSpan(text: pct, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x - tp.width / 2, size.height - 20 - height - 18));
  }

  void _label(Canvas c, Offset at, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at);
  }

  @override
  bool shouldRepaint(covariant HzSpectrumPainter old) {
    return old.cw != cw || old.ww != ww || old.r660 != r660 || old.r730 != r730 || old.shimmer != shimmer;
  }
}
