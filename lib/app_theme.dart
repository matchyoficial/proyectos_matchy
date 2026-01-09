import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MatchyTheme {
  // Colores base
  static const Color primaryPurple = Color(0xFF7B2FFF);
  static const Color primaryBlue = Color(0xFF2F80ED);
  static const Color backgroundDark = Color(0xFF05030A);

  static ThemeData get theme {
    final base = ThemeData.dark();

    return base.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
    );
  }
}
