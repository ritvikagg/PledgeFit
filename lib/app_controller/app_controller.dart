import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/challenge.dart';
import '../data/models/connected_devices_state.dart';
import '../data/models/mock_user.dart';
import '../data/models/user_profile.dart';
import '../data/models/wallet.dart';
import '../data/persistence/local_storage_repository.dart';
import '../services/auth/auth_controller.dart';
import '../services/challenge/challenge_service.dart';
import '../services/health/health_step_data_service.dart';
import '../services/health/health_sync_models.dart';
import '../services/health/health_sync_providers.dart';
import '../services/health/step_platform.dart';
import '../services/wallet/wallet_service.dart';

class AppModel {
  final MockUser user;
  final Wallet wallet;
  final Challenge? activeChallenge;
  final Challenge? lastCompletedChallenge;
  final UserProfile profile;
  final ConnectedDevicesState connectedDevices;

  const AppModel({
    required this.user,
    required this.wallet,
    required this.activeChallenge,
    required this.lastCompletedChallenge,
    required this.profile,
    required this.connectedDevices,
  });

  bool get isAuthenticated => user.id != MockUser.guest.id;

  bool get shouldShowLatestResult {
    return lastCompletedChallenge != null && !user.lastResultShown;
  }

  AppModel copyWith({
    MockUser? user,
    Wallet? wallet,
    Challenge? activeChallenge,
    Challenge? lastCompletedChallenge,
    UserProfile? profile,
    ConnectedDevicesState? connectedDevices,
    bool clearActiveChallenge = false,
    bool clearLastCompletedChallenge = false,
  }) {
    return AppModel(
      user: user ?? this.user,
      wallet: wallet ?? this.wallet,
      activeChallenge:
          clearActiveChallenge ? null : (activeChallenge ?? this.activeChallenge),
      lastCompletedChallenge: clearLastCompletedChallenge
          ? null
          : (lastCompletedChallenge ?? this.lastCompletedChallenge),
      profile: profile ?? this.profile,
      connectedDevices: connectedDevices ?? this.connectedDevices,
    );
  }
}

class AppController extends AsyncNotifier<AppModel> {
  late LocalStorageRepository _storage;
  late WalletService _walletService;
  late ChallengeService _challengeService;
  late HealthStepDataService _healthSteps;

  @override
  Future<AppModel> build() async {
    _healthSteps = ref.read(healthStepDataServiceProvider);
    final session = await ref.watch(authControllerProvider.future);

    final prefs = await SharedPreferences.getInstance();
    _storage = LocalStorageRepository(prefs);
    _walletService = WalletService(storage: _storage);
    _challengeService = ChallengeService(
      storage: _storage,
      walletService: _walletService,
    );

    if (session == null) {
      return AppModel(
        user: MockUser.guest,
        wallet: Wallet.empty,
        activeChallenge: null,
        lastCompletedChallenge: null,
        profile: UserProfile.empty,
        connectedDevices: ConnectedDevicesState.none,
      );
    }

    var user = await _storage.loadMockUser();
    if (user == null || user.id != session.userId) {
      user = MockUser(
        id: session.userId,
        createdAt: DateTime.now(),
        lastResultShown: true,
      );
      await _storage.saveMockUser(user);
    }
    final profile = await _storage.loadUserProfile();
    final connectedDevices = await _storage.loadConnectedDevices();
    Wallet wallet = await _storage.loadWallet();
    Challenge? activeChallenge = await _challengeService.loadActiveChallenge();
    Challenge? lastCompletedChallenge =
        await _challengeService.loadLastCompletedChallenge();

    // Evaluate active challenge for "as of today" and finalize if ended.
    await _challengeService.ensureEvaluatedAndFinalizeIfNeeded(now: DateTime.now());

    activeChallenge = await _challengeService.loadActiveChallenge();
    lastCompletedChallenge =
        await _challengeService.loadLastCompletedChallenge();
    wallet = await _storage.loadWallet();

    return AppModel(
      user: user,
      wallet: wallet,
      activeChallenge: activeChallenge,
      lastCompletedChallenge: lastCompletedChallenge,
      profile: profile,
      connectedDevices: connectedDevices,
    );
  }

