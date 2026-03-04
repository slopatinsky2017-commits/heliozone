import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'hz_card.dart';

class HZSliderTile extends StatelessWidget {
  const HZSliderTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return HZCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: HZTokens.cyan),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text('${value.toStringAsFixed(0)}%', key: ValueKey(value.toStringAsFixed(0))),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 100,
            activeColor: HZTokens.mint,
            inactiveColor: HZTokens.border,
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0%', style: TextStyle(fontSize: 12, color: Color(0xFF96A9BE))),
              Text('100%', style: TextStyle(fontSize: 12, color: Color(0xFF96A9BE))),
            ],
          ),
        ],
      ),
    );
  }
}
