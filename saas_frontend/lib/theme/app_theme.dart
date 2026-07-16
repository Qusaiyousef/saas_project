import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─────────────────────────────────────────────────────────
  //  Kinetic Enterprise (Light) – from DESIGN.md
  // ─────────────────────────────────────────────────────────
  static const Color lightBackground     = Color(0xFFF8F9FF); // surface / background
  static const Color lightSurface        = Color(0xFFFFFFFF); // surface-container-lowest (cards)
  static const Color lightSurfaceContainer = Color(0xFFE5EEFF); // surface-container
  static const Color lightSurfaceHigh    = Color(0xFFDCE9FF); // surface-container-high (table headers)
  static const Color lightPrimary        = Color(0xFF006A61); // secondary = teal action color
  static const Color lightOnPrimary      = Color(0xFFFFFFFF);
  static const Color lightOnSurface      = Color(0xFF0B1C30); // on-surface (primary text)
  static const Color lightOnSurfaceVar   = Color(0xFF45464D); // on-surface-variant (secondary text)
  static const Color lightOutline        = Color(0xFFC6C6CD); // outline-variant (borders)
  static const Color lightOutlineStrong  = Color(0xFF76777D); // outline
  static const Color lightError          = Color(0xFFBA1A1A);
  static const Color lightOnError        = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFFFDAD6);

  // ─────────────────────────────────────────────────────────
  //  Kinetic Dark – from DESIGN.md
  // ─────────────────────────────────────────────────────────
  static const Color darkBackground      = Color(0xFF081425); // surface / background
  static const Color darkSurface         = Color(0xFF152031); // surface-container (cards)
  static const Color darkSurfaceHigh     = Color(0xFF1F2A3C); // surface-container-high
  static const Color darkSurfaceHighest  = Color(0xFF2A3548); // surface-container-highest
  static const Color darkPrimary         = Color(0xFF57F1DB); // primary (teal)
  static const Color darkOnPrimary       = Color(0xFF003731); // on-primary
  static const Color darkSecondary       = Color(0xFF7BD0FF); // secondary (blue)
  static const Color darkOnSurface       = Color(0xFFD8E3FB); // on-surface (primary text)
  static const Color darkOnSurfaceVar    = Color(0xFFBACAC5); // on-surface-variant (secondary text)
  static const Color darkOutline         = Color(0xFF3C4A46); // outline-variant (borders)
  static const Color darkOutlineStrong   = Color(0xFF859490); // outline
  static const Color darkError           = Color(0xFFFFB4AB);
  static const Color darkOnError         = Color(0xFF690005);
  static const Color darkErrorContainer  = Color(0xFF93000A);

  // ─────────────────────────────────────────────────────────
  //  LIGHT THEME
  // ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light();

    final cs = ColorScheme(
      brightness: Brightness.light,
      primary: lightPrimary,
      onPrimary: lightOnPrimary,
      secondary: lightPrimary,
      onSecondary: lightOnPrimary,
      error: lightError,
      onError: lightOnError,
      surface: lightBackground,
      onSurface: lightOnSurface,
      onSurfaceVariant: lightOnSurfaceVar,
      outline: lightOutlineStrong,
      outlineVariant: lightOutline,
      errorContainer: lightErrorContainer,
      onErrorContainer: const Color(0xFF93000A),
      surfaceContainerHighest: lightSurfaceHigh,
    );

    return base.copyWith(
      colorScheme: cs,
      scaffoldBackgroundColor: lightBackground,
      canvasColor: lightBackground,
      cardColor: lightSurface,
      dividerColor: lightOutline,
      shadowColor: const Color(0x140F172A), // rgba(15,23,42,0.08)
      iconTheme: const IconThemeData(color: lightOnSurfaceVar),

      // Typography
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: lightOnSurface,
        displayColor: lightOnSurface,
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: lightOutline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: lightOutline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: lightPrimary, width: 2)),
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: lightOnSurfaceVar),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: lightOnSurfaceVar),
      ),

      // Buttons
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightOnSurface,
          side: const BorderSide(color: lightOutline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Cards
      cardTheme: const CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: lightOutline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightOnSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      // Drawer / Dialog / BottomSheet
      drawerTheme: const DrawerThemeData(backgroundColor: lightSurface, surfaceTintColor: Colors.transparent),
      dialogTheme: const DialogThemeData(backgroundColor: lightSurface, surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: lightSurface, surfaceTintColor: Colors.transparent),

      // DataTable
      dataTableTheme: DataTableThemeData(
        headingTextStyle: GoogleFonts.inter(color: lightOnSurfaceVar, fontWeight: FontWeight.w600, fontSize: 12),
        dataTextStyle: GoogleFonts.inter(color: lightOnSurface, fontSize: 14),
        headingRowColor: const WidgetStatePropertyAll(lightSurfaceHigh),
        dividerThickness: 1,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(textColor: lightOnSurface, iconColor: lightOnSurfaceVar),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceContainer,
        labelStyle: GoogleFonts.inter(color: lightOnSurface),
        side: const BorderSide(color: lightOutline),
        shape: const StadiumBorder(),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF213145),
        contentTextStyle: GoogleFonts.inter(color: const Color(0xFFEAF1FF)),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: const Color(0xFF213145), borderRadius: BorderRadius.circular(4)),
        textStyle: GoogleFonts.inter(color: const Color(0xFFEAF1FF), fontSize: 12),
      ),

      // PopupMenu
      popupMenuTheme: const PopupMenuThemeData(
        color: lightSurface,
        surfaceTintColor: Colors.transparent,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? lightPrimary : lightOutlineStrong),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? lightPrimary.withValues(alpha: 0.3) : lightOutline),
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: lightPrimary,
        unselectedLabelColor: lightOnSurfaceVar,
        indicatorColor: lightPrimary,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  DARK THEME
  // ─────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark();

    final cs = ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      secondary: darkSecondary,
      onSecondary: const Color(0xFF00354A),
      error: darkError,
      onError: darkOnError,
      surface: darkBackground,
      onSurface: darkOnSurface,
      onSurfaceVariant: darkOnSurfaceVar,
      outline: darkOutlineStrong,
      outlineVariant: darkOutline,
      errorContainer: darkErrorContainer,
      onErrorContainer: const Color(0xFFFFDAD6),
      surfaceContainerHighest: darkSurfaceHighest,
    );

    return base.copyWith(
      colorScheme: cs,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,
      cardColor: darkSurface,
      dividerColor: darkOutline,
      shadowColor: Colors.transparent,
      iconTheme: const IconThemeData(color: darkOnSurfaceVar),

      // Typography
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: darkOnSurface,
        displayColor: darkOnSurface,
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: darkOutline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: darkOutline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: darkPrimary, width: 2)),
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: darkOnSurfaceVar),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: darkOnSurfaceVar),
        prefixIconColor: darkOnSurfaceVar,
        suffixIconColor: darkOnSurfaceVar,
      ),

      // Buttons
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkOnSurface,
          side: const BorderSide(color: darkOutline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Cards
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: darkOutline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      // Drawer / Dialog / BottomSheet
      drawerTheme: const DrawerThemeData(backgroundColor: darkSurface, surfaceTintColor: Colors.transparent),
      dialogTheme: const DialogThemeData(backgroundColor: darkSurface, surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: darkSurface, surfaceTintColor: Colors.transparent),

      // DataTable
      dataTableTheme: DataTableThemeData(
        headingTextStyle: GoogleFonts.inter(color: darkOnSurfaceVar, fontWeight: FontWeight.w600, fontSize: 12),
        dataTextStyle: GoogleFonts.inter(color: darkOnSurface, fontSize: 14),
        headingRowColor: const WidgetStatePropertyAll(darkSurfaceHigh),
        dividerThickness: 1,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(textColor: darkOnSurface, iconColor: darkOnSurfaceVar),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceHigh,
        labelStyle: GoogleFonts.inter(color: darkOnSurface),
        side: const BorderSide(color: darkOutline),
        shape: const StadiumBorder(),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceHighest,
        contentTextStyle: GoogleFonts.inter(color: darkOnSurface),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: darkSurfaceHighest, borderRadius: BorderRadius.circular(4)),
        textStyle: GoogleFonts.inter(color: darkOnSurface, fontSize: 12),
      ),

      // PopupMenu
      popupMenuTheme: const PopupMenuThemeData(
        color: darkSurfaceHigh,
        surfaceTintColor: Colors.transparent,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? darkPrimary : darkOutlineStrong),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? darkPrimary.withValues(alpha: 0.3) : darkOutline),
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: darkPrimary,
        unselectedLabelColor: darkOnSurfaceVar,
        indicatorColor: darkPrimary,
      ),
    );
  }
}
