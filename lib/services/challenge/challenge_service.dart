import '../../core/date_utils.dart';
import '../../core/money.dart';
import '../../data/models/challenge.dart';
import '../../data/models/daily_entry.dart';
import '../../data/persistence/local_storage_repository.dart';
import '../wallet/wallet_service.dart';

class DailyEntryUpdateResult {
  final DailyEntry previousEntry;
  final DailyEntry updatedEntry;

  const DailyEntryUpdateResult({
    required this.previousEntry,
    required this.updatedEntry,
  });
}

class ChallengeService {
  final LocalStorageRepository _storage;
  final WalletService _walletService;

  const ChallengeService({
    required LocalStorageRepository storage,
    required WalletService walletService,
  })  : _storage = storage,
        _walletService = walletService;

  Future<Challenge?> loadActiveChallenge() => _storage.loadActiveChallenge();
  Future<Challenge?> loadLastCompletedChallenge() =>
      _storage.loadLastCompletedChallenge();

  Future<bool> hasActiveChallenge() async {
    final c = await loadActiveChallenge();
    return c != null && c.status == ChallengeStatus.active;
  }

  Future<Challenge> createChallenge({
    required int durationDays,
    required int depositPerDayDollars,
    required int dailyStepGoal,
    required int totalStepGoal,
    required DateTime now,
  }) async {
    final active = await loadActiveChallenge();
    if (active != null && active.status == ChallengeStatus.active) {
      throw StateError('An active challenge already exists.');
    }

    if (durationDays < 15) {
      throw ArgumentError.value(durationDays, 'durationDays', 'Minimum is 15.');
    }
    if (depositPerDayDollars < 1 || depositPerDayDollars > 5) {
      throw ArgumentError.value(
        depositPerDayDollars,
        'depositPerDayDollars',
        'Deposit per day must be between \$1 and \$5.',
      );
    }
    if (dailyStepGoal < 5000 || dailyStepGoal > 10000) {
      throw ArgumentError.value(
        dailyStepGoal,
        'dailyStepGoal',
        'Daily step goal must be between 5000 and 10000.',
      );
    }
    final minTotalStepGoal = (dailyStepGoal * durationDays * 0.5).ceil();
    if (totalStepGoal < minTotalStepGoal) {
      throw ArgumentError.value(
        totalStepGoal,
        'totalStepGoal',
        'Total step goal must be at least $minTotalStepGoal (daily goal × days × 0.5).',
      );
    }

    final challenge = Challenge.buildNew(
      now: now,
      durationDays: durationDays,
      depositPerDayDollars: depositPerDayDollars,
      dailyStepGoal: dailyStepGoal,
      totalStepGoal: totalStepGoal,
    );

    await _storage.saveActiveChallenge(challenge);
    await _walletService.recordChallengeDepositLocked(challenge: challenge);

    return challenge;
  }

  Future<DailyEntryUpdateResult> saveDailySteps({
    required String challengeId,
    required DateTime date,
    required int steps,
    required DateTime now,
  }) async {
    final challenge = await loadActiveChallenge();
    if (challenge == null || challenge.id != challengeId) {
      throw StateError('Active challenge not found.');
    }
    if (challenge.status != ChallengeStatus.active) {
      throw StateError('Challenge is not active.');
    }

    final nowDate = MvpDateUtils.dateOnly(now);
    final entryDate = MvpDateUtils.dateOnly(date);
    if (!MvpDateUtils.isSameDate(entryDate, nowDate)) {
      throw ArgumentError.value(
        date,
        'date',
        'You can only edit today\'s entry.',
      );
    }
    if (entryDate.isBefore(challenge.startDate) ||
        entryDate.isAfter(challenge.endDate)) {
      throw ArgumentError.value(date, 'date', 'Date is outside the challenge.');
    }

    // Ensure evaluation flags/lock state are up to date for today's edit.
    final evaluated = await _evaluateActiveChallengeForNow(
      challenge: challenge,
      now: now,
      persist: false,
    );

    final index =
        evaluated.dailyEntries.indexWhere(
          (e) => MvpDateUtils.isSameDate(e.date, entryDate),
        );
    if (index == -1) {
      throw StateError('Daily entry not found.');
    }
    final previousEntry = evaluated.dailyEntries[index];

    if (!previousEntry.editable) {
      throw StateError('Today\'s entry is locked.');
    }

    final updatedEntry = previousEntry.copyWith(
      steps: steps,
      stepsEntered: true,
      // hitDailyGoal/penalty/evaluationState will be recomputed below.
    );

    final updatedChallengeDailyEntries = [...evaluated.dailyEntries];
    updatedChallengeDailyEntries[index] = updatedEntry;

    final recomputedChallenge = await _recomputeTotalsAndEvaluateDailyEntries(
      challenge: evaluated.copyWith(dailyEntries: updatedChallengeDailyEntries),
      now: now,
    );

    await _storage.saveActiveChallenge(recomputedChallenge);

    return DailyEntryUpdateResult(previousEntry: previousEntry, updatedEntry: recomputedChallenge.dailyEntries[index]);
  }

