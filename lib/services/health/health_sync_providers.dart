import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'health_step_data_service.dart';

final healthStepDataServiceProvider = Provider<HealthStepDataService>((ref) {
  return HealthStepDataService();
});
