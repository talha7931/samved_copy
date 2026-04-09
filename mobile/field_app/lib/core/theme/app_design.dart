import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppDesign {
  static const Color primaryNavy = Color(0xFF000E24);
  static const Color primaryContainerNavy = Color(0xFF022448);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentOrangeDeep = Color(0xFFEA580C);

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryNavy, primaryContainerNavy],
  );

  static const LinearGradient orangeCtaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentOrange, accentOrangeDeep],
  );

  static List<BoxShadow> cardShadow(ColorScheme cs) => [
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static Color severityColor(ColorScheme cs, String? tier) {
    switch ((tier ?? '').toUpperCase()) {
      case 'CRITICAL':
        return cs.error;
      case 'HIGH':
        return cs.onTertiaryContainer;
      case 'MEDIUM':
        return const Color(0xFF455F87);
      case 'LOW':
      case 'RESOLVED':
        return const Color(0xFF22C55E);
      default:
        return cs.primary;
    }
  }

  static Color severityBackground(ColorScheme cs, String? tier) {
    final color = severityColor(cs, tier);
    return color.withValues(alpha: 0.14);
  }

  static TextStyle mono(TextStyle? base) {
    final fallback = base ?? const TextStyle(fontSize: 14);
    return GoogleFonts.jetBrainsMono(
      textStyle: fallback,
      fontWeight: fallback.fontWeight ?? FontWeight.w700,
      color: fallback.color,
      height: fallback.height,
      letterSpacing: fallback.letterSpacing,
    );
  }
}
