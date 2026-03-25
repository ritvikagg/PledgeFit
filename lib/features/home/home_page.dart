import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_controller/app_controller.dart';
import '../../core/date_utils.dart';
import '../../core/ui/money_text.dart';
import '../../core/ui/metric_row.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/section_card.dart';
import '../../data/models/challenge.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);

    return appState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (model) {
        final active = model.activeChallenge;
        final nowDate = MvpDateUtils.dateOnly(DateTime.now());

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
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
                if (active != null)
                  _ActiveChallengeCard(
                    model: model,
                    activeChallenge: active,
                    nowDate: nowDate,
                  )
                else
                  _EmptyStateCard(
                    onCreate: () => context.go('/create'),
                  ),
                const SizedBox(height: 10),
                _FooterNote(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FooterNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        'No payments or health integrations for this MVP. Everything is local and mock-only.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black54,
            ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyStateCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'No active challenge',
      subtitle: const Text('Create one to start building streak-proof accountability.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          PrimaryButton(
            label: 'Create a Challenge',
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

class _ActiveChallengeCard extends StatelessWidget {
  final AppModel model;
  final Challenge activeChallenge;
  final DateTime nowDate;

  const _ActiveChallengeCard({
    required this.model,
    required this.activeChallenge,
    required this.nowDate,
  });

  @override
  Widget build(BuildContext context) {
    final challenge = activeChallenge;

    final currentDay = MvpDateUtils.dayNumber(challenge.startDate, nowDate)
        .clamp(1, challenge.durationDays);

    final todaysEntry = challenge.dailyEntries.firstWhere(
      (e) => MvpDateUtils.isSameDate(e.date, nowDate),
      orElse: () => challenge.dailyEntries.first,
    );

    final totalProgress = (challenge.totalStepsAccumulated / challenge.totalStepGoal)
        .clamp(0, 1)
        .toDouble();

    final dailyProgress =
        (todaysEntry.steps / challenge.dailyStepGoal).clamp(0, 1).toDouble();

    return SectionCard(
      title: 'Active Step Challenge',
      subtitle: Text(
        'Day $currentDay of ${challenge.durationDays} • Ends on ${challenge.endDate.month}/${challenge.endDate.day}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 2),
          Text(
            'Progress to total goal',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: totalProgress),
          const SizedBox(height: 10),
          Text(
            '${challenge.totalStepsAccumulated.toString()} / ${challenge.totalStepGoal} steps',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Text(
            'Today’s steps',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: dailyProgress),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${todaysEntry.steps} / ${challenge.dailyStepGoal} steps',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (!todaysEntry.stepsEntered)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '(not submitted yet)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          MetricRow(
            label: 'Total deposited',
            value: MoneyText(
              model.wallet.totalDeposited,
              bold: true,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          MetricRow(
            label: 'Penalties so far',
            value: MoneyText(
              challenge.totalPenaltyAmount,
              style: Theme.of(context).textTheme.bodyMedium,
              bold: true,
            ),
          ),
          MetricRow(
            label: 'Refundable remaining',
            value: MoneyText(
              challenge.refundableRemainingAmount,
              style: Theme.of(context).textTheme.bodyMedium,
              bold: true,
            ),
          ),
          MetricRow(
            label: 'Wallet available balance',
            value: MoneyText(
              model.wallet.availableBalance,
              style: Theme.of(context).textTheme.bodyMedium,
              bold: true,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: todaysEntry.editable ? 'Enter Today’s Steps' : 'View Progress',
                  onPressed: todaysEntry.editable
                      ? () => context.go('/daily')
                      : () => context.go('/progress'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/progress'),
                  child: const Text('Challenge Progress'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

