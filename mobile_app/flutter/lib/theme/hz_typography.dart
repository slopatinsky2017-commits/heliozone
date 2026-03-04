import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HzTypography {
  static TextTheme textTheme() {
    return TextTheme(
      displaySmall: GoogleFonts.spaceGrotesk(fontSize: 42, fontWeight: FontWeight.w700, color: Colors.white),
      headlineSmall: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
      titleLarge: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFD0DCEF)),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF96A8BF)),
      labelSmall: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFAEC1D9), fontWeight: FontWeight.w600),
    );
  }
}
