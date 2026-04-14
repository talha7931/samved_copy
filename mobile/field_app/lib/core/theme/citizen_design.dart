import 'package:flutter/material.dart';

import 'app_design.dart';

abstract final class CitizenDesign {
  static const Color primary = AppDesign.primaryNavy;
  static const Color primaryContainer = AppDesign.primaryContainerNavy;
  static const Color accent = AppDesign.accentOrange;
  static const Color surface = Color(0xFFFAF9FD);
  static const Color surfaceContainerLow = Color(0xFFF4F3F7);
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color onSurfaceVariant = Color(0xFF43474E);
  static const Color outlineVariant = Color(0xFFC4C6CF);
  static const Color tertiaryFixed = Color(0xFFFFDBCA);
  static const Color onTertiaryContainer = Color(0xFFE46500);

  static const LinearGradient navyGradient = AppDesign.navyGradient;
  static const LinearGradient orangeCtaGradient = AppDesign.orangeCtaGradient;

  static Color severityColor(ColorScheme cs, String? tier) {
    return AppDesign.severityColor(cs, tier);
  }
}
