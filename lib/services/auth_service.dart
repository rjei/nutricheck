import 'package:flutter/foundation.dart';
import '../data/datasources/auth_data_source.dart';
import '../data/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Service otentikasi aplikasi NutriCheck berbasis [ChangeNotifier].
///
/// Menggunakan pola Singleton dan mendelegasikan penyimpanan ke [AuthRepository].
/// Menjaga kompatibilitas penuh (backward-compatible) dengan kode UI yang ada,
/// namun kini datanya tersimpan persisten ke basis data lokal ([LocalAuthDataSource])
/// dan siap dihubungkan ke Firebase ([FirebaseAuthDataSource]) di masa depan.
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initMemoryFromSeed();
  }

  final AuthRepository _repository = AuthRepository.instance;

  final List<UserModel> _users = [];
  UserModel? _currentUser;
  bool _initialized = false;

  void _initMemoryFromSeed() {
    if (_users.isEmpty) {
      _users.add(LocalAuthDataSource.defaultSeedUser);
    }
  }

  /// Menginisialisasi service saat aplikasi dibuka, memuat sesi tersimpan dari storage lokal.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final savedUser = await _repository.initialize();
      final all = await _repository.getAllUsers();

      _users.clear();
      _users.addAll(all);
      _currentUser = savedUser;
      _initialized = true;
      notifyListeners();
    } catch (_) {
    }
  }

  UserModel? get currentUser => _currentUser ?? _repository.currentUser;
  List<UserModel> get allUsers => List.unmodifiable(_users);
  bool get isLoggedIn => currentUser != null;

  /// Autentikasi login pengguna.
  ///
  /// Dapat dipanggil secara sinkron langsung (UI tidak perlu async),
  /// sementara di latar belakang sesi disimpan persisten ke storage lokal.
  bool login(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    final userIndex = _users.indexWhere(
      (u) => u.email.toLowerCase() == cleanEmail && u.password == password,
    );

    if (userIndex != -1) {
      _currentUser = _users[userIndex];
      _repository.login(email: cleanEmail, password: password);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Versi asinkron dari login jika caller ingin menunggu I/O storage selesai.
  Future<bool> loginAsync(String email, String password) async {
    final user = await _repository.login(email: email, password: password);
    if (user != null) {
      _currentUser = user;
      final idx = _users.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        _users[idx] = user;
      } else {
        _users.add(user);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Mendaftarkan pengguna baru dan otomatis menyimpan secara persisten.
  UserModel registerUser({
    required String fullName,
    required String email,
    required String password,
  }) {
    final cleanEmail = email.trim().toLowerCase();

    final existingIndex =
        _users.indexWhere((u) => u.email.toLowerCase() == cleanEmail);
    if (existingIndex != -1) {
      _currentUser = _users[existingIndex];
      _repository.login(email: cleanEmail, password: password);
      notifyListeners();
      return _currentUser!;
    }

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: cleanEmail,
      password: password,
      selectedConditions: ['Bebas Gluten'],
      primaryGoal: 'Deteksi Bahan Berbahaya & ADI',
      membershipStatus: 'Member since 2026',
      level: 1,
      nutritionScore: 90,
    );

    _users.add(newUser);
    _currentUser = newUser;

    _repository.register(
      fullName: fullName,
      email: email,
      password: password,
    );

    notifyListeners();
    return newUser;
  }

  /// Memperbarui kondisi kesehatan dan target pengguna.
  void updateHealthSurvey({
    required List<String> conditions,
    required String primaryGoal,
  }) {
    if (_currentUser != null) {
      _currentUser!.selectedConditions = List.from(conditions);
      _currentUser!.primaryGoal = primaryGoal;

      final idx = _users.indexWhere((u) => u.id == _currentUser!.id);
      if (idx != -1) {
        _users[idx] = _currentUser!;
      }

      _repository.updateHealthSurvey(
        conditions: conditions,
        primaryGoal: primaryGoal,
      );

      notifyListeners();
    }
  }

  /// Memperbarui nama lengkap dan email profil.
  void updateProfile({
    required String fullName,
    required String email,
  }) {
    if (_currentUser != null) {
      _currentUser!.fullName = fullName.trim();
      _currentUser!.email = email.trim().toLowerCase();

      final idx = _users.indexWhere((u) => u.id == _currentUser!.id);
      if (idx != -1) {
        _users[idx] = _currentUser!;
      }

      _repository.updateProfile(
        fullName: fullName,
        email: email,
      );

      notifyListeners();
    }
  }

  /// Logout akun aktif dan hapus sesi dari storage lokal.
  void logout() {
    _currentUser = null;
    _repository.logout();
    notifyListeners();
  }
}
