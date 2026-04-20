/// Outcome of a step sync or connect attempt (no thrown exceptions for expected cases).
enum StepSyncOutcome {
  success,
  noActiveChallenge,
  unsupportedPlatform,
  healthConnectUnavailable,
  healthConnectNotInstalled,
  activityPermissionDenied,
  healthPermissionDenied,
  syncFailed,
}

/// Lightweight status for UI (devices screen, sync page).
enum HealthPermissionUiState {
  unknown,
  granted,
  denied,
}
