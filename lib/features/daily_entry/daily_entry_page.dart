import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_controller/app_controller.dart';
import '../../core/date_utils.dart';
import '../../core/money.dart';
import '../../core/ui/money_text.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/section_card.dart';
import '../../data/models/daily_entry.dart';
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
    final nowDate = MvpDateUtils.dateOnly(DateTime.now());

    return appState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (model) {
        final challenge = model.activeChallenge;
        if (challenge == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Daily Steps')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No active challenge.'),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Create a challenge',
                    onPressed: () => context.go('/create'),
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

        _stepsController.text = _stepsController.text.isEmpty
            ? todayEntry.steps.toString()
            : _stepsController.text;

        final canEdit = todayEntry.editable;

        final prevStateText = _buildEntryStateText(todayEntry);

        return Scaffold(
          appBar: AppBar(title: const Text('Daily Step Entry')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SectionCard(
                  title: 'Today (${todayEntry.date.month}/${todayEntry.date.day})',
                  subtitle: Text(
                    'Daily goal: ${challenge.dailyStepGoal} steps • Deposit per day: ${challenge.depositPerDay.format()}.',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!canEdit)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Your entry for today is locked.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.black54),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _stepsController,
                              enabled: canEdit,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Steps',
                                hintText: 'Enter steps for today',
                              ),
                              validator: (value) {
                                final parsed =
                                    int.tryParse(value?.trim() ?? '');
                                if (parsed == null) return 'Enter steps as a number.';
                                if (parsed < 0) return 'Steps cannot be negative.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            PrimaryButton(
                              label: _isSaving ? 'Saving...' : 'Save Today’s Steps',
                              onPressed: canEdit
                                  ? () async {
                                      final ok =
                                          _formKey.currentState?.validate() ??
                                              false;
                                      if (!ok) return;
                                      setState(() => _isSaving = true);

                                      final steps =
                                          int.parse(_stepsController.text.trim());
                                      try {
                                        final result = await ref
                                            .read(appControllerProvider.notifier)
                                            .saveTodaySteps(steps);
                                        if (!mounted) return;
                                        setState(() {
                                          _isSaving = false;
                                          _lastUpdate = result;
                                        });

                                        final nextState =
                                            ref.read(appControllerProvider);
                                        final showResult =
                                            nextState.value?.shouldShowLatestResult ??
                                                false;
                                        if (showResult &&
                                            nextState.value?.activeChallenge ==
                                                null) {
                                          context.go('/result');
                                        }
                                      } catch (e) {
                                        setState(() => _isSaving = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('$e')),
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Current evaluation: $prevStateText',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (_lastUpdate != null)
                        _UpdateExplanation(update: _lastUpdate!),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _RulesNote(),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildEntryStateText(DailyEntry entry) {
    if (entry.evaluationState == DailyEntryEvaluationState.pending) {
      return 'pending (save steps to evaluate penalty)';
    }
    return entry.hitDailyGoal
        ? 'daily goal met (no penalty)'
        : 'daily goal missed (penalty applies)';
  }
}

class _UpdateExplanation extends StatelessWidget {
  final DailyEntryUpdateResult update;

  const _UpdateExplanation({required this.update});

  @override
  Widget build(BuildContext context) {
    final prev = update.previousEntry;
    final next = update.updatedEntry;

    String moneyText(int cents) => Money(cents).format();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'What changed',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Before: ${prev.evaluationState == DailyEntryEvaluationState.pending ? "pending" : (prev.hitDailyGoal ? "met" : "missed")} • Penalty: ${moneyText(prev.dailyPenaltyAmountCents)}',
        ),
        const SizedBox(height: 4),
        Text(
          'After: ${next.evaluationState == DailyEntryEvaluationState.pending ? "pending" : (next.hitDailyGoal ? "met" : "missed")} • Penalty: ${moneyText(next.dailyPenaltyAmountCents)}',
        ),
        const SizedBox(height: 10),
        Text(
          'Your challenge refundable balance will update immediately based on today’s penalty.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
        ),
      ],
    );
  }
}

class _RulesNote extends StatelessWidget {
  const _RulesNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Success is based on the TOTAL step goal by the end of the challenge. Daily penalties still apply if you miss today’s daily step goal.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black54,
            ),
      ),
    );
  }
}

