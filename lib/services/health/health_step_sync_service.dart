abstract class HealthStepSyncService {
  /// Syncs steps for a date into the app.
  /// MVP returns null because we use manual steps input.
  Future<int?> syncStepsForDate({required DateTime date});
}

