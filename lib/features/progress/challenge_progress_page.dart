import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_controller/app_controller.dart';
import '../../core/date_utils.dart';
import '../../core/money.dart';
import '../../core/ui/metric_row.dart';
import '../../core/ui/money_text.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/section_card.dart';
import '../../data/models/daily_entry.dart';
import '../../data/models/challenge.dart';

class ChallengeProgressPage extends ConsumerWidget {
  const ChallengeProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);
    final nowDate = MvpDateUtils.dateOnly(DateTime.now());

    return appState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (model) {
        final challenge = model.activeChallenge;
        if (challenge == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Challenge Progress')),
            body: Center(
              child: PrimaryButton(
                label: 'Create a Challenge',
                onPressed: () => context.go('/create'),
              ),
            ),
          );
        }

        final todays = challenge.dailyEntries.firstWhere(
          (e) => MvpDateUtils.isSameDate(e.date, nowDate),
          orElse: () => challenge.dailyEntries.first,
        );

        final totalProgress = (challenge.totalStepsAccumulated / challenge.totalStepGoal)
            .clamp(0, 1)
            .toDouble();

        int runningPenaltyCents = 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Challenge Progress'),
            actions: [
              IconButton(
                tooltip: 'Wallet',
                onPressed: () => context.go('/wallet'),
                icon: const Icon(Icons.account_balance_wallet_outlined),
              )
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SectionCard(
                  title: 'Totals (as of today)',
                  subtitle: const Text(
                    'Penalties only apply after daily submissions or when days pass.',
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        'Progress to total goal',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: totalProgress),
                      const SizedBox(height: 10),
                      Text(
                        '${challenge.totalStepsAccumulated} / ${challenge.totalStepGoal} steps',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      MetricRow(
                        label: 'Penalties so far',
                        value: MoneyText(challenge.totalPenaltyAmount, bold: true),
                      ),
                      MetricRow(
                        label: 'Refundable remaining',
                        value: MoneyText(challenge.refundableRemainingAmount, bold: true),
                      ),
                      const SizedBox(height: 16),
                      if (todays.editable)
                        PrimaryButton(
                          label: 'Enter Today’s Steps',
                          onPressed: () => context.go('/daily'),
                        ),
                    ],
                  ),
                ),
                ...challenge.dailyEntries.map(
                  (entry) {
                    final evaluated = entry.evaluationState == DailyEntryEvaluationState.evaluated;
                    final statusText = !evaluated
                        ? 'Pending'
                        : entry.hitDailyGoal
                            ? 'Hit daily goal'
                            : 'Missed daily goal';
                    final penaltyText = !evaluated
                        ? 'Pending'
                        : Money(entry.dailyPenaltyAmountCents).format();

                    if (evaluated) {
                      runningPenaltyCents += entry.dailyPenaltyAmountCents;
                    }

                    final runningRefundable = Money(
                      (challenge.totalDeposit.cents - runningPenaltyCents).clamp(
                        0,
                        challenge.totalDeposit.cents,
                      ),
                    );

                    final dayNumber = MvpDateUtils.dayNumber(challenge.startDate, entry.date);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Day $dayNumber • ${entry.date.month}/${entry.date.day}',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  if (entry.editable)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2DD4BF).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'Editable today',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text('Steps: ${entry.steps}'),
                                  ),
                                  Text(
                                    statusText,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: evaluated
                                              ? (entry.hitDailyGoal ? Colors.green : Colors.red)
                                              : Colors.black54,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Penalty: $penaltyText',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      evaluated
                                          ? 'Refundable after day: ${runningRefundable.format()}'
                                          : 'Refundable after day: Pending',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.black54,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

