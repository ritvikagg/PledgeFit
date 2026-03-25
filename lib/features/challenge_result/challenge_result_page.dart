import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_controller/app_controller.dart';
import '../../core/ui/money_text.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/section_card.dart';
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
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (model) {
        final result = model.lastCompletedChallenge;
        if (result == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Challenge Result')),
            body: Center(
              child: PrimaryButton(
                label: 'Go to Dashboard',
                onPressed: () => context.go('/home'),
              ),
            ),
          );
        }

        final isSuccess = result.status == ChallengeStatus.success;
        final title = isSuccess ? 'Success' : 'Failed';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Challenge Result'),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SectionCard(
                  title: title,
                  subtitle: Text(
                    isSuccess
                        ? 'You hit the TOTAL step goal by the end.'
                        : 'You did not reach the TOTAL step goal by the end.',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        '${result.totalStepsAccumulated} / ${result.totalStepGoal} steps',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 12),
                      _BreakdownRow(
                        label: 'Original deposit',
                        value: MoneyText(result.totalDeposit, bold: true),
                      ),
                      _BreakdownRow(
                        label: 'Total daily penalties (lost)',
                        value: MoneyText(result.totalPenaltyAmount, bold: true),
                      ),
                      _BreakdownRow(
                        label: 'Amount returned to wallet',
                        value: MoneyText(result.returnedAmount, bold: true),
                      ),
                      _BreakdownRow(
                        label: 'Amount kept by platform',
                        value: MoneyText(result.platformKeptAmount, bold: true),
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 14),
                      Text(
                        'Key distinction: daily penalties are separate from total-goal completion. You can succeed overall even with daily misses, as long as your TOTAL steps reach the target.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PrimaryButton(
                    label: 'Start a new challenge',
                    onPressed: () => context.go('/create'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final Widget value;

  const _BreakdownRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          value,
        ],
      ),
    );
  }
}

