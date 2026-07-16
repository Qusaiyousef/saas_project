import os

app_theme_content = """import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Kinetic Enterprise (Light)
  static const Color lightBackground = Color(0xFFF8F9FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF0D9488); // Teal 600
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFF006A61);
  static const Color lightOnSurface = Color(0xFF0B1C30);
  static const Color lightOnSurfaceVariant = Color(0xFF45464D);
  static const Color lightOutline = Color(0xFFE2E8F0);
  static const Color lightError = Color(0xFFBA1A1A);

  // Kinetic Dark (Dark)
  static const Color darkBackground = Color(0xFF081425);
  static const Color darkSurface = Color(0xFF152031); // surface-container for cards
  static const Color darkPrimary = Color(0xFF57F1DB);
  static const Color darkOnPrimary = Color(0xFF003731);
  static const Color darkSecondary = Color(0xFF7BD0FF);
  static const Color darkOnSurface = Color(0xFFD8E3FB);
  static const Color darkOnSurfaceVariant = Color(0xFFBACAC5);
  static const Color darkOutline = Color(0xFF3C4A46); // outline-variant or #2A3548
  static const Color darkError = Color(0xFFFFB4AB);

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: lightPrimary,
      brightness: Brightness.light,
      primary: lightPrimary,
      onPrimary: lightOnPrimary,
      secondary: lightSecondary,
      surface: lightBackground,
      onSurface: lightOnSurface,
      error: lightError,
      outline: lightOutline,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      canvasColor: lightBackground,
      cardColor: lightSurface,
      dividerColor: lightOutline,
      iconTheme: const IconThemeData(color: lightOnSurfaceVariant),
      primaryIconTheme: const IconThemeData(color: lightPrimary),

      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: lightOnSurface,
        displayColor: lightOnSurface,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: lightOnSurfaceVariant),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: lightOnSurfaceVariant),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: lightOnPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      cardTheme: const CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: lightOutline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightOnSurface,
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: darkPrimary,
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      secondary: darkSecondary,
      surface: darkBackground,
      onSurface: darkOnSurface,
      error: darkError,
      outline: darkOutline,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,
      cardColor: darkSurface,
      dividerColor: darkOutline,
      iconTheme: const IconThemeData(color: darkOnSurfaceVariant),
      primaryIconTheme: const IconThemeData(color: darkOnSurface),

      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: darkOnSurface,
        displayColor: darkOnSurface,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: darkOnSurfaceVariant),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: darkOnSurfaceVariant),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: darkOutline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
"""

with open('lib/theme/app_theme.dart', 'w') as f:
    f.write(app_theme_content)

