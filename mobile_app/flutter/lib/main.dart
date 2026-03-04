import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const HelioZoneApp());
}

class HelioZoneApp extends StatelessWidget {
  const HelioZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B1117);
    const surface = Color(0xFF141C25);
    const accent = Color(0xFF38D39F);

    return MaterialApp(
      title: 'HelioZone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: Color(0xFF54A4FF),
          surface: surface,
        ),
        cardTheme: const CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 0;

  static const _titles = ['Home', 'Zones', 'Control', 'Sun', 'Analytics'];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeTab(),
      const ZonesTab(),
      const ControlTab(),
      const SunTab(),
      const AnalyticsTab(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_tabIndex])),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: pages[_tabIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (value) => setState(() => _tabIndex = value),
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

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _refreshCount = 0;

  @override
  Widget build(BuildContext context) {
    final zoneCards = [
      _ZoneLiveStatus(
        zoneName: 'Zone 1',
        ppfd: 412,
        dli: 24.8,
        brightness: 74,
        sunPhase: 'day',
        cloudFactor: 0.88,
      ),
      _ZoneLiveStatus(
        zoneName: 'Zone 2',
        ppfd: 285,
        dli: 16.9,
        brightness: 52,
        sunPhase: 'sunrise',
        cloudFactor: 0.93,
      ),
    ];

    return ListView(
      children: [
        if (kIsWeb)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Discovery is not available on web yet. Use Manual IP.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10),
                  _ManualIpRow(),
                ],
              ),
            ),
          ),
        if (kIsWeb) const SizedBox(height: 12),
        Row(
          children: [
            Text('Zone Live Status', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => setState(() => _refreshCount++),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('Mock update #$_refreshCount', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        ...zoneCards.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: c,
            )),
      ],
    );
  }
}

class _ManualIpRow extends StatelessWidget {
  const _ManualIpRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Manual IP (e.g. 192.168.1.44)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(onPressed: null, child: const Text('Connect')),
      ],
    );
  }
}

class _ZoneLiveStatus extends StatelessWidget {
  const _ZoneLiveStatus({
    required this.zoneName,
    required this.ppfd,
    required this.dli,
    required this.brightness,
    required this.sunPhase,
    required this.cloudFactor,
  });

  final String zoneName;
  final int ppfd;
  final double dli;
  final int brightness;
  final String sunPhase;
  final double cloudFactor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(zoneName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                Text('PPFD: $ppfd µmol/m²/s'),
                Text('DLI: ${dli.toStringAsFixed(1)} mol/m²/day'),
                Text('Brightness: $brightness%'),
                Text('Sun phase: $sunPhase'),
                Text('Cloud factor: ${cloudFactor.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ZonesTab extends StatelessWidget {
  const ZonesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final zones = const [
      ('Zone 1', 'flowers', 'seedling'),
      ('Zone 2', 'flowers', 'vegetative'),
      ('Zone 3', 'flowers', 'flowering'),
    ];

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add zone'),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: zones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final z = zones[i];
              return Card(
                child: ListTile(
                  title: Text(z.$1),
                  subtitle: Text('Culture: ${z.$2} • Stage: ${z.$3}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ControlTab extends StatefulWidget {
  const ControlTab({super.key});

  @override
  State<ControlTab> createState() => _ControlTabState();
}

class _ControlTabState extends State<ControlTab> {
  double master = 68;
  double white = 64;
  double blue = 58;
  double red = 52;
  double farRed = 34;

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: ${value.toStringAsFixed(0)}%'),
            Slider(value: value, min: 0, max: 100, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _slider('Master dimmer', master, (v) => setState(() => master = v)),
        const SizedBox(height: 10),
        _slider('White', white, (v) => setState(() => white = v)),
        const SizedBox(height: 10),
        _slider('Blue', blue, (v) => setState(() => blue = v)),
        const SizedBox(height: 10),
        _slider('Red', red, (v) => setState(() => red = v)),
        const SizedBox(height: 10),
        _slider('Far-Red', farRed, (v) => setState(() => farRed = v)),
      ],
    );
  }
}

class SunTab extends StatelessWidget {
  const SunTab({super.key});

  @override
  Widget build(BuildContext context) {
    const intensity = 72.0;
    const curve1 = 0.22;
    const curve2 = 0.46;
    const curve3 = 0.72;
    const curve4 = 0.88;

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live Sun', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text('Intensity: ${intensity.toStringAsFixed(0)}%'),
                const SizedBox(height: 10),
                const Text('Curve placeholder'),
                const SizedBox(height: 8),
                const LinearProgressIndicator(value: curve1),
                const SizedBox(height: 6),
                const LinearProgressIndicator(value: curve2),
                const SizedBox(height: 6),
                const LinearProgressIndicator(value: curve3),
                const SizedBox(height: 6),
                const LinearProgressIndicator(value: curve4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = const [
      ('Today DLI', '21.9 mol/m²/day'),
      ('Avg PPFD', '342 µmol/m²/s'),
      ('Photoperiod hours', '16.0 h'),
      ('Peak brightness', '91 %'),
    ];

    return GridView.builder(
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (_, i) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(metrics[i].$1, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(metrics[i].$2, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
