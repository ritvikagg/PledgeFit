import 'package:flutter/material.dart';

import 'pledge_colors.dart';

/// Global multiplier for warm glow blobs (0.35 = calmer, 1.0 = default, 1.6 = bolder).
const double kPledgeBackgroundEnergy = 1.0;

enum PledgeBackgroundVariant {
  /// Light “energy field” for most of the app.
  main,

  /// Dark, ember-accented canvas behind splash / brand moments.
  splash,
}

/// Full-bleed branded background. Place behind content via [MaterialApp.builder]
/// or a local [Stack]; keep [Scaffold.backgroundColor] transparent.
class PledgeAppBackground extends StatelessWidget {
  const PledgeAppBackground({
    super.key,
    this.variant = PledgeBackgroundVariant.main,
    this.energyMultiplier = kPledgeBackgroundEnergy,
  });

  final PledgeBackgroundVariant variant;
  final double energyMultiplier;

  @override
  Widget build(BuildContext context) {
    final m = energyMultiplier.clamp(0.25, 2.0);
    return switch (variant) {
      PledgeBackgroundVariant.main => _MainEnergyField(m: m),
      PledgeBackgroundVariant.splash => _SplashEnergyField(m: m),
    };
  }
}

class _MainEnergyField extends StatelessWidget {
  const _MainEnergyField({required this.m});

  final double m;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                PledgeColors.energyFieldTop,
                PledgeColors.energyFieldMid,
                PledgeColors.energyFieldBottom,
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: _GlowBlob(
            diameter: 340,
            colors: [
              PledgeColors.energyEmber.withValues(alpha: 0.14 * m),
              Colors.transparent,
            ],
          ),
        ),
        Align(
          alignment: const Alignment(-0.85, -0.9),
          child: _GlowBlob(
            diameter: 300,
            colors: [
              PledgeColors.energyMomentum.withValues(alpha: 0.1 * m),
              Colors.transparent,
            ],
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: _GlowBlob(
            diameter: 220,
            colors: [
              PledgeColors.primaryGreen.withValues(alpha: 0.06 * m),
              Colors.transparent,
            ],
          ),
        ),
      ],
    );
  }
}

class _SplashEnergyField extends StatelessWidget {
  const _SplashEnergyField({required this.m});

  final double m;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                PledgeColors.splashGradientTop,
                PledgeColors.splashGradientMid,
                PledgeColors.splashGradientBottom,
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _GlowBlob(
            diameter: 420,
            colors: [
              PledgeColors.energyEmber.withValues(alpha: 0.22 * m),
              Colors.transparent,
            ],
          ),
        ),
        Align(
          alignment: const Alignment(0.9, -0.6),
          child: _GlowBlob(
            diameter: 260,
            colors: [
              PledgeColors.energyHeat.withValues(alpha: 0.12 * m),
              Colors.transparent,
            ],
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.diameter,
    required this.colors,
  });

  final double diameter;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: colors,
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
