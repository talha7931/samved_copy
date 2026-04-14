import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppDesign {
  // ── Brand Colors ─────────────────────────────────────
  static const Color primaryNavy = Color(0xFF0B1628);
  static const Color primaryContainerNavy = Color(0xFF1E3A5F);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentOrangeDeep = Color(0xFFEA580C);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color warningAmber = Color(0xFFF59E0B);

  // ── Gradients ────────────────────────────────────────
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

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
  );

  // ── Shadows ──────────────────────────────────────────
  /// Premium card shadow with subtle depth layering
  static List<BoxShadow> cardShadow(ColorScheme cs) => [
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Elevated shadow for modals/FABs
  static List<BoxShadow> elevatedShadow(ColorScheme cs) => [
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.06),
          blurRadius: 48,
          offset: const Offset(0, 16),
        ),
      ];

  // ── Severity ─────────────────────────────────────────
  static Color severityColor(ColorScheme cs, String? tier) {
    switch ((tier ?? '').toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'HIGH':
        return const Color(0xFFF97316);
      case 'MEDIUM':
        return const Color(0xFF3B82F6);
      case 'LOW':
      case 'RESOLVED':
        return const Color(0xFF16A34A);
      default:
        return cs.primary;
    }
  }

  static Color severityBackground(ColorScheme cs, String? tier) {
    final color = severityColor(cs, tier);
    return color.withValues(alpha: 0.10);
  }

  // ── Typography Helpers ───────────────────────────────
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

  /// Standard card decoration used across all screens
  static BoxDecoration cardDecoration(ColorScheme cs) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: cardShadow(cs),
      );

  /// Accent container for highlighted content
  static BoxDecoration accentContainer() => BoxDecoration(
        gradient: orangeCtaGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentOrange.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );
}
