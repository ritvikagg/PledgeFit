import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auth_session.dart';
import '../services/auth/auth_controller.dart';

/// Notifies [GoRouter] when auth state changes so [redirect] re-runs.
final class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this._ref) {
    _subscription = _ref.listen<AsyncValue<AuthSession?>>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref _ref;
  ProviderSubscription<AsyncValue<AuthSession?>>? _subscription;

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}
