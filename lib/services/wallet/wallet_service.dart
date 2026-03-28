import '../../core/money.dart';
import '../../data/models/challenge.dart';
import '../../data/models/wallet.dart';
import '../../data/models/wallet_transaction.dart';
import '../../data/persistence/local_storage_repository.dart';

class WalletService {
  final LocalStorageRepository _storage;

  const WalletService({required LocalStorageRepository storage})
      : _storage = storage;

  Future<Wallet> _load() => _storage.loadWallet();
  Future<void> _save(Wallet wallet) => _storage.saveWallet(wallet);

  Future<void> recordChallengeDepositLocked({
    required Challenge challenge,
  }) async {
    final wallet = await _load();

    final deposit = challenge.totalDeposit;
    final updated = wallet.copyWith(
      totalDeposited: wallet.totalDeposited + deposit,
      transactions: [
        WalletTransaction.create(
          type: 'deposit_locked',
          description: 'Locked into active challenge (${challenge.durationDays} days)',
          amount: deposit,
          createdAt: DateTime.now(),
        ),
        ...wallet.transactions,
      ],
    );

    await _save(updated);
  }

  Future<void> applyChallengeFinalization({required Challenge challenge}) async {
    final wallet = await _load();

    Money addAvailable = Money.zero;
    Money returned = Money.zero;
    Money forfeited = Money.zero;
    Money platformKept = Money.zero;

    final isSuccess = challenge.status == ChallengeStatus.success;

    if (isSuccess) {
      returned = challenge.refundableRemainingAmount;
      addAvailable = returned;
      forfeited = challenge.totalPenaltyAmount;
      platformKept = challenge.totalPenaltyAmount; // only forfeitures are kept
    } else {
      returned = Money.zero;
      forfeited = Money(challenge.totalPenaltyAmount.cents);
      platformKept = challenge.platformKeptAmount; // deposit not returned
    }

    final updated = wallet.copyWith(
      availableBalance: wallet.availableBalance + addAvailable,
      totalReturned: wallet.totalReturned + returned,
      totalForfeited: wallet.totalForfeited + forfeited,
      totalPlatformKept: wallet.totalPlatformKept + platformKept,
      transactions: [
        WalletTransaction.create(
          type: isSuccess ? 'challenge_returned' : 'challenge_platform_kept',
          description: isSuccess
              ? 'Challenge completed: returned ${returned.format()}'
              : 'Challenge failed: ${platformKept.format()} kept by platform',
          amount: isSuccess ? returned : platformKept,
          createdAt: DateTime.now(),
        ),
        ...wallet.transactions,
      ],
    );

    await _save(updated);
  }

  Future<void> markNoop() async {
    // Placeholder to match future wallet flows.
  }

  /// Extra days added to an active challenge — additional deposit locked.
  Future<void> recordAdditionalDepositLock({
    required Money amount,
    required String challengeId,
  }) async {
    final wallet = await _load();
    await _save(
      wallet.copyWith(
        totalDeposited: wallet.totalDeposited + amount,
        transactions: [
          WalletTransaction.create(
            type: 'deposit_locked',
            description: 'Additional days locked (challenge $challengeId)',
            amount: amount,
            createdAt: DateTime.now(),
          ),
          ...wallet.transactions,
        ],
      ),
    );
  }

  /// User restarted the goal: refundable balance in the challenge is forfeited to the platform.
  Future<void> recordChallengeRestartForfeit({required Challenge challenge}) async {
    final wallet = await _load();
    final forfeited = challenge.refundableRemainingAmount;
    if (forfeited.cents <= 0) {
      return;
    }
    await _save(
      wallet.copyWith(
        totalForfeited: wallet.totalForfeited + forfeited,
        totalPlatformKept: wallet.totalPlatformKept + forfeited,
        transactions: [
          WalletTransaction.create(
            type: 'restart_forfeit',
            description: 'Goal restarted — forfeited ${forfeited.format()}',
            amount: forfeited,
            createdAt: DateTime.now(),
          ),
          ...wallet.transactions,
        ],
      ),
    );
  }
}

