import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Kontrak sumber data autentikasi dan akun pengguna.
///
/// Mengikuti arsitektur clean data layer NutriCheck yang memungkinkan
/// pergantian sumber data dari lokal ([LocalAuthDataSource]) ke cloud
/// ([FirebaseAuthDataSource]) di masa depan tanpa memengaruhi UI.
abstract class AuthDataSource {
  /// Mengambil profil pengguna yang sesi loginnya sedang aktif (bila ada).
  Future<UserModel?> getActiveSession();

  /// Menetapkan sesi pengguna aktif berdasarkan [userId].
  Future<void> setActiveSession(String userId);

  /// Menghapus sesi aktif (logout).
  Future<void> clearActiveSession();

  /// Mencocokkan kredensial login. Mengembalikan [UserModel] jika sukses,
  /// atau `null` jika email/password salah.
  Future<UserModel?> login({
    required String email,
    required String password,
  });

  /// Mendaftarkan pengguna baru ke database.
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  });

  /// Menyimpan perubahan data pengguna (nama, email, preferensi alergi/survei).
  Future<void> updateUser(UserModel user);

  /// Mencari pengguna berdasarkan ID.
  Future<UserModel?> getUserById(String id);

  /// Mencari pengguna berdasarkan alamat email.
  Future<UserModel?> getUserByEmail(String email);

  /// Mengambil seluruh pengguna terdaftar (untuk audit / keperluan dev).
  Future<List<UserModel>> getAllUsers();
}

/// Implementasi basis data pengguna lokal berbasis [SharedPreferences].
///
/// Menyimpan data akun terdaftar dan sesi login aktif secara persisten di perangkat.
class LocalAuthDataSource implements AuthDataSource {
  LocalAuthDataSource({
    this.storageKey = 'nutricheck_users_v1',
    this.sessionKey = 'nutricheck_active_user_id_v1',
    SharedPreferences? prefs,
  }) : _prefs = prefs;

  final String storageKey;
  final String sessionKey;
  SharedPreferences? _prefs;

  Map<String, UserModel>? _usersCache;

  /// Akun bawaan (seed data) untuk memastikan kompatibilitas testing & demo.
  static UserModel get defaultSeedUser => UserModel(
        id: 'usr_001',
        fullName: 'Budi Santoso',
        email: 'budi.santoso@gmail.com',
        password: 'password123',
        selectedConditions: ['Bebas Gluten', 'Hipertensi / Sensitif Garam'],
        primaryGoal: 'Pantau Diet & Nutrisi Harian',
        membershipStatus: 'Member since February 2024',
        level: 12,
        nutritionScore: 85,
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
      );

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Map<String, UserModel>> _loadUsers() async {
    if (_usersCache != null) return _usersCache!;
    final users = <String, UserModel>{};

    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          users[entry.key] =
              UserModel.fromJson(Map<String, dynamic>.from(entry.value as Map));
        }
      }
    } catch (_) {
      users.clear();
    }

    if (users.isEmpty) {
      final seed = defaultSeedUser;
      users[seed.id] = seed;
      await _persistUsers(users);
    }

    return _usersCache = users;
  }

  Future<void> _persistUsers(Map<String, UserModel> users) async {
    try {
      final prefs = await _getPrefs();
      final payload = jsonEncode(users.map((k, v) => MapEntry(k, v.toJson())));
      await prefs.setString(storageKey, payload);
    } catch (_) {
    }
  }

  @override
  Future<UserModel?> getActiveSession() async {
    try {
      final prefs = await _getPrefs();
      final activeId = prefs.getString(sessionKey);
      if (activeId == null || activeId.isEmpty) return null;
      return await getUserById(activeId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setActiveSession(String userId) async {
    final prefs = await _getPrefs();
    await prefs.setString(sessionKey, userId);
  }

  @override
  Future<void> clearActiveSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(sessionKey);
  }

  @override
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = await _loadUsers();

    for (final user in users.values) {
      if (user.email.toLowerCase() == cleanEmail && user.password == password) {
        await setActiveSession(user.id);
        return user;
      }
    }
    return null;
  }

  @override
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = await _loadUsers();

    for (final existing in users.values) {
      if (existing.email.toLowerCase() == cleanEmail) {
        await setActiveSession(existing.id);
        return existing;
      }
    }

    final newId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = UserModel(
      id: newId,
      fullName: fullName.trim(),
      email: cleanEmail,
      password: password,
      selectedConditions: ['Bebas Gluten'],
      primaryGoal: 'Deteksi Bahan Berbahaya & ADI',
      membershipStatus: 'Member since 2026',
      level: 1,
      nutritionScore: 90,
    );

    users[newUser.id] = newUser;
    await _persistUsers(users);
    await setActiveSession(newUser.id);
    return newUser;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    final users = await _loadUsers();
    users[user.id] = user;
    await _persistUsers(users);
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    final users = await _loadUsers();
    return users[id];
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = await _loadUsers();
    for (final user in users.values) {
      if (user.email.toLowerCase() == cleanEmail) return user;
    }
    return null;
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final users = await _loadUsers();
    return List.unmodifiable(users.values);
  }
}

/// Blueprint implementasi cloud berbasis Firebase Auth & Cloud Firestore.
///
/// Siap digunakan saat dependensi `firebase_auth` & `cloud_firestore` ditambahkan.
/// Memetakan user Firestore di koleksi `/users/{userId}`.
class FirebaseAuthDataSource implements AuthDataSource {

  @override
  Future<UserModel?> getActiveSession() async {
    throw UnimplementedError(
      'FirebaseAuthDataSource akan diaktifkan saat konfigurasi Firebase terpasang.',
    );
  }

  @override
  Future<void> setActiveSession(String userId) async {}

  @override
  Future<void> clearActiveSession() async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel?> login({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateUser(UserModel user) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    throw UnimplementedError();
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    throw UnimplementedError();
  }
}
