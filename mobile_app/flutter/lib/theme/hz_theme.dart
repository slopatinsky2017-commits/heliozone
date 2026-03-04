import 'package:flutter/material.dart';

import 'hz_tokens.dart';
import 'hz_typography.dart';

class HzTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HzTokens.bg0,
      textTheme: HzTypography.textTheme(),
      colorScheme: const ColorScheme.dark(
        primary: HzTokens.amber,
        secondary: HzTokens.cyan,
        surface: HzTokens.bg2,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x66182637),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HzTokens.rMd),
          borderSide: const BorderSide(color: HzTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HzTokens.rMd),
          borderSide: const BorderSide(color: HzTokens.border),
        ),
      ),
    );
  }
}
