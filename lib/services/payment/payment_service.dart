import '../../core/money.dart';

abstract class PaymentService {
  /// Locks the user's deposit for the challenge (future Stripe integration).
  Future<void> lockDeposit({required String challengeId, required Money amount});

  /// Payouts refundable funds to the user (future Stripe integration).
  Future<void> payoutToUser({required String challengeId, required Money amount});

  /// Marks funds as kept by the platform (future Stripe integration).
  Future<void> markPlatformKept({required String challengeId, required Money amount});
}

