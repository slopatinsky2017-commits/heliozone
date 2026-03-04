import 'package:flutter/material.dart';

import 'hz_glass.dart';

class HzZoneSelector extends StatelessWidget {
  const HzZoneSelector({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return HzGlass(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          dropdownColor: const Color(0xFF121B29),
          items: const [
            DropdownMenuItem(value: 'Zone 1', child: Text('Zone 1')),
            DropdownMenuItem(value: 'Zone 2', child: Text('Zone 2')),
            DropdownMenuItem(value: 'Zone 3', child: Text('Zone 3')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