  /// Ensures the active challenge is evaluated for the provided `now` date,
  /// and if the challenge ended, finalizes it exactly once.
  Future<void> ensureEvaluatedAndFinalizeIfNeeded({required DateTime now}) async {
    final active = await loadActiveChallenge();
    if (active == null) return;
    if (active.status != ChallengeStatus.active) return;

    final nowDate = MvpDateUtils.dateOnly(now);
    if (!nowDate.isBefore(active.endDate)) {
      await _finalizeChallenge(active: active, now: now);
      return;
    }

    final evaluated = await _evaluateActiveChallengeForNow(
      challenge: active,
      now: now,
      persist: true,
    );
    await _storage.saveActiveChallenge(evaluated);
  }

  Future<Challenge> evaluateActiveForNow({
    required Challenge challenge,
    required DateTime now,
  }) {
    return _evaluateActiveChallengeForNow(
      challenge: challenge,
      now: now,
      persist: false,
    );
  }

  Future<Challenge?> getActiveChallengeEvaluated() async {
    final active = await loadActiveChallenge();
    if (active == null) return null;
    if (active.status != ChallengeStatus.active) return null;
    return _evaluateActiveChallengeForNow(
      challenge: active,
      now: DateTime.now(),
      persist: false,
    );
  }

  Future<Challenge> _evaluateActiveChallengeForNow({
    required Challenge challenge,
    required DateTime now,
    required bool persist,
  }) async {
    final nowDate = MvpDateUtils.dateOnly(now);

    final updatedEntries = challenge.dailyEntries.map((entry) {
      final day = entry.date;
      final isPast = day.isBefore(nowDate);
      final isToday = MvpDateUtils.isSameDate(day, nowDate);

      if (isPast) {
        final hit = entry.steps >= entry.stepGoalForDay;
        final penaltyCents = hit ? 0 : _depositPerDayPenaltyCents(challenge);
        return entry.copyWith(
          evaluationState: DailyEntryEvaluationState.evaluated,
          hitDailyGoal: hit,
          dailyPenaltyAmountCents: penaltyCents,
          editable: false,
        );
      }

      if (isToday) {
        if (!entry.stepsEntered) {
          // Pending until user submits today's steps.
          return entry.copyWith(
            evaluationState: DailyEntryEvaluationState.pending,
            hitDailyGoal: false,
            dailyPenaltyAmountCents: 0,
            editable: true,
          );
        }

        final hit = entry.steps >= entry.stepGoalForDay;
        final penaltyCents = hit ? 0 : _depositPerDayPenaltyCents(challenge);
        return entry.copyWith(
          evaluationState: DailyEntryEvaluationState.evaluated,
          hitDailyGoal: hit,
          dailyPenaltyAmountCents: penaltyCents,
          editable: true,
        );
      }

      // Future day
      return entry.copyWith(
        evaluationState: DailyEntryEvaluationState.pending,
        hitDailyGoal: false,
        dailyPenaltyAmountCents: 0,
        editable: false,
      );
    }).toList(growable: false);

    // Progress metrics exclude pending days (including "today" until steps are submitted).
    var stepsAccumulated = 0;
    var penaltyAccumulatedCents = 0;
    for (final entry in updatedEntries) {
      final isPast = entry.date.isBefore(nowDate);
      final isToday = MvpDateUtils.isSameDate(entry.date, nowDate);
      final includeForProgress = isPast || (isToday && entry.stepsEntered);
      if (!includeForProgress) continue;
      stepsAccumulated += entry.steps;
      penaltyAccumulatedCents += entry.dailyPenaltyAmountCents;
    }

    final totalDepositCents = challenge.totalDeposit.cents;
    final refundableCents = (totalDepositCents - penaltyAccumulatedCents).clamp(0, totalDepositCents);

    final updatedChallenge = challenge.copyWith(
      dailyEntries: updatedEntries,
      totalStepsAccumulated: stepsAccumulated,
      totalPenaltyAmountCents: penaltyAccumulatedCents,
      refundableRemainingAmountCents: refundableCents,
      returnedAmountCents: 0,
      platformKeptAmountCents: 0,
      status: ChallengeStatus.active,
    );

    return updatedChallenge;
  }

