import 'package:flutter/material.dart';

import '../theme/hz_tokens.dart';

class HzGlowButton extends StatefulWidget {
  const HzGlowButton({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  State<HzGlowButton> createState() => _HzGlowButtonState();
}

class _HzGlowButtonState extends State<HzGlowButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final glow = 0.25 + (_controller.value * 0.18);
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: [Color(0xFFFFC36A), Color(0xFFFFA340)]),
              boxShadow: [BoxShadow(color: HzTokens.amber.withOpacity(glow), blurRadius: 22)],
            ),
            child: Text(widget.text, style: const TextStyle(color: Color(0xFF211000), fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
        );
      },
    );
  }
}
