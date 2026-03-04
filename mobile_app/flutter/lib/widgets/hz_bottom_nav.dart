import 'package:flutter/material.dart';

import '../theme/hz_tokens.dart';

class HzBottomNav extends StatelessWidget {
  const HzBottomNav({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.grid_view_rounded, 'Zones'),
    (Icons.tune_rounded, 'Control'),
    (Icons.wb_twilight_rounded, 'Sun'),
    (Icons.analytics_outlined, 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC0F1824),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x334E6079)),
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final active = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: HzTokens.dFast,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: active ? const Color(0x22FFB347) : Colors.transparent,
                  boxShadow: active ? [BoxShadow(color: HzTokens.amber.withOpacity(0.22), blurRadius: 14)] : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_items[i].$1 as IconData, size: 20, color: active ? HzTokens.amber : const Color(0xFF8DA2BA)),
                    const SizedBox(height: 2),
                    Text(_items[i].$2 as String, style: TextStyle(fontSize: 11, color: active ? HzTokens.amber : const Color(0xFF8DA2BA))),
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
