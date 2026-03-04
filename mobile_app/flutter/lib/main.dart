import 'package:flutter/material.dart';

import 'screens/hz_cinematic_dashboard.dart';
import 'theme/hz_theme.dart';

void main() {
  runApp(const HelioZoneApp());
}

class HelioZoneApp extends StatelessWidget {
  const HelioZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelioZone',
      debugShowCheckedModeBanner: false,
      theme: HzTheme.dark(),
      home: const HzCinematicDashboard(),
    );
  }
}
