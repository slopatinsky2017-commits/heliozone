import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HzCinematicDashboardV2 extends StatefulWidget {
  const HzCinematicDashboardV2({super.key});

  @override
  State<HzCinematicDashboardV2> createState() => _HzCinematicDashboardV2State();
}

class _HzCinematicDashboardV2State extends State<HzCinematicDashboardV2> {
  bool _lampOn = true;
  bool _autoMode = true;
  int _activeTab = 0;

  final DateTime _sunrise = DateTime(2026, 1, 1, 6, 30);
  final DateTime _sunset = DateTime(2026, 1, 1, 20, 30);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final isDesktopLike = kIsWeb || width >= 900;
    final horizontalPadding = isDesktopLike ? 28.0 : 16.0;
    final heroHeight = isDesktopLike ? 350.0 : 305.0;

    final now = DateTime.now();
    final mappedNow = DateTime(
      _sunrise.year,
      _sunrise.month,
      _sunrise.day,
      now.hour,
      now.minute,
      now.second,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF05070D), Color(0xFF091223), Color(0xFF0D1628)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.85),
                    radius: 1.1,
                    colors: [
                      const Color(0x33FFB44A),
                      const Color(0x00000000),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            14,
                            horizontalPadding,
                            8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TopBar(isDesktopLike: isDesktopLike),
                              const SizedBox(height: 16),
                              _SunHeroCard(
                                now: mappedNow,
                                sunrise: _sunrise,
                                sunset: _sunset,
                                height: heroHeight,
                                phaseLabel: _phaseForTime(mappedNow),
                              ),
                              const SizedBox(height: 14),
                              _SpectrumCard(isDesktopLike: isDesktopLike),
                              const SizedBox(height: 14),
                              _MetricsRow(isDesktopLike: isDesktopLike),
                              const SizedBox(height: 14),
                              _ControlCard(
                                lampOn: _lampOn,
                                autoMode: _autoMode,
                                onLampToggle: () {
                                  setState(() {
                                    _lampOn = !_lampOn;
                                  });
                                },
                                onAutoToggle: (v) {
                                  setState(() {
                                    _autoMode = v;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      _BottomNav(
                        activeTab: _activeTab,
                        onTabTap: (index) => setState(() => _activeTab = index),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _phaseForTime(DateTime now) {
    if (now.isBefore(_sunrise)) return 'PRE-DAWN';
    if (now.isAfter(_sunset)) return 'NIGHT HOLD';
    final daySpan = _sunset.difference(_sunrise).inMinutes;
    final pos = now.difference(_sunrise).inMinutes / daySpan;
    if (pos < 0.2) return 'SUNRISE RAMP';
    if (pos < 0.8) return 'PEAK DAYLIGHT';
    return 'SUNSET FADE';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isDesktopLike});

  final bool isDesktopLike;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.inter(
      color: const Color(0xFFE8F2FF),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      fontSize: isDesktopLike ? 14 : 13,
    );

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: _glassBox(),
          child: Row(
            children: [
              Text('Zone 1', style: textStyle),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFFF3C27A), size: 18),
            ],
          ),
        ),
        const Spacer(),
        _statusIcon(Icons.wifi_rounded),
        const SizedBox(width: 8),
        _statusIcon(Icons.memory_rounded),
      ],
    );
  }

  Widget _statusIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: _glassBox(),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: const Color(0xFFDDEBFF)),
    );
  }
}

class _SunHeroCard extends StatelessWidget {
  const _SunHeroCard({
    required this.now,
    required this.sunrise,
    required this.sunset,
    required this.height,
    required this.phaseLabel,
  });

  final DateTime now;
  final DateTime sunrise;
  final DateTime sunset;
  final double height;
  final String phaseLabel;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900 || kIsWeb;
    final timeSize = isWide ? 48.0 : 42.0;

