import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HzTypography {
  static TextTheme textTheme() {
    return TextTheme(
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: Colors.white,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFFCFDCEF),
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF99AFC8),
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: const Color(0xFFADC3DC),
      ),
    );
  }
}
