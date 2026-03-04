import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class MiniChartPlaceholder extends StatelessWidget {
  const MiniChartPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    const bars = [0.3, 0.5, 0.4, 0.65, 0.55, 0.8, 0.62, 0.7];
    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars
            .map(
              (v) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    height: 72 * v,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(colors: [HZTokens.cyan, HZTokens.mint]),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