    return Container(
      height: height,
      decoration: _glassBox(radius: 24),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SunArcPainter(
                now: now,
                sunrise: sunrise,
                sunset: sunset,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.03),
                    radius: 0.44,
                    colors: [
                      const Color(0xCC0C1324),
                      const Color(0x8808101E),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('HH:mm').format(now),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: timeSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF7FBFF).withOpacity(0.98),
                    letterSpacing: 1.2,
                    shadows: const [
                      Shadow(
                        color: Color(0xAAFFBE66),
                        blurRadius: 14,
                      ),
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 18,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  phaseLabel,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF5C986).withOpacity(0.96),
                    shadows: const [
                      Shadow(color: Color(0x77000000), blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lettuce — Vegetative',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    letterSpacing: 0.35,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE8F3FF).withOpacity(0.95),
                    shadows: const [
                      Shadow(color: Color(0x88000000), blurRadius: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 18,
            bottom: 14,
            child: _timeTag(DateFormat('HH:mm').format(sunrise), true),
          ),
          Positioned(
            right: 18,
            bottom: 14,
            child: _timeTag(DateFormat('HH:mm').format(sunset), false),
          ),
        ],
      ),
    );
  }

  Widget _timeTag(String value, bool start) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x7710192B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x44C6D7EF)),
      ),
      child: Row(
        children: [
          Icon(
            start ? Icons.wb_twilight_rounded : Icons.nights_stay_rounded,
            color: const Color(0xFFF0C17D),
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFFEAF4FF),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpectrumCard extends StatelessWidget {
  const _SpectrumCard({required this.isDesktopLike});

  final bool isDesktopLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isDesktopLike ? 180 : 170,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: _glassBox(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPECTRUM PROFILE',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: const Color(0xFFF3C888),
            ),
          ),
          const SizedBox(height: 8),
          const Expanded(child: CustomPaint(painter: _SpectrumPainter())),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: const [
              _ChannelPill('380'),
              _ChannelPill('Cool White'),
              _ChannelPill('Warm White'),
              _ChannelPill('660'),
              _ChannelPill('730'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.isDesktopLike});

  final bool isDesktopLike;

  @override
  Widget build(BuildContext context) {
    final cards = [
      const _MetricCard(label: 'PPFD', value: '150', unit: 'µmol/m²/s'),
      const _MetricCard(label: 'DLI', value: '8.6', unit: 'mol/m²/day'),
    ];

    return isDesktopLike
        ? Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          )
        : Column(
            children: [
              cards[0],
              const SizedBox(height: 10),
              cards[1],
            ],
          );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _glassBox(radius: 18),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55FFB857),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
              gradient: const RadialGradient(
                colors: [Color(0xFFFFD182), Color(0xFFCD6A31)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFFE8C081),
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: value,
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFFF3F8FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    shadows: const [
                      Shadow(color: Color(0x66FFBF67), blurRadius: 10),
                    ],
                  ),
                  children: [
                    TextSpan(
                      text: '  $unit',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB8C9DE),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.lampOn,
    required this.autoMode,
    required this.onLampToggle,
    required this.onAutoToggle,
  });

  final bool lampOn;
  final bool autoMode;
  final VoidCallback onLampToggle;
  final ValueChanged<bool> onAutoToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(radius: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onLampToggle,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xA8F9C175), width: 1.2),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: lampOn
                        ? const [Color(0x3EFFC06A), Color(0x22A75827)]
                        : const [Color(0x33131D30), Color(0x22131D30)],
                  ),
                  boxShadow: lampOn
                      ? const [
                          BoxShadow(
                            color: Color(0x66FFB95B),
                            blurRadius: 18,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    lampOn ? 'LAMP ON' : 'LAMP OFF',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF8FCFF),
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                'AUTO',
                style: GoogleFonts.inter(
                  color: const Color(0xFFE6C487),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => onAutoToggle(!autoMode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 56,
                  height: 30,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x66E7EFFD)),
                    gradient: LinearGradient(
                      colors: autoMode
                          ? const [Color(0xAA1D5A7C), Color(0xAA2C97AA)]
                          : const [Color(0xAA182437), Color(0xAA131D2D)],
                    ),
                  ),
                  child: Align(
                    alignment: autoMode
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0xFFFFD694), Color(0xFFC37533)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.activeTab, required this.onTabTap});

  final int activeTab;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final base = (kIsWeb || mq.size.width >= 900) ? 64.0 : 78.0;
    final safe = mq.padding.bottom;
    final height = (base + safe).clamp(64.0, 84.0);

    final labels = ['Home', 'Zones', 'Control', 'Sun', 'Analytics'];
    final icons = [
      Icons.home_rounded,
      Icons.grid_view_rounded,
      Icons.tune_rounded,
      Icons.wb_sunny_rounded,
      Icons.query_stats_rounded,
    ];

    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(12, 8, 12, safe > 0 ? safe : 8),
      decoration: BoxDecoration(
        border: const Border(top: BorderSide(color: Color(0x3CD8E7FD))),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF7111A2B), Color(0xFB0B1322)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(labels.length, (index) {
          final selected = index == activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabTap(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: selected
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0x29FFC278), Color(0x1125475A)],
                        ),
                        border: Border.all(color: const Color(0x55FFD08B)),
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      size: 18,
                      color: selected
                          ? const Color(0xFFFFCE87)
                          : const Color(0xFF96ABC3),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      labels[index],
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected
                            ? const Color(0xFFF5C981)
                            : const Color(0xFFA5B8CF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChannelPill extends StatelessWidget {
  const _ChannelPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0x5C10192A),
        border: Border.all(color: const Color(0x44D7E7FF)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFFD5E3F4),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SunArcPainter extends CustomPainter {
  _SunArcPainter({
    required this.now,
    required this.sunrise,
    required this.sunset,
  });

  final DateTime now;
  final DateTime sunrise;
  final DateTime sunset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(20, size.height * 0.23, size.width - 40, size.height * 0.64);
    final baseArc = Paint()
      ..color = const Color(0x66BED6F2)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final bloomArc = Paint()
      ..color = const Color(0x22FFD89E)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    final path = Path()..addArc(rect, math.pi, math.pi);
    canvas.drawPath(path, bloomArc);
    canvas.drawPath(path, baseArc);

    final t = _normalized;
    final angle = math.pi + t * math.pi;
    final x = rect.center.dx + (rect.width / 2) * math.cos(angle);
    final y = rect.center.dy + (rect.height / 2) * math.sin(angle);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x99FFD889),
          const Color(0x33FF9F3C),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 28));
    canvas.drawCircle(Offset(x, y), 30, glow);

    final sun = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFE6B4), Color(0xFFFFC874), Color(0xFFF08D39)],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 8));
    canvas.drawCircle(Offset(x, y), 8, sun);
  }

  double get _normalized {
    if (now.isBefore(sunrise)) return 0;
    if (now.isAfter(sunset)) return 1;
    final total = sunset.difference(sunrise).inSeconds;
    final elapsed = now.difference(sunrise).inSeconds;
    return (elapsed / total).clamp(0, 1);
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) {
    return oldDelegate.now != now;
  }
}

