import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';
import '../models/challenge.dart';
import '../models/connected_devices_state.dart';
import '../models/mock_user.dart';
import '../models/user_profile.dart';
import '../models/wallet.dart';
import 'storage_keys.dart';

class LocalStorageRepository {
  final SharedPreferences _prefs;

  const LocalStorageRepository(this._prefs);

  Future<bool> isOnboardingCompleted() async =>
      _prefs.getBool(StorageKeys.onboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted({required bool completed}) async {
    await _prefs.setBool(StorageKeys.onboardingCompleted, completed);
  }

  Future<MockUser?> loadMockUser() async {
    final raw = _prefs.getString(StorageKeys.mockUser);
    if (raw == null) return null;
    return MockUser.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  Future<void> saveMockUser(MockUser user) async {
    await _prefs.setString(
      StorageKeys.mockUser,
      json.encode(user.toJson()),
    );
  }

  Future<Wallet> loadWallet() async {
    final raw = _prefs.getString(StorageKeys.wallet);
    if (raw == null) return Wallet.empty;
    return Wallet.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  Future<void> saveWallet(Wallet wallet) async {
    await _prefs.setString(
      StorageKeys.wallet,
      json.encode(wallet.toJson()),
    );
  }

  Future<Challenge?> loadActiveChallenge() async {
    final raw = _prefs.getString(StorageKeys.activeChallenge);
    if (raw == null) return null;
    return Challenge.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  Future<void> saveActiveChallenge(Challenge? challenge) async {
    if (challenge == null) {
      await _prefs.remove(StorageKeys.activeChallenge);
      return;
    }
    await _prefs.setString(
      StorageKeys.activeChallenge,
      json.encode(challenge.toJson()),
    );
  }

  Future<Challenge?> loadLastCompletedChallenge() async {
    final raw = _prefs.getString(StorageKeys.lastCompletedChallenge);
    if (raw == null) return null;
    return Challenge.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  Future<void> saveLastCompletedChallenge(Challenge? challenge) async {
    if (challenge == null) {
      await _prefs.remove(StorageKeys.lastCompletedChallenge);
      return;
    }
    await _prefs.setString(
      StorageKeys.lastCompletedChallenge,
      json.encode(challenge.toJson()),
    );
  }

  Future<UserProfile> loadUserProfile() async {
    final raw = _prefs.getString(StorageKeys.userProfile);
    if (raw == null) return UserProfile.empty;
    return UserProfile.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs.setString(
      StorageKeys.userProfile,
      json.encode(profile.toJson()),
    );
  }

  Future<ConnectedDevicesState> loadConnectedDevices() async {
    final raw = _prefs.getString(StorageKeys.connectedDevices);
    if (raw == null) return ConnectedDevicesState.none;
    return ConnectedDevicesState.fromJson(
      json.decode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> saveConnectedDevices(ConnectedDevicesState state) async {
    await _prefs.setString(
      StorageKeys.connectedDevices,
      json.encode(state.toJson()),
    );
  }

  Future<AuthSession?> loadAuthSession() async {
    final raw = _prefs.getString(StorageKeys.authSession);
    if (raw == null) return null;
    return AuthSession.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  Future<void> saveAuthSession(AuthSession session) async {
    await _prefs.setString(
      StorageKeys.authSession,
      json.encode(session.toJson()),
    );
  }

  Future<void> clearAuthSession() async {
    await _prefs.remove(StorageKeys.authSession);
  }

  Future<String?> loadGoogleMockUserId() async =>
      _prefs.getString(StorageKeys.googleMockLinkedUserId);

  Future<void> saveGoogleMockUserId(String id) async {
    await _prefs.setString(StorageKeys.googleMockLinkedUserId, id);
  }

  Future<Map<String, dynamic>> loadAuthCredentialRegistry() async {
    final raw = _prefs.getString(StorageKeys.authCredentialRegistry);
    if (raw == null) return {};
    final decoded = json.decode(raw);
    if (decoded is Map<String, dynamic>) {
      return Map<String, dynamic>.from(decoded);
    }
    return {};
  }

  Future<void> saveAuthCredentialRegistry(Map<String, dynamic> map) async {
    await _prefs.setString(
      StorageKeys.authCredentialRegistry,
      json.encode(map),
    );
  }

  /// Clears wallet and challenge records (e.g. new account on a device that had another user).
  Future<void> clearFinancialAndChallengeState() async {
    await saveWallet(Wallet.empty);
    await saveActiveChallenge(null);
    await saveLastCompletedChallenge(null);
  }
}

