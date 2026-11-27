import 'package:firebase_auth/firebase_auth.dart';
import '../datasources/auth_data_source.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository({required AuthDataSource dataSource})
      : _dataSource = dataSource;

  static final AuthRepository instance = AuthRepository(
    dataSource: FirebaseAuthDataSource(),
  );

  AuthDataSource _dataSource;
  UserModel? _currentUser;
  bool _initialized = false;

  AuthDataSource get dataSource => _dataSource;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  void setDataSource(AuthDataSource dataSource) {
    _dataSource = dataSource;
    _initialized = false;
    _currentUser = null;
  }

  Stream<User?> authStateChanges() => _dataSource.authStateChanges();

  Future<UserModel?> initialize() async {
    if (_initialized) return _currentUser;
    _currentUser = await _dataSource.getActiveSession();
    _initialized = true;
    return _currentUser;
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final user = await _dataSource.login(
      email: email.trim().toLowerCase(),
      password: password,
    );
    if (user != null) {
      _currentUser = user;
    }
    return user;
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final user = await _dataSource.register(
      fullName: fullName,
      email: email,
      password: password,
    );
    _currentUser = user;
    return user;
  }

  Future<UserModel?> signInWithGoogle() async {
    final user = await _dataSource.signInWithGoogle();
    if (user != null) {
      _currentUser = user;
    }
    return user;
  }

  Future<void> updateHealthSurvey({
    required List<String> conditions,
    required String primaryGoal,
    bool hasCompletedHealthSurvey = true,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      selectedConditions: List.from(conditions),
      primaryGoal: primaryGoal,
      hasCompletedHealthSurvey: hasCompletedHealthSurvey,
    );
    await _dataSource.updateUser(_currentUser!);
  }

  Future<void> updateHasCompletedSurvey(bool completed) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      hasCompletedHealthSurvey: completed,
    );
    await _dataSource.updateUser(_currentUser!);
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      avatarUrl: (avatarUrl != null && avatarUrl.trim().isNotEmpty)
          ? avatarUrl.trim()
          : _currentUser!.avatarUrl,
    );
    await _dataSource.updateUser(_currentUser!);
  }

  Future<void> logout() async {
    await _dataSource.clearActiveSession();
    _currentUser = null;
  }
}
