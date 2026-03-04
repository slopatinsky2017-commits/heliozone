import 'package:flutter/material.dart';

class SunCurveWidget extends StatelessWidget {
  const SunCurveWidget({super.key, required this.intensityPercent});

  final double intensityPercent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sun curve visualization'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: (intensityPercent / 100).clamp(0, 1)),
            const SizedBox(height: 8),
            Text('Current intensity: ${intensityPercent.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }
}