  Future<void> markLastResultShown() async {
    final current = state.value;
    if (current == null || !current.isAuthenticated) return;
    final updatedUser = current.user.copyWith(lastResultShown: true);
    await _storage.saveMockUser(updatedUser);
    state = AsyncValue.data(current.copyWith(user: updatedUser));
  }

  Future<Challenge> createChallenge({
    required int durationDays,
    required int depositPerDayDollars,
    required int dailyStepGoal,
  }) async {
    final current = state.value;
    if (current == null) {
      throw StateError('App is not ready.');
    }
    if (!current.isAuthenticated) {
      throw StateError('Sign in to create a challenge.');
    }

    final challenge = await _challengeService.createChallenge(
      durationDays: durationDays,
      depositPerDayDollars: depositPerDayDollars,
      dailyStepGoal: dailyStepGoal,
      now: DateTime.now(),
    );

    // Clear previous completion view if user starts a new challenge.
    await _storage.saveLastCompletedChallenge(null);
    final updatedUser = current.user.copyWith(lastResultShown: true);
    await _storage.saveMockUser(updatedUser);

    final updatedWallet = await _storage.loadWallet();

    state = AsyncValue.data(
      current.copyWith(
        user: updatedUser,
        wallet: updatedWallet,
        activeChallenge: challenge,
        clearLastCompletedChallenge: true,
      ),
    );

    return challenge;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _storage.saveUserProfile(profile);
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(profile: profile));
  }

  Future<void> saveConnectedDevices(ConnectedDevicesState devices) async {
    await _storage.saveConnectedDevices(devices);
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(connectedDevices: devices));
  }

  Future<Challenge> increaseActiveChallengeGoals({
    required int newDurationDays,
    required int newTotalStepGoal,
    required int newDailyStepGoal,
  }) async {
    final current = state.value;
    if (current == null) throw StateError('App is not ready.');
    final updated = await _challengeService.increaseActiveChallengeGoals(
      newDurationDays: newDurationDays,
      newTotalStepGoal: newTotalStepGoal,
      newDailyStepGoal: newDailyStepGoal,
      now: DateTime.now(),
    );
    final wallet = await _storage.loadWallet();
    state = AsyncValue.data(
      current.copyWith(activeChallenge: updated, wallet: wallet),
    );
    return updated;
  }

  Future<void> restartActiveChallenge() async {
    final current = state.value;
    if (current == null) throw StateError('App is not ready.');
    await _challengeService.restartActiveChallenge();
    final wallet = await _storage.loadWallet();
    final clearedUser = current.user.copyWith(lastResultShown: true);
    await _storage.saveMockUser(clearedUser);
    state = AsyncValue.data(
      current.copyWith(
        clearActiveChallenge: true,
        wallet: wallet,
        user: clearedUser,
        clearLastCompletedChallenge: true,
      ),
    );
  }

  /// Reads steps from Apple Health / Health Connect and applies them to the
  /// active challenge. Call after permissions are granted.
  Future<StepSyncOutcome> syncStepsFromHealth() async {
    final current = state.value;
    if (current == null) return StepSyncOutcome.syncFailed;

    if (kIsWeb || !_healthSteps.isSupported) {
      return StepSyncOutcome.unsupportedPlatform;
    }

    final challenge = current.activeChallenge;
    if (challenge == null) {
      return StepSyncOutcome.noActiveChallenge;
    }

    try {
      await _healthSteps.ensureConfigured();

      if (isAndroidMobile) {
        final status = await _healthSteps.getAndroidSdkStatus();
        final precheck = _healthSteps.outcomeForAndroidPrecheck(status);
        if (precheck != StepSyncOutcome.success) {
          await _persistSyncFailure(precheck);
          return precheck;
        }
        final motion = await Permission.activityRecognition.request();
        if (!motion.isGranted) {
          await _persistSyncFailure(StepSyncOutcome.activityPermissionDenied);
          return StepSyncOutcome.activityPermissionDenied;
        }
      }

      await _healthSteps.ensureHistoryAuthorizationIfNeeded(
        challengeStart: challenge.startDate,
        now: DateTime.now(),
      );

      final authorized = await _healthSteps.requestStepReadAuthorization();
      if (!authorized) {
        await _persistSyncFailure(StepSyncOutcome.healthPermissionDenied);
        return StepSyncOutcome.healthPermissionDenied;
      }

      final now = DateTime.now();
      final stepsByDate = await _healthSteps.readTotalStepsForChallengeDays(
        challengeStart: challenge.startDate,
        challengeEnd: challenge.endDate,
        now: now,
      );

      await _challengeService.applyHealthSyncedSteps(
        challengeId: challenge.id,
        stepsByDate: stepsByDate,
        now: now,
      );

      await _challengeService.ensureEvaluatedAndFinalizeIfNeeded(now: now);

      final activeChallenge = await _challengeService.loadActiveChallenge();
      final lastCompletedChallenge =
          await _challengeService.loadLastCompletedChallenge();
      final wallet = await _storage.loadWallet();

      final devices = current.connectedDevices.copyWith(
        stepSyncConnected: true,
        lastSyncedAt: now,
        permissionsGranted: true,
        clearLastSyncError: true,
      );
      await _storage.saveConnectedDevices(devices);

      state = AsyncValue.data(
        current.copyWith(
          wallet: wallet,
          activeChallenge: activeChallenge,
          lastCompletedChallenge: lastCompletedChallenge,
          connectedDevices: devices,
        ),
      );

      return StepSyncOutcome.success;
    } catch (e, st) {
      debugPrint('syncStepsFromHealth: $e\n$st');
      await _persistSyncFailure(StepSyncOutcome.syncFailed);
      return StepSyncOutcome.syncFailed;
    }
  }

  Future<void> _persistSyncFailure(StepSyncOutcome o) async {
    final current = state.value;
    if (current == null) return;
    await saveConnectedDevices(
      current.connectedDevices.copyWith(
        lastSyncErrorCode: o.name,
        stepSyncConnected: o == StepSyncOutcome.healthPermissionDenied
            ? false
            : current.connectedDevices.stepSyncConnected,
        permissionsGranted: o == StepSyncOutcome.healthPermissionDenied
            ? false
            : current.connectedDevices.permissionsGranted,
      ),
    );
  }

  /// Resyncs when the app returns to the foreground — only if the user already
  /// completed a successful health connection (avoids spamming permission UI).
  Future<void> syncStepsFromHealthIfEligible() async {
    final current = state.value;
    if (current == null) return;
    if (kIsWeb) return;
    if (current.activeChallenge == null) return;
    if (!current.connectedDevices.stepSyncConnected) return;
    await syncStepsFromHealth();
  }

  /// Clears local integration state and revokes Health Connect permissions on Android.
  Future<void> disconnectHealth() async {
    if (!kIsWeb && _healthSteps.isSupported) {
      try {
        await _healthSteps.ensureConfigured();
        await _healthSteps.revokeAndroidPermissions();
      } catch (e, st) {
        debugPrint('disconnectHealth: $e\n$st');
      }
    }
    await saveConnectedDevices(ConnectedDevicesState.none);
  }

  /// Mock-only appeal submit — replace with API call to appeals backend.
  Future<void> submitAppealMock({
    required String challengeRef,
    required String reason,
    required String notes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}

final appControllerProvider =
    AsyncNotifierProvider<AppController, AppModel>(AppController.new);

