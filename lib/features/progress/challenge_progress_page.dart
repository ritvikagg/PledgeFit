import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/presentation.dart';
import '../../app_controller/app_controller.dart';
import '../../core/date_utils.dart';
import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/pledge_buttons.dart';
import '../../core/ui/kit/pledge_shell.dart';
import '../../core/ui/kit/status_chip.dart';
import '../../data/models/daily_entry.dart';

class ChallengeProgressPage extends ConsumerWidget {
  const ChallengeProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);
    final challenge = ref.watch(displayChallengeProvider);
    final isDemo = ref.watch(isUiDemoChallengeProvider);
    final nowDate = MvpDateUtils.dateOnly(DateTime.now());

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
        if (challenge == null) {
          return PledgePageScaffold(
            title: 'Challenge progress',
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No active goal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a goal to see daily progress here.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PledgeColors.inkMuted,
                        ),
                  ),
                  const SizedBox(height: 16),
                  PledgePrimaryButton(
                    label: 'Set your first goal',
                    onPressed: () => context.go('/goal'),
                  ),
                ],
              ),
            ),
          );
        }

        final totalPct = (challenge.totalStepsAccumulated / challenge.totalStepGoal)
            .clamp(0.0, 1.0)
            .toDouble();

        int runningPenaltyCents = 0;

        return PledgePageScaffold(
          title: 'Challenge progress',
          padding: EdgeInsets.zero,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              if (isDemo)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PledgeColors.successGreenBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Investor demo data',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              Text(
                'Totals (ledger)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Per-day rows show goal vs steps; challenge totals use the full ledger (may differ slightly from row sums in demo).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PledgeColors.inkMuted,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: PledgeColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: totalPct,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: PledgeColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${formatWithCommas(challenge.totalStepsAccumulated)} / ${formatWithCommas(challenge.totalStepGoal)} steps',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PledgeColors.inkMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Penalties (challenge)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: PledgeColors.inkMuted,
                              ),
                        ),
                        Text(
                          challenge.totalPenaltyAmount.format(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: PledgeColors.penaltyAmber,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Refundable remaining',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: PledgeColors.inkMuted,
                              ),
                        ),
                        Text(
                          challenge.refundableRemainingAmount.format(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: PledgeColors.successGreen,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Daily timeline',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              ...challenge.dailyEntries.map((entry) {
                final dayNum =
                    MvpDateUtils.dayNumber(challenge.startDate, entry.date);
                final isFuture = entry.date.isAfter(nowDate);
                final isToday = MvpDateUtils.isSameDate(entry.date, nowDate);

                if (entry.evaluationState == DailyEntryEvaluationState.evaluated) {
                  runningPenaltyCents += entry.dailyPenaltyAmountCents;
                }
                final runningRef = Money(
                  (challenge.totalDeposit.cents - runningPenaltyCents).clamp(
                    0,
                    challenge.totalDeposit.cents,
                  ),
                );

                late PledgeChipVariant chipVariant;
                late String chipLabel;
                if (isFuture) {
                  chipVariant = PledgeChipVariant.neutral;
                  chipLabel = 'Upcoming';
                } else if (isToday) {
                  chipVariant = PledgeChipVariant.today;
                  chipLabel = 'Today';
                } else if (entry.hitDailyGoal) {
                  chipVariant = PledgeChipVariant.success;
                  chipLabel = 'Goal hit';
                } else {
                  chipVariant = PledgeChipVariant.danger;
                  chipLabel = 'Missed';
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PledgeColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$dayNum',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: PledgeColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isFuture
                                          ? '—'
                                          : '${formatWithCommas(entry.steps)} steps',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  PledgeStatusChip(
                                    label: chipLabel,
                                    variant: chipVariant,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${formatMonthDay(entry.date)} · Goal: ${formatWithCommas(entry.stepGoalForDay)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: PledgeColors.inkMuted),
                              ),
                              if (!isFuture &&
                                  entry.dailyPenaltyAmountCents > 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '-${Money(entry.dailyPenaltyAmountCents).format()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: PledgeColors.penaltyAmber,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                              if (!isFuture &&
                                  entry.evaluationState ==
                                      DailyEntryEvaluationState.evaluated) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Refundable after day: ${runningRef.format()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: PledgeColors.inkSoft),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
