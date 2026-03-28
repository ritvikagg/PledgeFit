import 'package:flutter/material.dart';

import '../../theme/pledge_colors.dart';

/// Card with large value, unit, and vertical stepper affordance.
class PledgeNumericStepperCard extends StatelessWidget {
  const PledgeNumericStepperCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.onIncrement,
    this.onDecrement,
    this.enabled = true,
  });

  final String label;
  final int value;
  final String unit;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final formatted = _formatInt(value);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PledgeColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: PledgeColors.inkMuted,
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  formatted,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: PledgeColors.ink,
                        height: 1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  unit,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PledgeColors.inkMuted,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton.filledTonal(
                onPressed: enabled ? onIncrement : null,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
              IconButton.filledTonal(
                onPressed: enabled ? onDecrement : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatInt(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-$buf' : buf.toString();
}
