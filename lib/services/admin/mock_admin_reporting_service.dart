import 'admin_reporting_service.dart';
import '../../data/models/challenge.dart';

/// MVP no-op admin reporting.
class MockAdminReportingService implements AdminReportingService {
  const MockAdminReportingService();

  @override
  Future<void> reportChallengeCreated(Challenge challenge) async {
    // no-op
  }

  @override
  Future<void> reportChallengeFinalized(Challenge challenge) async {
    // no-op
  }
}

