import '../core/date_utils.dart';
import '../core/money.dart';
import '../data/models/challenge.dart';
import '../data/models/daily_entry.dart';
import '../data/models/mock_user.dart';
import '../data/models/wallet.dart';

/// Seed/mock data for development.
///
/// The app does not auto-load these by default (so the MVP rules about
/// creating a challenge still apply). You can wire this into `AppController`
/// later when you want a demo experience.
class MockSeed {
  static MockUser demoUser() {
    return MockUser(
      id: 'user_demo',
      createdAt: DateTime.now(),
      lastResultShown: false,
    );
  }

  static Wallet demoWallet() {
    return Wallet(
      availableBalance: Money(0),
      totalDeposited: Money(0),
      totalReturned: Money(0),
      totalForfeited: Money(0),
      totalPlatformKept: Money(0),
      transactions: const [],
    );
  }

  static Challenge demoChallenge({
    required DateTime startDate,
    int durationDays = 15,
    int depositPerDayDollars = 1,
    int dailyStepGoal = 7000,
    int totalStepGoal = 7000 * 15,
  }) {
    final start = MvpDateUtils.dateOnly(startDate);
    final end = MvpDateUtils.addDays(start, durationDays - 1);
    final depositPerDay = Money(depositPerDayDollars * 100);
    final totalDeposit = Money(durationDays * depositPerDayDollars * 100);

    final entries = <DailyEntry>[];
    for (var i = 0; i < durationDays; i++) {
      final date = MvpDateUtils.addDays(start, i);
      final isPast = date.isBefore(MvpDateUtils.dateOnly(DateTime.now()));
      final steps = isPast ? dailyStepGoal : 0;
      final hit = steps >= dailyStepGoal;
      final penaltyCents = hit ? 0 : (depositPerDay.cents / 5).round();

      entries.add(
        DailyEntry(
          date: date,
          steps: steps,
          hitDailyGoal: hit,
          stepGoalForDay: dailyStepGoal,
          depositAllocatedForDayDollars: depositPerDayDollars,
          dailyPenaltyAmountCents: isPast ? penaltyCents : 0,
          editable: date == MvpDateUtils.dateOnly(DateTime.now()),
          evaluationState: isPast
              ? DailyEntryEvaluationState.evaluated
              : (date == MvpDateUtils.dateOnly(DateTime.now())
                  ? DailyEntryEvaluationState.pending
                  : DailyEntryEvaluationState.pending),
          stepsEntered: isPast,
        ),
      );
    }

    return Challenge(
      id: 'challenge_demo',
      createdAt: DateTime.now(),
      startDate: start,
      endDate: end,
      durationDays: durationDays,
      dailyStepGoal: dailyStepGoal,
      totalStepGoal: totalStepGoal,
      depositPerDay: depositPerDay,
      totalDeposit: totalDeposit,
      status: ChallengeStatus.active,
      totalStepsAccumulated: entries
          .where((e) => e.date.isBefore(MvpDateUtils.dateOnly(DateTime.now())) || (e.date.isAtSameMomentAs(MvpDateUtils.dateOnly(DateTime.now())) && e.stepsEntered))
          .fold(0, (a, b) => a + b.steps),
      totalPenaltyAmountCents:
          entries.where((e) => e.evaluationState == DailyEntryEvaluationState.evaluated).fold(
                0,
                (a, b) => a + b.dailyPenaltyAmountCents,
              ),
      refundableRemainingAmountCents: totalDeposit.cents -
          entries
              .where((e) => e.evaluationState == DailyEntryEvaluationState.evaluated)
              .fold(0, (a, b) => a + b.dailyPenaltyAmountCents),
      returnedAmountCents: 0,
      platformKeptAmountCents: 0,
      dailyEntries: entries,
    );
  }
}

