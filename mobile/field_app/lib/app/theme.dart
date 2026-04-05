import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimary = Color(0xFF022448);
const Color kPrimaryContainer = Color(0xFF1E3A5F);
const Color kTertiary = Color(0xFFE85D04);
const Color kSurface = Color(0xFFFAF9FC);
const Color kOnSurface = Color(0xFF1A1C1E);

ThemeData buildRoadNirmanTheme() {
  final base = const ColorScheme.light(
    primary: kPrimary,
    onPrimary: Colors.white,
    primaryContainer: kPrimaryContainer,
    onPrimaryContainer: Color(0xFFD5E3FF),
    secondary: Color(0xFF555F70),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD6E0F4),
    onSecondaryContainer: Color(0xFF3E4757),
    tertiary: kTertiary,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFDBCA),
    onTertiaryContainer: Color(0xFF783200),
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: kSurface,
    onSurface: kOnSurface,
    onSurfaceVariant: Color(0xFF43474E),
    outline: Color(0xFF74777F),
    outlineVariant: Color(0xFFC4C6CF),
    shadow: Color(0xFF1A1C1E),
    scrim: Color(0xFF000000),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF4F3F7),
    surfaceContainer: Color(0xFFEEEDEF),
    surfaceContainerHigh: Color(0xFFE9E7EB),
    surfaceContainerHighest: Color(0xFFE3E2E6),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: const Color(0xFFEDEFF3),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      bodyLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        color: kOnSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        color: kOnSurface,
      ),
      titleMedium: GoogleFonts.inter(
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
      color: base.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: base.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: base.outlineVariant.withValues(alpha: 0.45)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return base.primaryContainer.withValues(alpha: 0.15);
          }
          return base.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return base.primary;
          return base.onSurfaceVariant;
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: base.outlineVariant.withValues(alpha: 0.45)),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: base.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.inter(
        color: base.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.inter(
        color: base.onSurfaceVariant.withValues(alpha: 0.45),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: base.primary.withValues(alpha: 0.2)),
      ),
    ),
  );
}
