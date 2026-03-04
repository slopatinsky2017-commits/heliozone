import 'package:flutter/material.dart';

class HzTokens {
  static const bg0 = Color(0xFF06090F);
  static const bg1 = Color(0xFF0B111B);
  static const bg2 = Color(0xFF111A28);
  static const glass = Color(0x331A2534);
  static const border = Color(0x44C8D6EA);

  static const amber = Color(0xFFFFB347);
  static const amberSoft = Color(0x66FFB347);
  static const cyan = Color(0xFF63D4FF);
  static const whiteWarm = Color(0xFFFFF3D6);
  static const red660 = Color(0xFFFF5A5A);
  static const red730 = Color(0xFFB7363B);

  static const rSm = 12.0;
  static const rMd = 18.0;
  static const rLg = 26.0;

  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;

  static const dFast = Duration(milliseconds: 180);
  static const dMed = Duration(milliseconds: 280);
  static const dSlow = Duration(milliseconds: 900);

  static const cosmicBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bg0, bg1, bg2],
  );

  static List<BoxShadow> softGlow(Color c) => [
        BoxShadow(color: c.withOpacity(0.30), blurRadius: 24, spreadRadius: 0.1),
      ];
}
