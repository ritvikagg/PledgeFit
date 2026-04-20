import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/pledge_buttons.dart';

/// Centered confirmation before creating a new challenge — returns `true` if confirmed.
Future<bool> showGoalConfirmSheet({
  required BuildContext context,
  required int stepsPerDay,
  required int dollarsPerDay,
  required int numberOfDays,
  required int totalSteps,
  required Money totalMoney,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        child: Material(
          color: PledgeColors.card,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Start this challenge?',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please confirm your challenge details before starting.',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: PledgeColors.inkMuted,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 22),
                _ConfirmRow(
                  label: 'Dollars per day',
                  value: Money(dollarsPerDay * 100).format(),
                ),
                _ConfirmRow(
                  label: 'Steps per day',
                  value: '${formatWithCommas(stepsPerDay)} steps',
                ),
                _ConfirmRow(
                  label: 'Duration',
                  value: '$numberOfDays days',
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: PledgeColors.successGreenBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: PledgeColors.successGreen.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your full commitment',
                        textAlign: TextAlign.center,
                        style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                              color: PledgeColors.inkMuted,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total steps',
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: PledgeColors.inkMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${formatWithCommas(totalSteps)} steps',
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: PledgeColors.primaryGreenDark,
                                        height: 1.1,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total money',
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: PledgeColors.inkMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalMoney.format(),
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: PledgeColors.primaryGreenDark,
                                        height: 1.1,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Totals = daily amounts × $numberOfDays days',
                        textAlign: TextAlign.center,
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: PledgeColors.inkMuted,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                PledgePrimaryButton(
                  label: 'Start goal',
                  onPressed: () => Navigator.pop(ctx, true),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return ok ?? false;
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PledgeColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
