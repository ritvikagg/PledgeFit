import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_controller/app_controller.dart';
import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/theme/pledge_product_rules.dart';
import '../../core/theme/pledge_surfaces.dart';
import '../../core/ui/kit/numeric_stepper_card.dart';
import '../../core/ui/kit/pledge_buttons.dart';
import '../../core/ui/kit/pledge_shell.dart';
import '../../data/models/challenge.dart';
import 'goal_confirm_sheet.dart';

/// Set a new goal when none exists, or increase goals / restart when active.
/// Business rules: [ChallengeService.increaseActiveChallengeGoals], [ChallengeService.restartActiveChallenge].
class UpdateGoalPage extends ConsumerStatefulWidget {
  const UpdateGoalPage({super.key});

  @override
  ConsumerState<UpdateGoalPage> createState() => _UpdateGoalPageState();
}

class _UpdateGoalPageState extends ConsumerState<UpdateGoalPage> {
  int _durationDays = PledgeProductRules.minChallengeDays;
  int _depositPerDayDollars = PledgeProductRules.defaultDepositPerDayDollars;
  int _dailyStepGoal = 8000;
  String? _error;
  bool _submitting = false;
  String? _lastChallengeSyncKey;

  String _challengeSyncKey(Challenge c) =>
      '${c.id}:${c.durationDays}:${c.totalStepGoal}:${c.dailyStepGoal}';

  /// Total steps for the challenge — derived from daily goal × duration (not a separate input).
  int get _computedTotalSteps => _dailyStepGoal * _durationDays;

  /// Active challenges may carry a legacy total above daily×days; never reduce below that.
  int _effectiveTotalSteps(Challenge? active) {
    if (active == null) return _computedTotalSteps;
    return max(_computedTotalSteps, active.totalStepGoal);
  }

  int get _minTotal =>
      (_dailyStepGoal * _durationDays * 0.5).ceil(); // mirrors ChallengeService

  void _syncFieldsFromProvider(AppModel model) {
    final a = model.activeChallenge;
    if (a != null) {
      final key = _challengeSyncKey(a);
      if (_lastChallengeSyncKey == key) return;
      _lastChallengeSyncKey = key;
      _durationDays = a.durationDays;
      _depositPerDayDollars = a.depositPerDay.cents ~/ 100;
      _dailyStepGoal = a.dailyStepGoal;
    } else if (_lastChallengeSyncKey != null) {
      _lastChallengeSyncKey = null;
      _durationDays = PledgeProductRules.minChallengeDays;
      _depositPerDayDollars = PledgeProductRules.defaultDepositPerDayDollars;
      _dailyStepGoal = 8000;
    }
  }

  Future<void> _confirmRestart(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restart goal?'),
        content: const Text(
          'This ends your current challenge and forfeits all refundable money from it. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: PledgeColors.dangerRose,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Forfeit & restart'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(appControllerProvider.notifier).restartActiveChallenge();
      if (!context.mounted) return;
      setState(() {
        _lastChallengeSyncKey = null;
        _durationDays = PledgeProductRules.minChallengeDays;
        _depositPerDayDollars = PledgeProductRules.defaultDepositPerDayDollars;
        _dailyStepGoal = 8000;
      });
      context.go('/home');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challenge ended. You can set a new goal.')),
      );
    } on Object catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = ref.read(appControllerProvider).value;
      if (model == null) return;
      final before = _lastChallengeSyncKey;
      _syncFieldsFromProvider(model);
      if (before != _lastChallengeSyncKey) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final modelAsync = ref.watch(appControllerProvider);

    ref.listen<AsyncValue<AppModel>>(appControllerProvider, (prev, next) {
      next.whenData((model) {
        final before = _lastChallengeSyncKey;
        _syncFieldsFromProvider(model);
        if (before != _lastChallengeSyncKey) {
          setState(() {});
        }
      });
    });

