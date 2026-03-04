import 'package:flutter/material.dart';

import 'tokens.dart';

class HZTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: HZTokens.bg,
      colorScheme: const ColorScheme.dark(
        primary: HZTokens.mint,
        secondary: HZTokens.cyan,
        surface: HZTokens.bgCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: HZTokens.bgCard,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HZTokens.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HZTokens.rMd),
          borderSide: const BorderSide(color: HZTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HZTokens.rMd),
          borderSide: const BorderSide(color: HZTokens.border),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        titleLarge: const TextStyle(fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: const TextStyle(color: Color(0xFFCDDAEA)),
        bodySmall: const TextStyle(color: Color(0xFF9BAEC3)),
      ),
    );
  }
}
