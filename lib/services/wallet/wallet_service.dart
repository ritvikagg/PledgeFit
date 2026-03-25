import '../../core/id_generator.dart';
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
}

