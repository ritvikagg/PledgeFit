import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_controller/app_controller.dart';
import '../../core/money.dart';
import '../../core/ui/metric_row.dart';
import '../../core/ui/money_text.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/section_card.dart';

class CreateChallengePage extends ConsumerStatefulWidget {
  const CreateChallengePage({super.key});

  @override
  ConsumerState<CreateChallengePage> createState() => _CreateChallengePageState();
}

class _CreateChallengePageState extends ConsumerState<CreateChallengePage> {
  final _formKey = GlobalKey<FormState>();
  int _durationDays = 15;
  int _depositPerDayDollars = 3;
  int _dailyStepGoal = 7000;
  late TextEditingController _totalStepGoalController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _totalStepGoalController =
        TextEditingController(text: (_dailyStepGoal * _durationDays).toString());
  }

  @override
  void dispose() {
    _totalStepGoalController.dispose();
    super.dispose();
  }

  int get _totalStepGoal =>
      int.tryParse(_totalStepGoalController.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final modelAsync = ref.watch(appControllerProvider);

    return modelAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (model) {
        final active = model.activeChallenge;
        final totalDepositCents = _durationDays * _depositPerDayDollars * 100;
        final totalDeposit = Money(totalDepositCents);
        final penaltyPerMissCents =
            (Money(_depositPerDayDollars * 100).cents / 5).round();
        final penaltyPerMiss = Money(penaltyPerMissCents);

        final minTotal = (_dailyStepGoal * _durationDays * 0.5).ceil();

        final disabled = active != null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Create Challenge'),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SectionCard(
                  title: 'Challenge settings',
                  subtitle: disabled
                      ? const Text('You already have an active challenge.')
                      : const Text('Deposit money and hit your steps goals.'),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        Row(
                          children: [
                            const Text('Duration'),
                            const Spacer(),
                            Text('$_durationDays days'),
                          ],
                        ),
                        Slider(
                          value: _durationDays.toDouble(),
                          min: 15,
                          max: 60,
                          divisions: 45,
                          label: '$_durationDays days',
                          onChanged: disabled
                              ? null
                              : (v) {
                                  setState(() {
                                    _durationDays = v.round();
                                    _totalStepGoalController.text =
                                        (_dailyStepGoal * _durationDays).toString();
                                  });
                                },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Deposit per day'),
                            const Spacer(),
                            Text('\$$_depositPerDayDollars/day'),
                          ],
                        ),
                        DropdownButton<int>(
                          value: _depositPerDayDollars,
                          items: [1, 2, 3, 4, 5]
                              .map((v) =>
                                  DropdownMenuItem(value: v, child: Text('\$$v')))
                              .toList(),
                          onChanged: disabled
                              ? null
                              : (v) => setState(() {
                                    _depositPerDayDollars = v ?? 3;
                                  }),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Daily step goal'),
                            const Spacer(),
                            Text('$_dailyStepGoal steps'),
                          ],
                        ),
                        Slider(
                          value: _dailyStepGoal.toDouble(),
                          min: 5000,
                          max: 10000,
                          divisions: (10000 - 5000) ~/ 250,
                          label: '$_dailyStepGoal',
                          onChanged: disabled
                              ? null
                              : (v) {
                                  setState(() {
                                    _dailyStepGoal = (v / 250).round() * 250;
                                    _totalStepGoalController.text =
                                        (_dailyStepGoal * _durationDays).toString();
                                  });
                                },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _totalStepGoalController,
                          enabled: !disabled,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Total step goal (end of challenge)',
                            hintText: 'e.g. ${_dailyStepGoal * _durationDays}',
                            suffixText: 'steps',
                          ),
                          validator: (value) {
                            final parsed =
                                int.tryParse(value?.trim() ?? '') ?? 0;
                            if (parsed == 0) return 'Enter a total step goal.';
                            if (parsed < minTotal) {
                              return 'Must be >= $minTotal (daily goal × days × 0.5).';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        MetricRow(
                          label: 'Minimum allowed total',
                          value: Text(
                            '$minTotal',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Money rules (MVP mock)',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Total deposit',
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            MoneyText(totalDeposit, bold: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Miss a day => penalty (20%)',
                              ),
                            ),
                            MoneyText(penaltyPerMiss, bold: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Even if you succeed overall (hit the total step goal), missed daily goals reduce your refundable balance.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: disabled
                                    ? 'Finish or fail current challenge'
                                    : 'Create Challenge',
                                onPressed: disabled
                                    ? null
                                    : () async {
                                        setState(() => _error = null);
                                        final ok = _formKey.currentState?.validate() ??
                                            false;
                                        if (!ok) return;

                                        try {
                                          final created =
                                              await ref
                                                  .read(appControllerProvider.notifier)
                                                  .createChallenge(
                                                    durationDays: _durationDays,
                                                    depositPerDayDollars:
                                                        _depositPerDayDollars,
                                                    dailyStepGoal: _dailyStepGoal,
                                                    totalStepGoal: _totalStepGoal,
                                                  );
                                          if (!mounted) return;
                                          context.go('/home');
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Challenge created. You have ${created.durationDays} days.'),
                                            ),
                                          );
                                        } on Object catch (e) {
                                          setState(() => _error = e.toString());
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Best-case refundable if you never miss daily goals: ${totalDeposit.format()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
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

