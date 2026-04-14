import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimary = Color(0xFF0B1628);
const Color kPrimaryContainer = Color(0xFF1E3A5F);
const Color kTertiary = Color(0xFFF97316);
const Color kSurface = Color(0xFFFAFBFD);
const Color kOnSurface = Color(0xFF0F172A);

ThemeData buildRoadNirmanTheme() {
  final base = const ColorScheme.light(
    primary: kPrimary,
    onPrimary: Colors.white,
    primaryContainer: kPrimaryContainer,
    onPrimaryContainer: Color(0xFFD5E3FF),
    secondary: Color(0xFF475569),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD6E0F4),
    onSecondaryContainer: Color(0xFF334155),
    tertiary: kTertiary,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFDBCA),
    onTertiaryContainer: Color(0xFF783200),
    error: Color(0xFFDC2626),
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    surface: kSurface,
    onSurface: kOnSurface,
    onSurfaceVariant: Color(0xFF475569),
    outline: Color(0xFF94A3B8),
    outlineVariant: Color(0xFFE2E8F0),
    shadow: Color(0xFF0F172A),
    scrim: Color(0xFF000000),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF8FAFC),
    surfaceContainer: Color(0xFFF1F5F9),
    surfaceContainerHigh: Color(0xFFE2E8F0),
    surfaceContainerHighest: Color(0xFFCBD5E1),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      bodyLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        color: kOnSurface,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        color: kOnSurface,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        color: const Color(0xFF64748B),
        height: 1.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF64748B),
        letterSpacing: 0.8,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        color: kOnSurface,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        color: kOnSurface,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        color: kOnSurface,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        color: kOnSurface,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        color: kOnSurface,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        color: kOnSurface,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        color: kOnSurface,
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: base.onSurface,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        fontSize: 20,
        color: base.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: base.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: base.outlineVariant.withValues(alpha: 0.6)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return base.primaryContainer.withValues(alpha: 0.12);
          }
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return base.primary;
          return base.onSurfaceVariant;
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: base.outlineVariant.withValues(alpha: 0.4)),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: base.primaryContainer.withValues(alpha: 0.12),
      side: BorderSide(color: base.outlineVariant.withValues(alpha: 0.4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    dividerTheme: DividerThemeData(
      color: base.outlineVariant.withValues(alpha: 0.3),
      thickness: 1,
      space: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: GoogleFonts.inter(
        color: base.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.inter(
        color: base.onSurfaceVariant.withValues(alpha: 0.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: base.outlineVariant.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: base.outlineVariant.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: base.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: base.error),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      backgroundColor: base.onSurface,
      contentTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      selectedItemColor: base.primary,
      unselectedItemColor: base.onSurfaceVariant,
      selectedLabelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w800,
        fontSize: 11,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kTertiary,
      foregroundColor: Colors.white,
      elevation: 4,
      focusElevation: 6,
      hoverElevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      surfaceTintColor: Colors.transparent,
    ),
  );
}
