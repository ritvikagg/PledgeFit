import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../../core/date_utils.dart';
import 'health_sync_models.dart';
import 'step_platform.dart';

/// Reads step totals from Apple Health (iOS) or Health Connect (Android) via the
/// [health](https://pub.dev/packages/health) plugin. UI layers should depend on
/// this class, not on [Health] directly.
class HealthStepDataService {
  HealthStepDataService() : _health = Health();

  final Health _health;
  bool _configured = false;

  Health get plugin => _health;

  Future<void> ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Whether this build can use native health APIs (mobile iOS/Android only).
  bool get isSupported => isIosMobile || isAndroidMobile;

  Future<HealthConnectSdkStatus?> getAndroidSdkStatus() async {
    if (!isAndroidMobile) return null;
    await ensureConfigured();
    return _health.getHealthConnectSdkStatus();
  }

  Future<bool> isHealthConnectReady() async {
    if (!isAndroidMobile) return true;
    await ensureConfigured();
    return _health.isHealthConnectAvailable();
  }

  Future<void> promptInstallHealthConnect() async {
    if (isAndroidMobile) {
      await ensureConfigured();
      await _health.installHealthConnect();
    }
  }

  /// Requests READ access to step counts. Returns false if the user denies or dialog fails.
  Future<bool> requestStepReadAuthorization() async {
    if (!isSupported) return false;
    await ensureConfigured();
    final ok = await _health.requestAuthorization(
      [HealthDataType.STEPS],
      permissions: [HealthDataAccess.READ],
    );
    return ok;
  }

  /// Best-effort permission check (Android: reliable; iOS: may be null for read).
  Future<bool?> hasStepReadPermission() async {
    if (!isSupported) return false;
    await ensureConfigured();
    return _health.hasPermissions(
      [HealthDataType.STEPS],
      permissions: [HealthDataAccess.READ],
    );
  }

  Future<void> revokeAndroidPermissions() async {
    if (Platform.isAndroid) {
      await ensureConfigured();
      await _health.revokePermissions();
    }
  }

  Future<int?> readTotalStepsForDay(DateTime date) async {
    if (!isSupported) return null;
    await ensureConfigured();
    final day = MvpDateUtils.dateOnly(date);
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    try {
      final total = await _health.getTotalStepsInInterval(start, end);
      return total ?? 0;
    } catch (e, st) {
      debugPrint('HealthStepDataService.readTotalStepsForDay: $e\n$st');
      return null;
    }
  }

  Future<Map<DateTime, int>> readTotalStepsForChallengeDays({
    required DateTime challengeStart,
    required DateTime challengeEnd,
    required DateTime now,
  }) async {
    final out = <DateTime, int>{};
    final startRange = MvpDateUtils.dateOnly(challengeStart);
    final endRange = MvpDateUtils.dateOnly(challengeEnd);
    final today = MvpDateUtils.dateOnly(now);
    var d = startRange;
    while (!d.isAfter(endRange) && !d.isAfter(today)) {
      final steps = await readTotalStepsForDay(d);
      out[MvpDateUtils.dateOnly(d)] = steps ?? 0;
      d = MvpDateUtils.addDays(d, 1);
    }
    return out;
  }

  /// Optional: longer challenges may need Health Connect history permission on Android.
  Future<void> ensureHistoryAuthorizationIfNeeded({
    required DateTime challengeStart,
    required DateTime now,
  }) async {
    if (!isAndroidMobile) return;
    await ensureConfigured();
    final needsOlderThanDefaultWindow =
        now.difference(challengeStart).inDays > 29;
    if (!needsOlderThanDefaultWindow) return;
    final authorized = await _health.isHealthDataHistoryAuthorized();
    if (authorized) return;
    try {
      await _health.requestHealthDataHistoryAuthorization();
    } catch (e, st) {
      debugPrint('ensureHistoryAuthorizationIfNeeded: $e\n$st');
    }
  }

  /// Maps SDK status to a coarse outcome for onboarding.
  StepSyncOutcome outcomeForAndroidPrecheck(HealthConnectSdkStatus? status) {
    if (status == null) {
      return StepSyncOutcome.healthConnectUnavailable;
    }
    switch (status) {
      case HealthConnectSdkStatus.sdkAvailable:
        return StepSyncOutcome.success;
      case HealthConnectSdkStatus.sdkUnavailable:
        return StepSyncOutcome.healthConnectNotInstalled;
      case HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired:
        return StepSyncOutcome.healthConnectUnavailable;
    }
  }
}
