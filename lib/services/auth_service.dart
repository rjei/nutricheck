import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final AuthRepository _repository = AuthRepository.instance;

  UserModel? _currentUser;
  bool _initialized = false;
  StreamSubscription<User?>? _authSub;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _currentUser = await _repository.initialize();
      _authSub ??= _repository.authStateChanges().listen((fbUser) async {
        if (fbUser == null) {
          if (_currentUser != null) {
            _currentUser = null;
            notifyListeners();
          }
        } else if (_currentUser?.id != fbUser.uid) {
          _currentUser = await _repository.dataSource.getActiveSession();
          notifyListeners();
        }
      });
      _initialized = true;
      notifyListeners();
    } catch (_) {
      _initialized = true;
    }
  }

  UserModel? get currentUser => _currentUser ?? _repository.currentUser;
  bool get isLoggedIn => currentUser != null;

  @visibleForTesting
  void setTestUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<bool> loginAsync(String email, String password) async {
    final user = await _repository.login(email: email, password: password);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<UserModel?> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final user = await _repository.register(
      fullName: fullName,
      email: email,
      password: password,
    );
    _currentUser = user;
    notifyListeners();
    return user;
  }

  Future<bool> signInWithGoogle() async {
    final user = await _repository.signInWithGoogle();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
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
    notifyListeners();
    await _repository.updateHealthSurvey(
      conditions: conditions,
      primaryGoal: primaryGoal,
      hasCompletedHealthSurvey: hasCompletedHealthSurvey,
    );
  }

  Future<void> updateHasCompletedSurvey(bool completed) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      hasCompletedHealthSurvey: completed,
    );
    notifyListeners();
    await _repository.updateHasCompletedSurvey(completed);
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
    notifyListeners();
    await _repository.updateProfile(
      fullName: _currentUser!.fullName,
      email: _currentUser!.email,
      avatarUrl: _currentUser!.avatarUrl,
    );
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
    try {
      await _repository.logout();
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
