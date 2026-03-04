import 'package:flutter/material.dart';

import '../theme/hz_tokens.dart';
import 'hz_glass.dart';

class HzMetricTile extends StatelessWidget {
  const HzMetricTile({super.key, required this.label, required this.value, required this.unit, required this.color});

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return HzGlass(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withOpacity(0.20), blurRadius: 18)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(unit, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
