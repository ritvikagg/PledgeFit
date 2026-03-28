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
import '../../services/challenge/challenge_service.dart';

class DailyEntryPage extends ConsumerStatefulWidget {
  const DailyEntryPage({super.key});

  @override
  ConsumerState<DailyEntryPage> createState() => _DailyEntryPageState();
}

class _DailyEntryPageState extends ConsumerState<DailyEntryPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stepsController;
  bool _isSaving = false;
  DailyEntryUpdateResult? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _stepsController = TextEditingController();
  }

  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            title: 'Daily steps',
            showBack: true,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No challenge to log',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
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

        final todayEntry = challenge.dailyEntries.firstWhere(
          (e) => MvpDateUtils.isSameDate(e.date, nowDate),
          orElse: () => challenge.dailyEntries.first,
        );

        final dayNum =
            MvpDateUtils.dayNumber(challenge.startDate, todayEntry.date);

        if (_stepsController.text.isEmpty) {
          _stepsController.text = todayEntry.steps.toString();
        }

        final fieldEnabled = isDemo || todayEntry.editable;
        final canPersist = !isDemo && todayEntry.editable;
        final parsedSteps = int.tryParse(_stepsController.text.trim()) ?? 0;
        final previewHit = parsedSteps >= todayEntry.stepGoalForDay;
        final penaltyIfMiss = Money(challenge.depositPerDay.cents ~/ 5);
        final dailyPct = (parsedSteps / todayEntry.stepGoalForDay)
            .clamp(0.0, 1.0)
            .toDouble();

        final header =
            'DAY $dayNum · ${formatMonthDay(todayEntry.date).toUpperCase()}';

        return PledgePageScaffold(
          title: 'Enter Today\'s Steps',
          showBack: true,
          padding: EdgeInsets.zero,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (isDemo)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PledgeColors.successGreenBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Demo preview — create a challenge to save real entries.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: PledgeColors.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        header,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: PledgeColors.inkMuted,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stepsController,
                              enabled: fieldEnabled,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: fieldEnabled
                                        ? PledgeColors.ink
                                        : PledgeColors.inkSoft,
                                  ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              validator: (value) {
                                final p = int.tryParse(value?.trim() ?? '');
                                if (p == null) return 'Enter a number';
                                if (p < 0) return 'Invalid';
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          Column(
                            children: [
                              IconButton.filledTonal(
                                onPressed: !fieldEnabled
                                    ? null
                                    : () {
                                        final v = int.tryParse(
                                                _stepsController.text) ??
                                            0;
                                        _stepsController.text =
                                            (v + 500).toString();
                                        setState(() {});
                                      },
                                icon: const Icon(Icons.keyboard_arrow_up),
                              ),
                              IconButton.filledTonal(
                                onPressed: !fieldEnabled
                                    ? null
                                    : () {
                                        final v = int.tryParse(
                                                _stepsController.text) ??
                                            0;
                                        _stepsController.text =
                                            (v - 500).clamp(0, 1 << 30).toString();
                                        setState(() {});
                                      },
                                icon: const Icon(Icons.keyboard_arrow_down),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        'steps',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: PledgeColors.inkMuted,
                            ),
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: dailyPct,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE5E7EB),
                          color: PledgeColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            formatWithCommas(parsedSteps),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: PledgeColors.inkMuted,
                                ),
                          ),
                          const Spacer(),
                          Text(
                            'Goal: ${formatWithCommas(todayEntry.stepGoalForDay)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: PledgeColors.inkMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: previewHit
                              ? PledgeColors.successGreenBg
                              : PledgeColors.penaltyAmberBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          previewHit
                              ? 'Daily goal met — no penalty today.'
                              : 'Below goal — ${penaltyIfMiss.format()} would be forfeited for today (20% of ${challenge.depositPerDay.format()}).',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: PledgeColors.ink,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PledgePrimaryButton(
                label: _isSaving ? 'Saving…' : 'Save today\'s steps',
                isLoading: _isSaving,
                onPressed: isDemo
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Create a challenge from the New tab to save real step entries.',
                            ),
                          ),
                        );
                      }
                    : !canPersist
                        ? null
                        : () async {
                            final ok =
                                _formKey.currentState?.validate() ?? false;
                            if (!ok) return;
                            setState(() => _isSaving = true);
                            final steps =
                                int.parse(_stepsController.text.trim());
                            try {
                              final result = await ref
                                  .read(appControllerProvider.notifier)
                                  .saveTodaySteps(steps);
                              if (!context.mounted) return;
                              setState(() {
                                _isSaving = false;
                                _lastUpdate = result;
                              });
                              final next = ref.read(appControllerProvider);
                              final showResult =
                                  next.value?.shouldShowLatestResult ?? false;
                              if (showResult &&
                                  next.value?.activeChallenge == null &&
                                  context.mounted) {
                                context.go('/result');
                              }
                            } catch (e) {
                              setState(() => _isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$e')),
                                );
                              }
                            }
                          },
              ),
              const SizedBox(height: 12),
              PledgeSecondaryButton(
                label: 'Cancel',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              if (_lastUpdate != null && !isDemo) ...[
                const SizedBox(height: 20),
                _UpdateExplanation(update: _lastUpdate!),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _UpdateExplanation extends StatelessWidget {
  const _UpdateExplanation({required this.update});

  final DailyEntryUpdateResult update;

  @override
  Widget build(BuildContext context) {
    final prev = update.previousEntry;
    final next = update.updatedEntry;
    String m(int c) => Money(c).format();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PledgeColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PledgeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What changed',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Before: penalty ${m(prev.dailyPenaltyAmountCents)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'After: penalty ${m(next.dailyPenaltyAmountCents)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