class _SpectrumPainter extends CustomPainter {
  const _SpectrumPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * 0.78;
    final points = [
      Offset(size.width * 0.05, baseY),
      Offset(size.width * 0.20, size.height * 0.52),
      Offset(size.width * 0.42, size.height * 0.28),
      Offset(size.width * 0.62, size.height * 0.45),
      Offset(size.width * 0.80, size.height * 0.22),
      Offset(size.width * 0.95, size.height * 0.60),
    ];

    final fillPath = Path()..moveTo(points.first.dx, baseY);
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      linePath.quadraticBezierTo(cx, p0.dy, p1.dx, p1.dy);
      fillPath.quadraticBezierTo(cx, p0.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(points.last.dx, baseY);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0x66FFBC64),
          const Color(0x22FF4D38),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD0E3FF), Color(0xFFFFCC7A), Color(0xFFFF704A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(fillPath, fillPaint);

    final glowPaint = Paint()
      ..color = const Color(0x55FFB86A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawPath(linePath, glowPaint);
    canvas.drawPath(linePath, linePaint);

    final markerXs = [0.06, 0.28, 0.5, 0.73, 0.9];
    final markerYs = [0.74, 0.44, 0.40, 0.30, 0.56];

    for (var i = 0; i < markerXs.length; i++) {
      final center = Offset(size.width * markerXs[i], size.height * markerYs[i]);
      final glow = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0x77FFC57A),
            const Color(0x22FF6D4A),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 10));
      canvas.drawCircle(center, 11, glow);
      canvas.drawCircle(center, 3.2, Paint()..color = const Color(0xFFFFDEA8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

BoxDecoration _glassBox({double radius = 14}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0x4BD8E9FF), width: 1),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xA0162235), Color(0x6A101A2D)],
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x1A9AB3D2),
        blurRadius: 14,
        offset: Offset(0, 6),
      ),
      BoxShadow(
        color: Color(0x261E2E46),
        blurRadius: 24,
        offset: Offset(0, 12),
      ),
    ],
  );
}
