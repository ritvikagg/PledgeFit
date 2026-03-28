import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_controller/app_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/circular_goal_ring.dart';
import '../../core/ui/kit/pledge_buttons.dart';
import '../../data/models/challenge.dart';

class ChallengeResultPage extends ConsumerStatefulWidget {
  const ChallengeResultPage({super.key});

  @override
  ConsumerState<ChallengeResultPage> createState() =>
      _ChallengeResultPageState();
}

class _ChallengeResultPageState extends ConsumerState<ChallengeResultPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(appControllerProvider.notifier).markLastResultShown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);

    return appState.when(
      loading: () => const Scaffold(
        backgroundColor: PledgeColors.pageBg,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: PledgeColors.pageBg,
        body: Center(child: Text('Error: $e')),
      ),
      data: (model) {
        final result = model.lastCompletedChallenge;
        if (result == null) {
          return Scaffold(
            backgroundColor: PledgeColors.pageBg,
            appBar: AppBar(
              title: const Text('Result'),
              backgroundColor: PledgeColors.pageBg,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: PledgePrimaryButton(
                  label: 'Back to home',
                  onPressed: () => context.go('/home'),
                ),
              ),
            ),
          );
        }

        final isSuccess = result.status == ChallengeStatus.success;
        final pct = (result.totalStepsAccumulated / result.totalStepGoal)
            .clamp(0.0, 1.0)
            .toDouble();

        return Scaffold(
          backgroundColor: PledgeColors.pageBg,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? PledgeColors.successGreenBg
                        : PledgeColors.failureWash,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isSuccess
                              ? PledgeColors.successGreen
                              : PledgeColors.dangerRose,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSuccess ? Icons.check_rounded : Icons.close_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isSuccess ? 'Challenge complete' : 'Challenge failed',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: PledgeColors.ink,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSuccess
                            ? 'You hit your total step goal. Remaining refundable balance returns to your wallet (after daily forfeitures).'
                            : 'You didn\'t reach the total step goal. Remaining locked stake is kept by the platform.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: PledgeColors.inkMuted,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 20),
                      CircularGoalRing(
                        size: 176,
                        strokeWidth: 12,
                        progress: pct,
                        centerTitle: '${(pct * 100).round()}%',
                        centerSubtitle:
                            '${formatWithCommas(result.totalStepsAccumulated)} steps',
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: PledgeColors.card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Financial breakdown',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 18),
                          _Row(
                            label: 'Total steps',
                            value: formatWithCommas(result.totalStepsAccumulated),
                          ),
                          _Row(
                            label: 'Step target',
                            value: formatWithCommas(result.totalStepGoal),
                          ),
                          _Row(
                            label: 'Original deposit',
                            value: result.totalDeposit.format(),
                          ),
                          _Row(
                            label: 'Penalties incurred',
                            value: '-${result.totalPenaltyAmount.format()}',
                            valueColor: PledgeColors.penaltyAmber,
                          ),
                          _Row(
                            label: 'Amount returned',
                            value: result.returnedAmount.format(),
                            valueColor: PledgeColors.successGreen,
                          ),
                          _Row(
                            label: 'Kept by platform',
                            value: result.platformKeptAmount.format(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PledgePrimaryButton(
                      label: 'Start new challenge',
                      icon: Icons.add_rounded,
                      onPressed: () => context.go('/goal'),
                    ),
                    const SizedBox(height: 12),
                    PledgeSecondaryButton(
                      label: 'Back to home',
                      onPressed: () => context.go('/home'),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

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
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? PledgeColors.ink,
                ),
          ),
        ],
      ),
    );
  }
}
