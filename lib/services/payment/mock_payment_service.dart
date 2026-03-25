import '../../core/money.dart';
import 'payment_service.dart';

/// MVP no-op payment service.
class MockPaymentService implements PaymentService {
  const MockPaymentService();

  @override
  Future<void> lockDeposit({required String challengeId, required Money amount}) async {
    // Intentionally no-op for MVP.
  }

  @override
  Future<void> payoutToUser({required String challengeId, required Money amount}) async {
    // Intentionally no-op for MVP.
  }

  @override
  Future<void> markPlatformKept({required String challengeId, required Money amount}) async {
    // Intentionally no-op for MVP.
  }
}

