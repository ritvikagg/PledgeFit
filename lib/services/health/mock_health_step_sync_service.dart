import 'health_step_sync_service.dart';

/// MVP no-op health sync.
class MockHealthStepSyncService implements HealthStepSyncService {
  const MockHealthStepSyncService();

  @override
  Future<int?> syncStepsForDate({required DateTime date}) async {
    return null; // manual steps only for MVP
  }
}

