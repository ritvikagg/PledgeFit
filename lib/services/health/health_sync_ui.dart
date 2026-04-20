import '../../core/date_utils.dart';
import '../../core/formatters.dart';
import '../../data/models/challenge.dart';
import '../../data/models/connected_devices_state.dart';
import 'health_sync_copy.dart';
import 'health_sync_models.dart';
import 'step_platform.dart';

/// High-level banner slot for Home / Progress / Step sync (one primary issue at a time).
enum HealthSyncBannerKind {
  none,
  noChallengeHealthConnected,
  connectRequired,
  permissionDenied,
  healthConnectNotInstalled,
  healthConnectUnavailable,
  activityPermissionDenied,
  syncFailed,
  connectedOk,
  noStepDataHint,
}

class HealthSyncBannerViewModel {
  const HealthSyncBannerViewModel({
    required this.kind,
    this.outcome,
    required this.title,
    required this.body,
    this.showOpenSettings = false,
    this.showInstallHealthConnect = false,
    this.showRetrySync = false,
    this.lastGoodSyncLabel,
  });

  final HealthSyncBannerKind kind;
  final StepSyncOutcome? outcome;
  final String title;
  final String body;
  final bool showOpenSettings;
  final bool showInstallHealthConnect;
  final bool showRetrySync;
  final String? lastGoodSyncLabel;

  /// When there is no active challenge — slim status / connect prompt on Home empty state.
  static HealthSyncBannerViewModel? stripForNoActiveChallenge({
    required bool isDemo,
    required ConnectedDevicesState devices,
  }) {
    if (isDemo) return null;
    if (devices.stepSyncConnected && devices.lastSyncedAt != null) {
      final lastOk = devices.lastSyncedAt!;
      return HealthSyncBannerViewModel(
        kind: HealthSyncBannerKind.noChallengeHealthConnected,
        title: '${HealthSyncCopy.appName} · ${healthProviderDisplayName()}',
        body:
            'Health sync is on. Last successful sync: ${_fmt(lastOk)}. '
            'Start a goal on the Goal tab when you’re ready.',
      );
    }
    return HealthSyncBannerViewModel(
      kind: HealthSyncBannerKind.connectRequired,
      title: 'Connect ${healthProviderDisplayName()}',
      body:
          '${HealthSyncCopy.connectToSyncSteps} '
          'You can connect now so you’re ready for your first challenge.',
      showInstallHealthConnect: isAndroidMobile,
    );
  }

  /// Primary card when a real challenge exists (not demo snapshot).
  static HealthSyncBannerViewModel? primaryForActiveChallenge({
    required bool isDemo,
    required ConnectedDevicesState devices,
    required Challenge challenge,
    required DateTime nowDate,
  }) {
    if (isDemo) return null;

    final err = parseStepSyncOutcome(devices.lastSyncErrorCode);
    final connected = devices.stepSyncConnected;
    final lastOk = devices.lastSyncedAt;

    final today = challenge.dailyEntries.firstWhere(
      (e) => MvpDateUtils.isSameDate(e.date, nowDate),
      orElse: () => challenge.dailyEntries.first,
    );

    if (!connected) {
      return _blockedBanner(err);
    }

    if (err != null && err != StepSyncOutcome.success) {
      return _errorWhileConnected(err, lastOk);
    }

    if (lastOk != null) {
      if (today.stepsEntered && today.steps == 0) {
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.noStepDataHint,
          title: 'No steps recorded for today yet',
          body:
              'If you’ve already been active, open the ${healthProviderDisplayName()} '
              'app and confirm your sources, then sync again. Otherwise, check back '
              'after you move around.',
          showRetrySync: true,
          lastGoodSyncLabel: _fmt(lastOk),
        );
      }
      return HealthSyncBannerViewModel(
        kind: HealthSyncBannerKind.connectedOk,
        title: 'Connected · ${healthProviderDisplayName()}',
        body:
            'Read access is on. Last successful sync ${_fmt(lastOk)}. '
            'Today’s total from health: ${formatWithCommas(today.steps)} steps.',
      );
    }

