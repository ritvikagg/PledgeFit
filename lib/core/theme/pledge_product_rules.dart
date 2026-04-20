/// StepStake challenge rules surfaced in UI and validation.
/// Keep defaults and examples aligned with [ChallengeService].
abstract final class PledgeProductRules {
  static const int minChallengeDays = 15;
  static const int maxChallengeDays = 60;

  static const int minDailySteps = 5000;
  static const int maxDailySteps = 10000;

  static const int minDepositPerDayDollars = 1;
  static const int maxDepositPerDayDollars = 5;

  /// New-goal form default and marketing-style examples (not user-specific state).
  static const int defaultDepositPerDayDollars = 1;
}
