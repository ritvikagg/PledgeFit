import '../core/date_utils.dart';
import '../core/money.dart';
import 'models/challenge.dart';
import 'models/daily_entry.dart';
import 'models/wallet.dart';
import 'models/wallet_transaction.dart';

/// Toggle investor-demo overlay when no real challenge is persisted.
abstract final class InvestorDemoConfig {
  static const bool enabled = false;
  static const String challengeId = 'investor_demo_challenge';
}

/// Mock data aligned with product rules ($1–$5/day deposits; example uses minimum).
abstract final class InvestorDemoSnapshot {
  static Challenge challenge(DateTime now) {
    final today = MvpDateUtils.dateOnly(now);
    final start = MvpDateUtils.addDays(today, -7);
    final end = MvpDateUtils.addDays(start, 14);

    const dailyGoal = 8000;
    const depositPerDayDollars = 1;
    const totalGoal = 120000;

    // Past 7 days sum to 63,200; today 4,200 → 67,400 total progress.
    const pastSteps = <int>[10000, 10000, 5000, 10000, 10000, 5000, 8200];
    var i = 0;
    final entries = <DailyEntry>[];

    for (var d = 0; d < 15; d++) {
      final date = MvpDateUtils.addDays(start, d);
      final isPast = date.isBefore(today);
      final isFuture = date.isAfter(today);

      if (isFuture) {
        entries.add(
          DailyEntry(
            date: date,
            steps: 0,
            hitDailyGoal: false,
            stepGoalForDay: dailyGoal,
            depositAllocatedForDayDollars: depositPerDayDollars,
            dailyPenaltyAmountCents: 0,
            editable: false,
            evaluationState: DailyEntryEvaluationState.pending,
            stepsEntered: false,
          ),
        );
        continue;
      }

      if (isPast) {
        final steps = pastSteps[i++];
        final hit = steps >= dailyGoal;
        final penaltyCents =
            hit ? 0 : (Money(depositPerDayDollars * 100).cents ~/ 5);
        entries.add(
          DailyEntry(
            date: date,
            steps: steps,
            hitDailyGoal: hit,
            stepGoalForDay: dailyGoal,
            depositAllocatedForDayDollars: depositPerDayDollars,
            dailyPenaltyAmountCents: penaltyCents,
            editable: false,
            evaluationState: DailyEntryEvaluationState.evaluated,
            stepsEntered: true,
          ),
        );
        continue;
      }

      // Today (day 8)
      const steps = 4200;
      final hit = steps >= dailyGoal;
      final penaltyCents =
          hit ? 0 : (Money(depositPerDayDollars * 100).cents ~/ 5);
      entries.add(
        DailyEntry(
          date: date,
          steps: steps,
          hitDailyGoal: hit,
          stepGoalForDay: dailyGoal,
          depositAllocatedForDayDollars: depositPerDayDollars,
          dailyPenaltyAmountCents: penaltyCents,
          editable: true,
          evaluationState: DailyEntryEvaluationState.evaluated,
          stepsEntered: true,
        ),
      );
      continue;
    }

    const totalDepositCents = 15 * depositPerDayDollars * 100;
    const headlinePenaltyCents = 60; // 3 misses × 20% of $1.00
    const headlineRefundableCents = totalDepositCents - headlinePenaltyCents;

    return Challenge(
      id: InvestorDemoConfig.challengeId,
      createdAt: now,
      startDate: start,
      endDate: end,
      durationDays: 15,
      dailyStepGoal: dailyGoal,
      totalStepGoal: totalGoal,
      depositPerDay: Money(depositPerDayDollars * 100),
      totalDeposit: Money(totalDepositCents),
      status: ChallengeStatus.active,
      totalStepsAccumulated: 67400,
      totalPenaltyAmountCents: headlinePenaltyCents,
      refundableRemainingAmountCents: headlineRefundableCents,
      returnedAmountCents: 0,
      platformKeptAmountCents: 0,
      dailyEntries: entries,
    );
  }

  /// Wallet mock: $15.00 challenge lock; $0.60 penalties; coherent with demo challenge.
  static Wallet wallet(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    return Wallet(
      availableBalance: Money(1440),
      totalDeposited: Money(1500),
      totalReturned: Money(2800),
      totalForfeited: Money(60),
      totalPlatformKept: Money(0),
      transactions: [
        WalletTransaction.create(
          type: 'deposit_locked',
          description: 'Challenge deposit (15 days × \$1/day)',
          amount: Money(1500),
          createdAt: d.subtract(const Duration(days: 7)),
        ),
        WalletTransaction.create(
          type: 'penalty',
          description: 'Day 3 penalty',
          amount: Money(20),
          createdAt: d.subtract(const Duration(days: 5)),
        ),
        WalletTransaction.create(
          type: 'penalty',
          description: 'Day 6 penalty',
          amount: Money(20),
          createdAt: d.subtract(const Duration(days: 2)),
        ),
        WalletTransaction.create(
          type: 'penalty',
          description: 'Today penalty (preview)',
          amount: Money(20),
          createdAt: d,
        ),
        WalletTransaction.create(
          type: 'refund',
          description: 'Previous challenge refund',
          amount: Money(2800),
          createdAt: d.subtract(const Duration(days: 10)),
        ),
      ],
    );
  }

  static Challenge failureResultPreview() {
    final c = challenge(DateTime(2026, 3, 28));
    const penalties = 280;
    const deposit = 1500;
    return c.copyWith(
      status: ChallengeStatus.failed,
      totalStepsAccumulated: 89200,
      totalStepGoal: 120000,
      totalPenaltyAmountCents: penalties,
      refundableRemainingAmountCents: deposit - penalties,
      returnedAmountCents: 0,
      platformKeptAmountCents: deposit - penalties,
    );
  }
}
