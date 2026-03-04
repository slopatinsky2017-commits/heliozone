import 'package:flutter/material.dart';

class HzTokens {
  static const bgA = Color(0xFF05070C);
  static const bgB = Color(0xFF0A111C);
  static const bgC = Color(0xFF101A2A);
  static const panel = Color(0xAA141E2E);
  static const border = Color(0x33DCE8FF);

  static const amber = Color(0xFFFFB554);
  static const amberBright = Color(0xFFFFC978);
  static const cyan = Color(0xFF62D6FF);
  static const ww = Color(0xFFFFEBC9);
  static const red660 = Color(0xFFFF5D5D);
  static const red730 = Color(0xFFC33A46);
  static const success = Color(0xFF40E0A8);

  static const rSm = 12.0;
  static const rMd = 18.0;
  static const rLg = 26.0;
  static const rXl = 32.0;

  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;

  static const dFast = Duration(milliseconds: 160);
  static const dMed = Duration(milliseconds: 280);
  static const dSlow = Duration(milliseconds: 900);

  static const cosmicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgA, bgB, bgC],
  );

  static List<BoxShadow> amberGlow([double o = 0.28]) => [
        BoxShadow(color: amber.withOpacity(o), blurRadius: 24, spreadRadius: 0.2),
      ];

  // Backward-compatible aliases used across legacy widgets.
  static const bg0 = bgA;
  static const bg1 = bgB;
  static const bg2 = bgC;
  static const glass = panel;
  static const whiteWarm = ww;
  static const amberSoft = Color(0x66FFB554);
  static const cosmicBg = cosmicGradient;

  static List<BoxShadow> softGlow(Color c) => [
        BoxShadow(color: c.withOpacity(0.30), blurRadius: 24, spreadRadius: 0.1),
      ];
}
