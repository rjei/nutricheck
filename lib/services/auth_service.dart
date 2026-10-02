import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Hardcoded initial database of users
  final List<UserModel> _users = [
    UserModel(
      id: 'usr_001',
      fullName: 'Budi Santoso',
      email: 'budi.santoso@gmail.com',
      password: 'password123',
      selectedConditions: ['Bebas Gluten', 'Hipertensi / Sensitif Garam'],
      primaryGoal: 'Pantau Diet & Nutrisi Harian',
      membershipStatus: 'Member since February 2024',
      level: 12,
      nutritionScore: 85,
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
    ),
  ];

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  List<UserModel> get allUsers => List.unmodifiable(_users);
  bool get isLoggedIn => _currentUser != null;

  // READ: Authenticate user login
  bool login(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    final userIndex = _users.indexWhere(
      (u) => u.email.toLowerCase() == cleanEmail && u.password == password,
    );

    if (userIndex != -1) {
      _currentUser = _users[userIndex];
      notifyListeners();
      return true;
    }
    return false;
  }

  // CREATE: Register new user
  UserModel registerUser({
    required String fullName,
    required String email,
    required String password,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    
    // Check if email already exists
    final existingIndex = _users.indexWhere((u) => u.email.toLowerCase() == cleanEmail);
    if (existingIndex != -1) {
      _currentUser = _users[existingIndex];
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
      membershipStatus: 'Member since September 2026',
      level: 1,
      nutritionScore: 90,
    );

    _users.add(newUser);
    _currentUser = newUser;
    notifyListeners();
    return newUser;
  }

  // UPDATE: Save/update health survey conditions & primary goal
  void updateHealthSurvey({
    required List<String> conditions,
    required String primaryGoal,
  }) {
    if (_currentUser != null) {
      _currentUser!.selectedConditions = List.from(conditions);
      _currentUser!.primaryGoal = primaryGoal;
      notifyListeners();
    }
  }

  // UPDATE: Update profile name & email
  void updateProfile({
    required String fullName,
    required String email,
  }) {
    if (_currentUser != null) {
      _currentUser!.fullName = fullName;
      _currentUser!.email = email;
      notifyListeners();
    }
  }

  // DELETE: Logout active user
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
