import 'package:flutter/material.dart';

import '../theme/hz_tokens.dart';

class HzTogglePill extends StatelessWidget {
  const HzTogglePill({super.key, required this.enabled, required this.onChanged, this.label = 'AUTO'});

  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!enabled),
      child: AnimatedContainer(
        duration: HzTokens.dFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: enabled ? const Color(0x33FFB347) : const Color(0x221B2736),
          border: Border.all(color: enabled ? HzTokens.amber : const Color(0xFF3A4A5F)),
        ),
        child: Text(label, style: TextStyle(color: enabled ? HzTokens.amber : const Color(0xFFAFC2D7), fontWeight: FontWeight.w700)),
      ),
    );
  }
}
