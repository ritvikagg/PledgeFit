import '../money.dart';
import 'pledge_product_rules.dart';

/// Marketing / onboarding example only — internally consistent; respects
/// product bounds (duration 15–60, steps 5k–10k, stake $1–$5).
abstract final class OnboardingExampleChallenge {
  static const int stepsPerDay = 10000;
  static const int depositPerDayDollars =
      PledgeProductRules.defaultDepositPerDayDollars;
  static const int durationDays = 30;

  static int get totalDepositCents =>
      durationDays * depositPerDayDollars * 100;

  static Money get totalDeposit => Money(totalDepositCents);

  /// 20% of one day’s stake when the example uses $1/day ($0.20).
  static Money get examplePenaltyPerMissedDay =>
      Money((depositPerDayDollars * 100) ~/ 5);
}
