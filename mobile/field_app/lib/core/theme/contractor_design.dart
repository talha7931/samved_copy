import 'package:flutter/material.dart';

import 'app_design.dart';

abstract final class ContractorDesign {
  static const Color background = Color(0xFFFAF9FD);
  static const Color primaryNavy = AppDesign.primaryNavy;
  static const Color primaryContainer = AppDesign.primaryContainerNavy;
  static const Color accent = AppDesign.accentOrange;
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFE46500);
  static const Color danger = Color(0xFFBA1A1A);

  static const LinearGradient primaryGradient = AppDesign.navyGradient;
  static const LinearGradient accentGradient = AppDesign.orangeCtaGradient;

  static Color severityColor(ColorScheme cs, String? tier) {
    return AppDesign.severityColor(cs, tier);
  }
}
