import 'package:flutter/material.dart';

import '../theme/hz_effects.dart';
import '../theme/hz_tokens.dart';

class HzGlass extends StatelessWidget {
  const HzGlass({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = HzTokens.rMd});

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return HzEffects.glass(
      radius: BorderRadius.circular(radius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(colors: [Color(0x33213045), Color(0x22151F2F)]),
          border: Border.all(color: HzTokens.border),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: IgnorePointer(child: Opacity(opacity: 0.5, child: HzNoiseOverlay(opacity: 0.03)))),
            child,
          ],
        ),
      ),
    );
  }
}
