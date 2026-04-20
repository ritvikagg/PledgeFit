/// Central user-facing strings for health sync and product naming.
abstract final class HealthSyncCopy {
  static const appName = 'StepStake';

  static const emptyHomeTitle = 'Start a step challenge';
  static const emptyHomeBody =
      'Set a duration and step targets, lock a deposit, and earn it back by '
      'hitting your total goal. Miss a daily target and part of that day’s '
      'stake is forfeited — your steps sync automatically from Apple Health or '
      'Health Connect when you connect.';

  static const pullToRefreshHint =
      'Pull down to refresh steps from your health provider.';

  static const connectToSyncSteps =
      'Connect Apple Health or Health Connect so we can read your daily step '
      'totals and keep your challenge up to date.';

  static String readDataExplainer(String providerName) =>
      '$appName only reads daily step totals from $providerName to score your '
      'challenge. We don’t write or modify your health records.';

  static const disconnectProgressStalls =
      'Challenge progress won’t update until you reconnect and sync again.';

  static const faqWhyHealthTitle = 'Why do I need Apple Health or Health Connect?';
  static const faqWhyHealthBody =
      'StepStake reads your daily step count from the same place your phone and '
      'wearables already store steps. Grant access so we can sync totals for your '
      'challenge automatically.';

  static const faqPermissionsTitle = 'What data does StepStake use?';
  static const faqPermissionsBody =
      'We request permission to read daily step totals only. That lets us '
      'compare your activity to your challenge goals. We don’t need to write or '
      'change your health records.';

  static const faqDisconnectTitle = 'What happens if I disconnect health access?';
  static const faqDisconnectBody =
      'We stop receiving new step totals. Your last synced numbers stay on screen '
      'until you reconnect, but penalties and totals won’t update until you '
      'sync again from Settings or Step sync.';

  static const faqNotShowingTitle = 'Why are my steps not showing?';
  static const faqNotShowingBody =
      'Common causes: permission not granted yet, Health Connect not installed on '
      'Android, no steps recorded today in Health yet, or your watch isn’t '
      'syncing to Apple Health / Health Connect. Try opening the Health app, '
      'walking a bit, then pull to refresh in StepStake.';

  static const faqHowOftenTitle = 'How often does syncing happen?';
  static const faqHowOftenBody =
      'StepStake syncs when you open the app, return from the background, pull '
      'to refresh on Home, or tap Sync on the Step sync and Connected devices screens.';
}
