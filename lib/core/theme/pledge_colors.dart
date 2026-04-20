import 'package:flutter/material.dart';

/// StepStake — cohesive fintech × fitness palette + energy-field background tokens.
abstract final class PledgeColors {
  // —— Brand / primary ——
  static const Color primaryGreen = Color(0xFF34A853);
  static const Color primaryGreenDark = Color(0xFF2E7D47);

  // —— Accent (financial caution + warmth) ——
  static const Color penaltyAmber = Color(0xFFF59E0B);
  static const Color penaltyAmberBg = Color(0xFFFFF7ED);

  // —— Semantic ——
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenBg = Color(0xFFECFDF5);

  static const Color dangerRose = Color(0xFFEF4444);
  static const Color dangerRoseBg = Color(0xFFFEF2F2);

  // —— Text ——
  static const Color ink = Color(0xFF1A1C1E);
  static const Color inkMuted = Color(0xFF6B7280);
  static const Color inkSoft = Color(0xFF9CA3AF);

  // —— Surfaces ——
  /// Fallback when a solid page color is required (dialogs, tests).
  static const Color pageBg = Color(0xFFF7F5F3);

  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color cardBorder = Color(0xFFF0EEEC);
  static const Color secondaryButtonBg = Color(0xFFF3F2F0);
  static const Color calloutMutedBg = Color(0xFFF3F2F0);

  static const Color progressTrack = Color(0xFFE8E6E3);

  // —— Results / states ——
  static const Color failureWash = Color(0xFFFFF1F2);

  // —— Abstract “energy field” (main app background gradients) ——
  static const Color energyFieldTop = Color(0xFFFBFAF8);
  static const Color energyFieldMid = Color(0xFFF8F6F4);
  static const Color energyFieldBottom = Color(0xFFF3F2F6);

  /// Warm ember glow (radial accents).
  static const Color energyEmber = Color(0xFFE85D3C);

  /// Momentum streak (secondary warm accent).
  static const Color energyHeat = Color(0xFFF0A03A);

  /// Cool counterpart to ember — ties to primary, keeps finance trust.
  static const Color energyMomentum = Color(0xFF34A853);

  // —— Splash / dark canvas ——
  static const Color splashBg = Color(0xFF12141A);
  static const Color splashGradientTop = Color(0xFF13151C);
  static const Color splashGradientMid = Color(0xFF1A1715);
  static const Color splashGradientBottom = Color(0xFF151A1F);
}
