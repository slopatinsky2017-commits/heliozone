import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class HZCard extends StatelessWidget {
  const HZCard({super.key, required this.child, this.padding = const EdgeInsets.all(HZTokens.s4)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HZTokens.rMd),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2633), Color(0xFF141E28)],
        ),
        border: Border.all(color: HZTokens.border),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