    return null;
  }

  /// Step sync route: prefer the latest user attempt, then persisted + challenge state.
  static HealthSyncBannerViewModel? forStepSyncPage({
    required bool isDemo,
    required ConnectedDevicesState devices,
    required Challenge? challenge,
    required DateTime nowDate,
    StepSyncOutcome? lastInteraction,
  }) {
    if (isDemo) return null;

    if (lastInteraction != null && lastInteraction != StepSyncOutcome.success) {
      return _bannerForRecentOutcome(lastInteraction, devices);
    }

    if (challenge != null) {
      return primaryForActiveChallenge(
        isDemo: false,
        devices: devices,
        challenge: challenge,
        nowDate: nowDate,
      );
    }

    return stripForNoActiveChallenge(isDemo: false, devices: devices);
  }

  static HealthSyncBannerViewModel _bannerForRecentOutcome(
    StepSyncOutcome o,
    ConnectedDevicesState devices,
  ) {
    switch (o) {
      case StepSyncOutcome.noActiveChallenge:
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.syncFailed,
          title: 'No active challenge',
          body:
              'Create a goal on the Goal tab first. ${HealthSyncCopy.appName} only '
              'applies synced steps to an active challenge.',
        );
      case StepSyncOutcome.unsupportedPlatform:
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.syncFailed,
          title: 'Not available here',
          body: 'Use an iPhone or Android phone with ${HealthSyncCopy.appName}.',
        );
      default:
        if (devices.stepSyncConnected) {
          return _errorWhileConnected(o, devices.lastSyncedAt);
        }
        return _blockedBanner(o);
    }
  }

  static HealthSyncBannerViewModel? forProgress({
    required bool isDemo,
    required bool hasActiveChallenge,
    required ConnectedDevicesState devices,
  }) {
    if (isDemo || !hasActiveChallenge) return null;
    final err = parseStepSyncOutcome(devices.lastSyncErrorCode);
    final connected = devices.stepSyncConnected;

    if (!connected) {
      final b = _blockedBanner(err);
      return b.copyWith(
        title: 'Progress needs ${healthProviderDisplayName()}',
        body:
            'Daily totals stay at zero until we can read your steps. '
            '${HealthSyncCopy.connectToSyncSteps}',
      );
    }
    if (err != null && err != StepSyncOutcome.success) {
      return _errorWhileConnected(err, devices.lastSyncedAt);
    }
    return null;
  }

  static HealthSyncBannerViewModel _blockedBanner(StepSyncOutcome? err) {
    switch (err) {
      case StepSyncOutcome.healthPermissionDenied:
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.permissionDenied,
          outcome: err,
          title: 'Step access denied',
          body:
              'Allow ${HealthSyncCopy.appName} to read Steps in ${healthProviderDisplayName()}, '
              'then try again.',
          showOpenSettings: true,
          showRetrySync: true,
        );
      case StepSyncOutcome.healthConnectNotInstalled:
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.healthConnectNotInstalled,
          outcome: err,
          title: 'Install Health Connect',
          body:
              'Android uses Health Connect to read steps. Install it from the '
              'Play Store, then return here.',
          showInstallHealthConnect: true,
          showRetrySync: true,
        );
      case StepSyncOutcome.healthConnectUnavailable:
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.healthConnectUnavailable,
          outcome: err,
          title: 'Health Connect isn’t ready',
          body:
              'Update Google Play services or your device, then try again.',
          showRetrySync: true,
        );
      case StepSyncOutcome.activityPermissionDenied:
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.activityPermissionDenied,
          outcome: err,
          title: 'Activity permission needed',
          body:
              'Android needs Activity recognition so Health Connect can share step data.',
          showOpenSettings: true,
          showRetrySync: true,
        );
      default:
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.connectRequired,
          title: 'Connect ${healthProviderDisplayName()}',
          body: HealthSyncCopy.connectToSyncSteps,
          showInstallHealthConnect: isAndroidMobile,
          showRetrySync: true,
        );
    }
  }

  static HealthSyncBannerViewModel _errorWhileConnected(
    StepSyncOutcome err,
    DateTime? lastOk,
  ) {
    final hint = lastOk != null
        ? ' Your last good sync (${_fmt(lastOk)}) is still shown until a sync succeeds.'
        : '';
    switch (err) {
      case StepSyncOutcome.syncFailed:
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.syncFailed,
          outcome: err,
          title: 'Couldn’t sync steps',
          body:
              'Something went wrong while reading your health data.$hint',
          showRetrySync: true,
          lastGoodSyncLabel: lastOk != null ? _fmt(lastOk) : null,
        );
      case StepSyncOutcome.healthPermissionDenied:
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.permissionDenied,
          outcome: err,
          title: 'Step access denied',
          body:
              'Re-enable read access in Settings, then retry.$hint',
          showOpenSettings: true,
          showRetrySync: true,
          lastGoodSyncLabel: lastOk != null ? _fmt(lastOk) : null,
        );
      case StepSyncOutcome.healthConnectNotInstalled:
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.healthConnectNotInstalled,
          outcome: err,
          title: 'Health Connect missing',
          body:
              'Install or update Health Connect, then retry.$hint',
          showInstallHealthConnect: true,
          showRetrySync: true,
        );
      case StepSyncOutcome.healthConnectUnavailable:
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.healthConnectUnavailable,
          outcome: err,
          title: 'Health Connect unavailable',
          body:
              'This device can’t use Health Connect right now. Update system '
              'software and try again.$hint',
          showRetrySync: true,
        );
      case StepSyncOutcome.activityPermissionDenied:
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.activityPermissionDenied,
          outcome: err,
          title: 'Activity permission required',
          body:
              'Allow activity recognition, then retry.$hint',
          showOpenSettings: true,
          showRetrySync: true,
        );
      default:
        return HealthSyncBannerViewModel(
          kind: HealthSyncBannerKind.syncFailed,
          outcome: err,
          title: 'Sync issue',
          body: 'Try again in a moment.$hint',
          showRetrySync: true,
        );
    }
  }

  HealthSyncBannerViewModel copyWith({
    String? title,
    String? body,
  }) {
    return HealthSyncBannerViewModel(
      kind: kind,
      outcome: outcome,
      title: title ?? this.title,
      body: body ?? this.body,
      showOpenSettings: showOpenSettings,
      showInstallHealthConnect: showInstallHealthConnect,
      showRetrySync: showRetrySync,
      lastGoodSyncLabel: lastGoodSyncLabel,
    );
  }

  static String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final sfx = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day}, $h:$m $sfx';
  }
}

StepSyncOutcome? parseStepSyncOutcome(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  for (final v in StepSyncOutcome.values) {
    if (v.name == raw) return v;
  }
  return null;
}
