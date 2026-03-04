import 'package:flutter/material.dart';

class HZAppScaffold extends StatelessWidget {
  const HZAppScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final String title;
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: body,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Zones'),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Control'),
          NavigationDestination(icon: Icon(Icons.wb_twilight_rounded), label: 'Sun'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Analytics'),
        ],
      ),
    );
  }
}
