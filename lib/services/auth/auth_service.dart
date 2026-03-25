import '../../data/models/mock_user.dart';

abstract class AuthService {
  /// Returns the current local MVP user.
  Future<MockUser> getOrCreateLocalUser();
}

