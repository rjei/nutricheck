import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutricheck/data/datasources/auth_data_source.dart';
import 'package:nutricheck/data/models/user_model.dart';
import 'package:nutricheck/data/repositories/auth_repository.dart';

class _FakeAuthDataSource implements AuthDataSource {
  final Map<String, UserModel> _users = {};
  UserModel? _activeUser;

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  Future<void> clearActiveSession() async {
    _activeUser = null;
  }

  @override
  Future<UserModel?> getActiveSession() async => _activeUser;

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final clean = email.trim().toLowerCase();
    for (final u in _users.values) {
      if (u.email.toLowerCase() == clean) return u;
    }
    return null;
  }

  @override
  Future<UserModel?> getUserById(String id) async => _users[id];

  @override
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final user = await getUserByEmail(email);
    if (user == null || password != 'valid_pass') return null;
    _activeUser = user;
    return user;
  }

  @override
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final user = UserModel(
      id: 'uid_${_users.length + 1}',
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      provider: 'email',
      hasCompletedHealthSurvey: false,
    );
    _users[user.id] = user;
    _activeUser = user;
    return user;
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    final user = UserModel(
      id: 'google_uid_1',
      fullName: 'Google User',
      email: 'google.user@gmail.com',
      provider: 'google',
      hasCompletedHealthSurvey: false,
    );
    _users[user.id] = user;
    _activeUser = user;
    return user;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    _users[user.id] = user;
    if (_activeUser?.id == user.id) _activeUser = user;
  }
}

void main() {
  group('AuthRepository with AuthDataSource', () {
    late _FakeAuthDataSource dataSource;
    late AuthRepository repository;

    setUp(() {
      dataSource = _FakeAuthDataSource();
      repository = AuthRepository(dataSource: dataSource);
    });

    test('register user baru dan set sesi aktif', () async {
      final newUser = await repository.register(
        fullName: 'Ahmad Dahlan',
        email: 'ahmad@example.com',
        password: 'secretPassword',
      );

      expect(newUser.fullName, 'Ahmad Dahlan');
      expect(newUser.email, 'ahmad@example.com');
      expect(newUser.hasCompletedHealthSurvey, isFalse);
      expect(repository.isLoggedIn, isTrue);
    });

    test('login berhasil dengan kredensial valid dan gagal jika salah', () async {
      await repository.register(
        fullName: 'Budi',
        email: 'budi@gmail.com',
        password: 'valid_pass',
      );
      await repository.logout();

      final failed = await repository.login(
        email: 'budi@gmail.com',
        password: 'wrong',
      );
      expect(failed, isNull);
      expect(repository.isLoggedIn, isFalse);

      final success = await repository.login(
        email: 'budi@gmail.com',
        password: 'valid_pass',
      );
      expect(success, isNotNull);
      expect(repository.isLoggedIn, isTrue);
    });

    test('signInWithGoogle membuat sesi google provider', () async {
      final user = await repository.signInWithGoogle();
      expect(user, isNotNull);
      expect(user!.provider, 'google');
      expect(repository.isLoggedIn, isTrue);
    });

    test('updateHealthSurvey dan updateHasCompletedSurvey tersimpan', () async {
      await repository.signInWithGoogle();
      await repository.updateHealthSurvey(
        conditions: ['Intoleransi Laktosa'],
        primaryGoal: 'Batasi Natrium',
      );

      expect(repository.currentUser?.hasCompletedHealthSurvey, isTrue);
      expect(repository.currentUser?.selectedConditions, ['Intoleransi Laktosa']);

      await repository.updateHasCompletedSurvey(false);
      expect(repository.currentUser?.hasCompletedHealthSurvey, isFalse);
    });
  });
}