  int _depositPerDayPenaltyCents(Challenge challenge) {
    // Penalty = 20% of that day's deposit allocation.
    // depositPerDay is stored as cents (whole-dollar -> cents multiple of 100).
    return (challenge.depositPerDay.cents / 5).round();
  }

  Future<Challenge> _recomputeTotalsAndEvaluateDailyEntries({
    required Challenge challenge,
    required DateTime now,
  }) async {
    // For MVP: totals always depend on evaluation rules for "active" challenges.
    final evaluated = await _evaluateActiveChallengeForNow(
      challenge: challenge,
      now: now,
      persist: false,
    );
    return evaluated;
  }

  Future<void> _finalizeChallenge({
    required Challenge active,
    required DateTime now,
  }) async {
    final nowDate = MvpDateUtils.dateOnly(now);
    if (nowDate.isBefore(active.endDate)) return;

    final evaluatedEntries = active.dailyEntries.map((entry) {
      // For finalization: evaluate all days in the challenge range.
      final isInRange = !entry.date.isAfter(active.endDate);
      if (!isInRange) {
        return entry.copyWith(
          evaluationState: DailyEntryEvaluationState.pending,
          hitDailyGoal: false,
          dailyPenaltyAmountCents: 0,
          editable: false,
        );
      }

      final hit = entry.steps >= entry.stepGoalForDay;
      final penaltyCents = hit ? 0 : _depositPerDayPenaltyCents(active);
      return entry.copyWith(
        evaluationState: DailyEntryEvaluationState.evaluated,
        hitDailyGoal: hit,
        dailyPenaltyAmountCents: penaltyCents,
        editable: false,
      );
    }).toList(growable: false);

    var totalSteps = 0;
    var totalPenaltyCents = 0;
    for (final entry in evaluatedEntries) {
      totalSteps += entry.steps;
      totalPenaltyCents += entry.dailyPenaltyAmountCents;
    }

    final refundableCents = (active.totalDeposit.cents - totalPenaltyCents).clamp(
      0,
      active.totalDeposit.cents,
    );

    final isSuccess = totalSteps >= active.totalStepGoal;

    final returnedCents = isSuccess ? refundableCents : 0;
    final platformKeptCents = isSuccess ? totalPenaltyCents : active.totalDeposit.cents;

    final finalized = active.copyWith(
      dailyEntries: evaluatedEntries,
      totalStepsAccumulated: totalSteps,
      totalPenaltyAmountCents: totalPenaltyCents,
      refundableRemainingAmountCents: refundableCents,
      returnedAmountCents: returnedCents,
      platformKeptAmountCents: platformKeptCents,
      status: isSuccess ? ChallengeStatus.success : ChallengeStatus.failed,
    );

    // Update wallet and persist challenge outcome exactly once.
    await _walletService.applyChallengeFinalization(challenge: finalized);
    await _storage.saveLastCompletedChallenge(finalized);
    await _storage.saveActiveChallenge(null);
  }

