import '../../core/id_generator.dart';
import '../../data/models/mock_user.dart';
import '../../data/persistence/local_storage_repository.dart';
import 'auth_service.dart';

class MockAuthService implements AuthService {
  final LocalStorageRepository storage;

  const MockAuthService({required this.storage});

  @override
  Future<MockUser> getOrCreateLocalUser() async {
    final existing = await storage.loadMockUser();
    if (existing != null) return existing;

    final user = MockUser(
      id: generateId(prefix: 'user'),
      createdAt: DateTime.now(),
      lastResultShown: false,
    );
    await storage.saveMockUser(user);
    return user;
  }
}

