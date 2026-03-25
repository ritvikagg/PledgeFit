import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/challenge.dart';
import '../data/models/daily_entry.dart';
import '../data/models/mock_user.dart';
import '../data/models/wallet.dart';
import '../data/persistence/local_storage_repository.dart';
import '../core/date_utils.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/mock_auth_service.dart';
import '../services/challenge/challenge_service.dart';
import '../services/wallet/wallet_service.dart';

class AppModel {
  final MockUser user;
  final Wallet wallet;
  final Challenge? activeChallenge;
  final Challenge? lastCompletedChallenge;

  const AppModel({
    required this.user,
    required this.wallet,
    required this.activeChallenge,
    required this.lastCompletedChallenge,
  });

  bool get shouldShowLatestResult {
    return lastCompletedChallenge != null && !user.lastResultShown;
  }

  AppModel copyWith({
    MockUser? user,
    Wallet? wallet,
    Challenge? activeChallenge,
    Challenge? lastCompletedChallenge,
  }) {
    return AppModel(
      user: user ?? this.user,
      wallet: wallet ?? this.wallet,
      activeChallenge: activeChallenge ?? this.activeChallenge,
      lastCompletedChallenge:
          lastCompletedChallenge ?? this.lastCompletedChallenge,
    );
  }
}

class AppController extends AsyncNotifier<AppModel> {
  late LocalStorageRepository _storage;
  late AuthService _authService;
  late WalletService _walletService;
  late ChallengeService _challengeService;

  @override
  Future<AppModel> build() async {
    final prefs = await SharedPreferences.getInstance();
    _storage = LocalStorageRepository(prefs);
    _authService = MockAuthService(storage: _storage);
    _walletService = WalletService(storage: _storage);
    _challengeService = ChallengeService(
      storage: _storage,
      walletService: _walletService,
    );

    final user = await _authService.getOrCreateLocalUser();
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
    );
  }

  Future<void> markLastResultShown() async {
    final current = state.value;
    if (current == null) return;
    final updatedUser = current.user.copyWith(lastResultShown: true);
    await _storage.saveMockUser(updatedUser);
    state = AsyncValue.data(current.copyWith(user: updatedUser));
  }

  Future<Challenge> createChallenge({
    required int durationDays,
    required int depositPerDayDollars,
    required int dailyStepGoal,
    required int totalStepGoal,
  }) async {
    final current = state.value;
    if (current == null) {
      throw StateError('App is not ready.');
    }

    final challenge = await _challengeService.createChallenge(
      durationDays: durationDays,
      depositPerDayDollars: depositPerDayDollars,
      dailyStepGoal: dailyStepGoal,
      totalStepGoal: totalStepGoal,
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
        lastCompletedChallenge: null,
      ),
    );

    return challenge;
  }

  Future<DailyEntryUpdateResult> saveTodaySteps(int steps) async {
    final current = state.value;
    if (current == null || current.activeChallenge == null) {
      throw StateError('No active challenge.');
    }
    final now = DateTime.now();

    final updated = await _challengeService.saveDailySteps(
      challengeId: current.activeChallenge!.id,
      date: now,
      steps: steps,
      now: now,
    );

    // If the user saved on the final day, finalize immediately.
    await _challengeService.ensureEvaluatedAndFinalizeIfNeeded(now: now);

    final activeChallenge = await _challengeService.loadActiveChallenge();
    final lastCompletedChallenge =
        await _challengeService.loadLastCompletedChallenge();
    final wallet = await _storage.loadWallet();

    state = AsyncValue.data(
      current.copyWith(
        wallet: wallet,
        activeChallenge: activeChallenge,
        lastCompletedChallenge: lastCompletedChallenge,
      ),
    );

    return updated;
  }
}

final appControllerProvider =
    AsyncNotifierProvider<AppController, AppModel>(AppController.new);

