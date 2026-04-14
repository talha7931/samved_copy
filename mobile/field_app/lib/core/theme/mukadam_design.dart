import 'package:flutter/material.dart';

import 'app_design.dart';

abstract final class MukadamDesign {
  static const Color background = Color(0xFFFAF9FD);
  static const Color primaryNavy = AppDesign.primaryNavy;
  static const Color primaryContainer = AppDesign.primaryContainerNavy;
  static const Color accent = AppDesign.accentOrange;
  static const Color surfaceContainerLow = Color(0xFFF4F3F7);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE8E8EC);
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color onSurfaceVariant = Color(0xFF43474E);
  static const Color error = Color(0xFFBA1A1A);
  static const Color tertiaryFixed = Color(0xFFFFDBCA);
  static const Color onTertiaryContainer = Color(0xFFE46500);
  static const Color secondaryContainer = Color(0xFFB5D0FD);
  static const Color success = Color(0xFF22C55E);

  static const LinearGradient primaryGradient = AppDesign.navyGradient;
  static const LinearGradient accentGradient = AppDesign.orangeCtaGradient;

  static Color severityBar(ColorScheme cs, String? tier) {
    return AppDesign.severityColor(cs, tier);
  }
}
