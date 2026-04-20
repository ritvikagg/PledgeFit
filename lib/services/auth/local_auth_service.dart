import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/id_generator.dart';
import '../../data/models/auth_session.dart';
import '../../data/models/mock_user.dart';
import '../../data/models/user_profile.dart';
import '../../data/persistence/local_storage_repository.dart';

/// Password-backed email auth and a pluggable [signInWithGoogleMock] for local MVP.
/// Swap implementations for Firebase / backend / real Google Sign-In later.
class LocalAuthService {
  LocalAuthService(this._storage);

  final LocalStorageRepository _storage;

  Future<AuthSession?> loadSession() => _storage.loadAuthSession();

  Future<void> clearSession() => _storage.clearAuthSession();

  Future<void> _saveSession(AuthSession session) =>
      _storage.saveAuthSession(session);

  Future<void> _saveRegistry(Map<String, dynamic> map) =>
      _storage.saveAuthCredentialRegistry(map);

  Future<Map<String, dynamic>> _loadRegistry() =>
      _storage.loadAuthCredentialRegistry();

  String _hashPassword(String email, String password) {
    final bytes = utf8.encode('$email|${password.trim()}|stepstake_local_v1');
    return sha256.convert(bytes).toString();
  }

  /// Mock Google Sign-In: stable anonymous user on device, no network.
  /// Real implementation: replace body with `GoogleSignIn` + token exchange.
  Future<AuthSession> signInWithGoogleMock() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    var userId = await _storage.loadGoogleMockUserId();
    final now = DateTime.now();
    if (userId == null) {
      final existing = await _storage.loadMockUser();
      userId = existing?.id ?? generateId(prefix: 'guser');
      await _storage.saveGoogleMockUserId(userId);
      final user = MockUser(
        id: userId,
        createdAt: now,
        lastResultShown: true,
      );
      await _storage.saveMockUser(user);
      await _storage.saveUserProfile(
        const UserProfile(
          fullName: 'Google account',
          username: 'google_user',
          email: 'google.mock@stepstake.local',
          avatarEmoji: '👤',
        ),
      );
    } else {
      var existing = await _storage.loadMockUser();
      if (existing == null || existing.id != userId) {
        existing = MockUser(
          id: userId,
          createdAt: now,
          lastResultShown: true,
        );
        await _storage.saveMockUser(existing);
      }
    }

    final profile = await _storage.loadUserProfile();
    final session = AuthSession(
      userId: userId,
      email: profile.email.isNotEmpty
          ? profile.email
          : 'google.mock@stepstake.local',
      fullName: profile.fullName.isNotEmpty
          ? profile.fullName
          : 'Google account',
      authProvider: 'google',
      loginAt: now,
    );
    await _saveSession(session);
    return session;
  }

  Future<AuthSession> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final registry = await _loadRegistry();
    if (registry.containsKey(normalizedEmail)) {
      throw StateError('An account already exists for this email.');
    }

    final existing = await _storage.loadMockUser();
    final reuseAnonymousId = registry.isEmpty && existing != null;
    final userId = reuseAnonymousId ? existing.id : generateId(prefix: 'user');
    if (!reuseAnonymousId) {
      await _storage.clearFinancialAndChallengeState();
    }
    final passwordHash = _hashPassword(normalizedEmail, password);

    registry[normalizedEmail] = {
      'userId': userId,
      'passwordHash': passwordHash,
      'authProvider': 'email',
    };
    await _saveRegistry(registry);

    final user = MockUser(
      id: userId,
      createdAt: existing?.createdAt ?? DateTime.now(),
      lastResultShown: existing?.lastResultShown ?? true,
    );
    await _storage.saveMockUser(user);

    var username = fullName.trim().isEmpty
        ? 'user'
        : fullName.trim().split(' ').first;
    username =
        username.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (username.isEmpty) username = 'user';

    await _storage.saveUserProfile(
      UserProfile(
        fullName: fullName.trim(),
        username: username,
        email: normalizedEmail,
        avatarEmoji: '👤',
      ),
    );

    final session = AuthSession(
      userId: userId,
      email: normalizedEmail,
      fullName: fullName.trim(),
      authProvider: 'email',
      loginAt: DateTime.now(),
    );
    await _saveSession(session);
    return session;
  }

  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final registry = await _loadRegistry();
    final entry = registry[normalizedEmail];
    if (entry is! Map<String, dynamic>) {
      throw StateError('No account found for this email.');
    }
    final expected = entry['passwordHash'] as String?;
    final userId = entry['userId'] as String?;
    if (expected == null || userId == null) {
      throw StateError('Invalid stored credentials.');
    }
    final hash = _hashPassword(normalizedEmail, password);
    if (hash != expected) {
      throw StateError('Incorrect password.');
    }

    var user = await _storage.loadMockUser();
    if (user == null || user.id != userId) {
      user = MockUser(
        id: userId,
        createdAt: DateTime.now(),
        lastResultShown: true,
      );
      await _storage.saveMockUser(user);
    }

    final profile = await _storage.loadUserProfile();
    final session = AuthSession(
      userId: userId,
      email: normalizedEmail,
      fullName: profile.fullName.isNotEmpty ? profile.fullName : normalizedEmail,
      authProvider: 'email',
      loginAt: DateTime.now(),
    );
    await _saveSession(session);
    return session;
  }
}
