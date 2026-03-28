import 'package:flutter/material.dart';

import '../../theme/pledge_colors.dart';

enum PledgeChipVariant { success, danger, neutral, today }

class PledgeStatusChip extends StatelessWidget {
  const PledgeStatusChip({
    super.key,
    required this.label,
    this.variant = PledgeChipVariant.neutral,
  });

  final String label;
  final PledgeChipVariant variant;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    switch (variant) {
      case PledgeChipVariant.success:
      case PledgeChipVariant.today:
        bg = PledgeColors.successGreenBg;
        fg = PledgeColors.successGreen;
        break;
      case PledgeChipVariant.danger:
        bg = PledgeColors.dangerRoseBg;
        fg = PledgeColors.dangerRose;
        break;
      case PledgeChipVariant.neutral:
        bg = const Color(0xFFF3F4F6);
        fg = PledgeColors.inkMuted;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