  /// Upward-only edits: duration, total steps, daily steps (today and future days use the new daily goal).
  Future<Challenge> increaseActiveChallengeGoals({
    required int newDurationDays,
    required int newTotalStepGoal,
    required int newDailyStepGoal,
    required DateTime now,
  }) async {
    final challenge = await loadActiveChallenge();
    if (challenge == null || challenge.status != ChallengeStatus.active) {
      throw StateError('No active challenge.');
    }
    if (newDurationDays < challenge.durationDays) {
      throw ArgumentError('Duration can only increase.');
    }
    if (newTotalStepGoal < challenge.totalStepGoal) {
      throw ArgumentError('Total step goal can only increase.');
    }
    if (newDailyStepGoal < challenge.dailyStepGoal) {
      throw ArgumentError('Daily step goal can only increase.');
    }
    if (newDailyStepGoal < 5000 || newDailyStepGoal > 10000) {
      throw ArgumentError.value(
        newDailyStepGoal,
        'newDailyStepGoal',
        'Daily step goal must be between 5000 and 10000.',
      );
    }
    final minTotal = (newDailyStepGoal * newDurationDays * 0.5).ceil();
    if (newTotalStepGoal < minTotal) {
      throw ArgumentError(
        'Total step goal must be at least $minTotal (daily × days × 0.5).',
      );
    }

    final nowDate = MvpDateUtils.dateOnly(now);
    var updated = challenge;
    final depositDollars = challenge.depositPerDay.cents ~/ 100;

    if (newDurationDays > challenge.durationDays) {
      final extra = newDurationDays - challenge.durationDays;
      final newEntries = [...challenge.dailyEntries];
      for (var i = 0; i < extra; i++) {
        final date = MvpDateUtils.addDays(challenge.endDate, i + 1);
        final isToday = MvpDateUtils.isSameDate(date, nowDate);
        newEntries.add(
          DailyEntry(
            date: date,
            steps: 0,
            hitDailyGoal: false,
            stepGoalForDay: newDailyStepGoal,
            depositAllocatedForDayDollars: depositDollars,
            dailyPenaltyAmountCents: 0,
            editable: isToday,
            evaluationState: DailyEntryEvaluationState.pending,
            stepsEntered: false,
          ),
        );
      }
      final extraCents = challenge.depositPerDay.cents * extra;
      await _walletService.recordAdditionalDepositLock(
        amount: Money(extraCents),
        challengeId: challenge.id,
      );
      updated = challenge.copyWith(
        durationDays: newDurationDays,
        endDate: MvpDateUtils.addDays(challenge.startDate, newDurationDays - 1),
        totalDeposit: Money(challenge.totalDeposit.cents + extraCents),
        dailyEntries: newEntries,
      );
    }

    final withGoals = updated.copyWith(
      dailyStepGoal: newDailyStepGoal,
      totalStepGoal: newTotalStepGoal,
      durationDays: newDurationDays,
      dailyEntries: updated.dailyEntries.map((e) {
        if (!e.date.isBefore(nowDate)) {
          return e.copyWith(stepGoalForDay: newDailyStepGoal);
        }
        return e;
      }).toList(),
    );

    final evaluated = await _evaluateActiveChallengeForNow(
      challenge: withGoals,
      now: now,
      persist: false,
    );
    await _storage.saveActiveChallenge(evaluated);
    return evaluated;
  }

  /// Clears the active challenge after moving refundable funds to forfeited / platform totals.
  Future<void> restartActiveChallenge() async {
    final challenge = await loadActiveChallenge();
    if (challenge == null || challenge.status != ChallengeStatus.active) {
      throw StateError('No active challenge.');
    }
    await _walletService.recordChallengeRestartForfeit(challenge: challenge);
    await _storage.saveActiveChallenge(null);
  }
}

