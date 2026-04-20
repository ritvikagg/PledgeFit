import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/auth_session.dart';
import '../../data/persistence/local_storage_repository.dart';
import 'local_auth_service.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  late LocalAuthService _auth;

  LocalAuthService get service => _auth;

  @override
  Future<AuthSession?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorageRepository(prefs);
    _auth = LocalAuthService(storage);
    return _auth.loadSession();
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _auth.signInWithEmail(
          email: email,
          password: password,
        ));
  }

  Future<void> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _auth.signUpWithEmail(
          fullName: fullName,
          email: email,
          password: password,
        ));
  }

  Future<void> signInWithGoogleMock() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_auth.signInWithGoogleMock);
  }

  Future<void> logout() async {
    await _auth.clearSession();
    state = const AsyncValue.data(null);
  }
}
