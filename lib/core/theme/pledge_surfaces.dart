import 'package:flutter/material.dart';

import 'pledge_colors.dart';

/// Shared card / surface treatments so screens stay on-brand.
abstract final class PledgeSurfaces {
  static BoxDecoration cardElevated({
    double radius = 20,
    List<BoxShadow> shadows = const [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 16,
        offset: Offset(0, 6),
      ),
    ],
  }) {
    return BoxDecoration(
      color: PledgeColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: PledgeColors.cardBorder),
      boxShadow: shadows,
    );
  }

  static BoxDecoration cardFlat({double radius = 16}) {
    return BoxDecoration(
      color: PledgeColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: PledgeColors.cardBorder),
    );
  }

  static BoxDecoration calloutMuted({double radius = 14}) {
    return BoxDecoration(
      color: PledgeColors.calloutMutedBg,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}
