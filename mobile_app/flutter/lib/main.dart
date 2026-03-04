import 'package:flutter/material.dart';

import 'theme/theme.dart';
import 'theme/tokens.dart';
import 'widgets/app_scaffold.dart';
import 'widgets/hz_card.dart';
import 'widgets/hz_metric_chip.dart';
import 'widgets/hz_section_header.dart';
import 'widgets/hz_slider_tile.dart';
import 'widgets/mini_chart_placeholder.dart';

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
      theme: HZTheme.dark(),
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

    return HZAppScaffold(
      title: _titles[_tabIndex],
      selectedIndex: _tabIndex,
      onDestinationSelected: (value) => setState(() => _tabIndex = value),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_tabIndex),
          child: pages[_tabIndex],
        ),
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
  final _ipCtrl = TextEditingController();

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _heroHeader(),
        const SizedBox(height: HZTokens.s3),
        _manualIpCard(),
        const SizedBox(height: HZTokens.s4),
        HZSectionHeader(
          title: 'Zone Live Status',
          subtitle: 'Real-time mock telemetry • update #$_refreshCount',
          trailing: FilledButton.icon(
            onPressed: () => setState(() => _refreshCount++),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ),
        const SizedBox(height: HZTokens.s3),
        const _ZoneLiveCard(
          name: 'Zone 1',
          ppfd: '418 µmol/m²/s',
          dli: '25.2 mol/m²/day',
          brightness: '76%',
          phase: 'day',
          cloud: '0.89',
        ),
        const SizedBox(height: HZTokens.s3),
        const _ZoneLiveCard(
          name: 'Zone 2',
          ppfd: '292 µmol/m²/s',
          dli: '17.3 mol/m²/day',
          brightness: '54%',
          phase: 'sunrise',
          cloud: '0.93',
        ),
      ],
    );
  }

  Widget _heroHeader() {
    return HZCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HZTokens.rMd),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A2F2C), Color(0xFF1A2431)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(HZTokens.s4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(HZTokens.s3),
              decoration: BoxDecoration(
                color: const Color(0x332FD9A8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.energy_savings_leaf, color: HZTokens.mint),
            ),
            const SizedBox(width: HZTokens.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HelioZone', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Industrial Horticulture Control', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                _Badge(text: 'AUTO MODE', color: HZTokens.cyan),
                SizedBox(height: 6),
                _Badge(text: 'CONNECTED', color: HZTokens.mint),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _manualIpCard() {
    return HZCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Controller Access', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: HZTokens.s2),
          Text(
            'Use Manual IP for direct access on web (discovery support comes later).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: HZTokens.s3),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ipCtrl,
                  decoration: const InputDecoration(hintText: '192.168.1.44'),
                ),
              ),
              const SizedBox(width: HZTokens.s2),
              FilledButton(onPressed: () {}, child: const Text('Connect')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ZoneLiveCard extends StatelessWidget {
  const _ZoneLiveCard({
    required this.name,
    required this.ppfd,
    required this.dli,
    required this.brightness,
    required this.phase,
    required this.cloud,
  });

  final String name;
  final String ppfd;
  final String dli;
  final String brightness;
  final String phase;
  final String cloud;

  @override
  Widget build(BuildContext context) {
    return HZCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              const _Badge(text: 'flowers', color: HZTokens.mint),
            ],
          ),
          const SizedBox(height: HZTokens.s3),
          Wrap(
            spacing: HZTokens.s2,
            runSpacing: HZTokens.s2,
            children: [
              HZMetricChip(icon: Icons.wb_iridescent_rounded, label: 'PPFD', value: ppfd),
              HZMetricChip(icon: Icons.today_rounded, label: 'DLI', value: dli),
              HZMetricChip(icon: Icons.light_mode_rounded, label: 'Brightness', value: brightness),
              HZMetricChip(icon: Icons.wb_twilight_rounded, label: 'Phase', value: phase),
              HZMetricChip(icon: Icons.cloud_rounded, label: 'Cloud', value: cloud),
            ],
          ),
        ],
      ),
    );
  }
}

