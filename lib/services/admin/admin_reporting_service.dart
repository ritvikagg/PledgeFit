import '../../data/models/challenge.dart';

abstract class AdminReportingService {
  Future<void> reportChallengeCreated(Challenge challenge);
  Future<void> reportChallengeFinalized(Challenge challenge);
}

