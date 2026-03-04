import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class HZMetricChip extends StatelessWidget {
  const HZMetricChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = HZTokens.cyan,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: HZTokens.bgElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: HZTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text('$label ', style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