class ZonesTab extends StatelessWidget {
  const ZonesTab({super.key});

  @override
  Widget build(BuildContext context) {
    const zones = [
      ('Zone 1', 'seedling', 260, 14.4),
      ('Zone 2', 'vegetative', 420, 24.0),
      ('Zone 3', 'flowering', 620, 33.6),
    ];

    return Column(
      children: [
        HZSectionHeader(
          title: 'Zones',
          subtitle: 'Culture: flowers',
          trailing: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Add zone')),
        ),
        const SizedBox(height: HZTokens.s3),
        Expanded(
          child: ListView.separated(
            itemCount: zones.length,
            separatorBuilder: (_, __) => const SizedBox(height: HZTokens.s3),
            itemBuilder: (_, i) {
              final z = zones[i];
              return HZCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(z.$1),
                  subtitle: Text('flowers • target ${z.$3} PPFD • DLI ${z.$4.toStringAsFixed(1)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Badge(text: z.$2, color: HZTokens.amber),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const HZSectionHeader(title: 'Lighting Control', subtitle: 'Premium channel tuning'),
        const SizedBox(height: HZTokens.s3),
        HZSliderTile(icon: Icons.power_settings_new_rounded, label: 'Master dimmer', value: master, onChanged: (v) => setState(() => master = v)),
        const SizedBox(height: HZTokens.s3),
        HZSliderTile(icon: Icons.light_mode_rounded, label: 'White', value: white, onChanged: (v) => setState(() => white = v)),
        const SizedBox(height: HZTokens.s3),
        HZSliderTile(icon: Icons.water_drop_rounded, label: 'Blue', value: blue, onChanged: (v) => setState(() => blue = v)),
        const SizedBox(height: HZTokens.s3),
        HZSliderTile(icon: Icons.local_fire_department_rounded, label: 'Red', value: red, onChanged: (v) => setState(() => red = v)),
        const SizedBox(height: HZTokens.s3),
        HZSliderTile(icon: Icons.nightlight_round, label: 'Far-Red', value: farRed, onChanged: (v) => setState(() => farRed = v)),
      ],
    );
  }
}

class SunTab extends StatelessWidget {
  const SunTab({super.key});

  @override
  Widget build(BuildContext context) {
    const intensity = 0.74;
    return ListView(
      children: [
        const HZSectionHeader(title: 'Live Sun', subtitle: 'Dynamic model preview'),
        const SizedBox(height: HZTokens.s3),
        HZCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Intensity ${(intensity * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: HZTokens.s3),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(value: intensity, minHeight: 12),
              ),
              const SizedBox(height: HZTokens.s3),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('Sunrise 06:00'), Text('Sunset 18:00')],
              ),
              const SizedBox(height: HZTokens.s4),
              const Text('Curve placeholder'),
              const SizedBox(height: HZTokens.s2),
              const MiniChartPlaceholder(),
            ],
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
    const kpis = [
      ('Today DLI', '22.4', 'mol/m²/day', Icons.today_rounded),
      ('Avg PPFD', '351', 'µmol/m²/s', Icons.wb_iridescent_rounded),
      ('Photoperiod', '16.0', 'hours', Icons.schedule_rounded),
      ('Peak Brightness', '92', '%', Icons.bolt_rounded),
    ];

    return ListView(
      children: [
        const HZSectionHeader(title: 'Analytics', subtitle: 'Daily performance snapshot'),
        const SizedBox(height: HZTokens.s3),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kpis.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: HZTokens.s3,
            mainAxisSpacing: HZTokens.s3,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (_, i) => HZCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(kpis[i].$4 as IconData, color: HZTokens.cyan),
                const SizedBox(height: HZTokens.s2),
                Text(kpis[i].$1 as String, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 3),
                Text('${kpis[i].$2} ${kpis[i].$3}', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: HZTokens.s3),
        const HZCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('7-day trend'),
              SizedBox(height: HZTokens.s2),
              MiniChartPlaceholder(),
            ],
          ),
        )
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
