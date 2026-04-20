import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_controller/app_controller.dart';
import '../data/investor_demo_snapshot.dart';
import '../data/models/challenge.dart';
import '../data/models/wallet.dart';

/// True when the UI is showing the investor snapshot instead of a persisted challenge.
final isUiDemoChallengeProvider = Provider<bool>((ref) {
  final app = ref.watch(appControllerProvider).asData?.value;
  if (app == null) return false;
  if (!InvestorDemoConfig.enabled) return false;
  return app.activeChallenge == null;
});

/// True when an active challenge needs a successful Health connection to sync steps.
final needsHealthStepSourceProvider = Provider<bool>((ref) {
  final app = ref.watch(appControllerProvider).asData?.value;
  if (app == null) return false;
  if (app.activeChallenge == null) return false;
  return !app.connectedDevices.stepSyncConnected;
});

final displayChallengeProvider = Provider<Challenge?>((ref) {
  final app = ref.watch(appControllerProvider).asData?.value;
  if (app == null) return null;
  if (app.activeChallenge != null) return app.activeChallenge;
  if (InvestorDemoConfig.enabled) {
    return InvestorDemoSnapshot.challenge(DateTime.now());
  }
  return null;
});

final displayWalletProvider = Provider<Wallet>((ref) {
  final app = ref.watch(appControllerProvider).asData?.value;
  if (app == null) return Wallet.empty;
  if (app.activeChallenge != null) return app.wallet;
  if (InvestorDemoConfig.enabled) {
    return InvestorDemoSnapshot.wallet(DateTime.now());
  }
  return app.wallet;
});