    return modelAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Error: $e')),
      ),
      data: (model) {
        final c = model.activeChallenge;
        final hasActive = c != null;
        final totalDeposit =
            Money(_durationDays * _depositPerDayDollars * 100);
        final penaltyPerMiss =
            Money((Money(_depositPerDayDollars * 100).cents / 5).round());
        final maxPenalty = Money(penaltyPerMiss.cents * _durationDays);

        return PledgePageScaffold(
          title: hasActive ? 'Update goal' : 'Set your goal',
          showBack: true,
          padding: EdgeInsets.zero,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: PledgeColors.dangerRose,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (hasActive) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PledgeColors.successGreenBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: PledgeColors.successGreen.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.trending_up, color: PledgeColors.successGreen),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You can only increase your commitment: more days '
                          'or a higher daily step goal. Reducing goals is not allowed.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Current challenge',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: PledgeColors.inkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${c.durationDays} days · '
                  '${formatWithCommas(c.dailyStepGoal)} steps/day · '
                  '${c.depositPerDay.format()}/day · '
                  '${formatWithCommas(c.totalStepGoal)} steps total (daily × days)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 20),
              ],
              PledgeNumericStepperCard(
                label: 'Challenge duration',
                value: _durationDays,
                unit: 'days',
                enabled: !hasActive ||
                    _durationDays < PledgeProductRules.maxChallengeDays,
                onIncrement: () {
                  if (_durationDays >= PledgeProductRules.maxChallengeDays) {
                    return;
                  }
                  setState(() => _durationDays++);
                },
                onDecrement: () {
                  if (hasActive) {
                    if (_durationDays <= c.durationDays) return;
                  } else {
                    if (_durationDays <= PledgeProductRules.minChallengeDays) {
                      return;
                    }
                  }
                  setState(() => _durationDays--);
                },
              ),
              const SizedBox(height: 14),
              PledgeNumericStepperCard(
                label: 'Deposit per day',
                value: _depositPerDayDollars,
                unit: 'USD / day',
                enabled: !hasActive,
                onIncrement: () {
                  if (_depositPerDayDollars >=
                      PledgeProductRules.maxDepositPerDayDollars) {
                    return;
                  }
                  setState(() => _depositPerDayDollars++);
                },
                onDecrement: () {
                  if (_depositPerDayDollars <=
                      PledgeProductRules.minDepositPerDayDollars) {
                    return;
                  }
                  setState(() => _depositPerDayDollars--);
                },
              ),
              if (hasActive)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Deposit per day is fixed for this challenge.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PledgeColors.inkMuted,
                        ),
                  ),
                ),
              const SizedBox(height: 14),
              PledgeNumericStepperCard(
                label: 'Daily step goal',
                value: _dailyStepGoal,
                unit: 'steps',
                enabled: !hasActive ||
                    _dailyStepGoal < PledgeProductRules.maxDailySteps,
                onIncrement: () {
                  if (_dailyStepGoal >= PledgeProductRules.maxDailySteps) return;
                  setState(() {
                    _dailyStepGoal = (_dailyStepGoal + 250).clamp(
                      PledgeProductRules.minDailySteps,
                      PledgeProductRules.maxDailySteps,
                    );
                  });
                },
                onDecrement: () {
                  final floor = hasActive
                      ? c.dailyStepGoal
                      : PledgeProductRules.minDailySteps;
                  if (_dailyStepGoal <= floor) return;
                  setState(() {
                    _dailyStepGoal = (_dailyStepGoal - 250).clamp(
                      floor,
                      PledgeProductRules.maxDailySteps,
                    );
                  });
                },
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: PledgeSurfaces.cardElevated(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasActive ? 'Updated summary' : 'Challenge summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _SummaryRow(
                      label: 'Steps per day',
                      value: '${formatWithCommas(_dailyStepGoal)} steps',
                    ),
                    _SummaryRow(
                      label: 'Dollars per day',
                      value: Money(_depositPerDayDollars * 100).format(),
                    ),
                    _SummaryRow(
                      label: 'Duration',
                      value: '$_durationDays days',
                    ),
                    const Divider(height: 28),
                    _SummaryRow(
                      label: 'Total steps',
                      value:
                          '${formatWithCommas(hasActive ? _effectiveTotalSteps(c) : _computedTotalSteps)} steps',
                      strong: true,
                    ),
                    _SummaryRow(
                      label: 'Total money',
                      value: totalDeposit.format(),
                      strong: true,
                    ),
                    const Divider(height: 28),
                    _SummaryRow(
                      label: 'Daily penalty (if missed)',
                      value: penaltyPerMiss.format(),
                      valueColor: PledgeColors.penaltyAmber,
                    ),
                    _SummaryRow(
                      label: 'Max possible penalty',
                      value: maxPenalty.format(),
                      valueColor: PledgeColors.penaltyAmber,
                    ),
                    const Divider(height: 28),
                    _SummaryRow(
                      label: 'If 100% successful',
                      value: '${totalDeposit.format()} returned',
                      valueColor: PledgeColors.successGreen,
                      strong: true,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: PledgeSurfaces.calloutMuted(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 20, color: PledgeColors.inkMuted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You lose 20% of each day\'s deposit when you miss '
                              'that day\'s step goal. Complete your full step commitment '
                              '(all days combined) by the end date to get your remaining balance back.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: PledgeColors.inkMuted,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (!hasActive)
                PledgePrimaryButton(
                  label: 'Start goal',
                  isLoading: _submitting,
                  onPressed: () async {
                    setState(() {
                      _error = null;
                    });
                    final confirmed = await showGoalConfirmSheet(
                      context: context,
                      stepsPerDay: _dailyStepGoal,
                      dollarsPerDay: _depositPerDayDollars,
                      numberOfDays: _durationDays,
                      totalSteps: _computedTotalSteps,
                      totalMoney: totalDeposit,
                    );
                    if (!confirmed || !context.mounted) return;

                    setState(() {
                      _submitting = true;
                    });
                    try {
                      await ref
                          .read(appControllerProvider.notifier)
                          .createChallenge(
                            durationDays: _durationDays,
                            depositPerDayDollars: _depositPerDayDollars,
                            dailyStepGoal: _dailyStepGoal,
                          );
                      if (!context.mounted) return;
                      context.go('/home');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Goal started — $_durationDays days locked in.',
                          ),
                        ),
                      );
                    } on Object catch (e) {
                      setState(() => _error = e.toString());
                    } finally {
                      if (mounted) setState(() => _submitting = false);
                    }
                  },
                )
              else
                PledgePrimaryButton(
                  label: 'Apply increases',
                  isLoading: _submitting,
                  onPressed: () async {
                    setState(() {
                      _error = null;
                      _submitting = true;
                    });
                    final newTotalGoal = _effectiveTotalSteps(c);
                    if (newTotalGoal < _minTotal) {
                      setState(() {
                        _error =
                            'Total steps must be at least $_minTotal (from your daily goal and days).';
                        _submitting = false;
                      });
                      return;
                    }
                    if (_durationDays < c.durationDays ||
                        newTotalGoal < c.totalStepGoal ||
                        _dailyStepGoal < c.dailyStepGoal) {
                      setState(() {
                        _error = 'Goals can only move upward.';
                        _submitting = false;
                      });
                      return;
                    }
                    if (_durationDays == c.durationDays &&
                        newTotalGoal == c.totalStepGoal &&
                        _dailyStepGoal == c.dailyStepGoal) {
                      setState(() {
                        _error = 'Increase at least one value to update.';
                        _submitting = false;
                      });
                      return;
                    }
                    try {
                      await ref
                          .read(appControllerProvider.notifier)
                          .increaseActiveChallengeGoals(
                            newDurationDays: _durationDays,
                            newTotalStepGoal: newTotalGoal,
                            newDailyStepGoal: _dailyStepGoal,
                          );
                      if (!context.mounted) return;
                      context.go('/home');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Goal updated.'),
                        ),
                      );
                    } on Object catch (e) {
                      setState(() => _error = e.toString());
                    } finally {
                      if (mounted) setState(() => _submitting = false);
                    }
                  },
                ),
              if (hasActive) ...[
                const SizedBox(height: 28),
                Text(
                  'Danger zone',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: PledgeColors.dangerRose,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Restarting ends this challenge and sends all refundable funds '
                  'to the platform as a forfeiture.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PledgeColors.inkMuted,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PledgeColors.dangerRose,
                      side: const BorderSide(color: PledgeColors.dangerRose),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _submitting ? null : () => _confirmRestart(context),
                    child: const Text('Restart goal'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.strong = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PledgeColors.inkMuted,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
                  color: valueColor ?? PledgeColors.ink,
                ),
          ),
        ],
      ),
    );
  }
}
