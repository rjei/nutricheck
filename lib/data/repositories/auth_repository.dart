import '../datasources/auth_data_source.dart';
import '../models/user_model.dart';

/// Titik akses tunggal autentikasi dan data akun pengguna.
///
/// Bertindak sebagai repository layer yang memisahkan logika UI dari sumber data
/// fisik ([LocalAuthDataSource] saat ini, atau [FirebaseAuthDataSource] nantinya).
class AuthRepository {
  AuthRepository({required AuthDataSource dataSource})
      : _dataSource = dataSource;

  /// Instance default menggunakan penyimpanan lokal persisten.
  static final AuthRepository instance = AuthRepository(
    dataSource: LocalAuthDataSource(),
  );

  AuthDataSource _dataSource;
  UserModel? _currentUser;
  bool _initialized = false;

  /// Sumber data aktif yang sedang digunakan.
  AuthDataSource get dataSource => _dataSource;

  /// Pengguna yang sedang aktif login. `null` bila belum login.
  UserModel? get currentUser => _currentUser;

  /// Status apakah ada sesi pengguna yang sedang aktif.
  bool get isLoggedIn => _currentUser != null;

  /// Mengganti sumber data secara dinamis (mis. beralih ke Firebase saat cloud phase).
  void setDataSource(AuthDataSource dataSource) {
    _dataSource = dataSource;
    _initialized = false;
    _currentUser = null;
  }

  /// Memuat sesi tersimpan dari database. Dipanggil saat bootstrap aplikasi.
  Future<UserModel?> initialize() async {
    if (_initialized) return _currentUser;
    _currentUser = await _dataSource.getActiveSession();
    _initialized = true;
    return _currentUser;
  }

  /// Melakukan login akun.
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

  /// Mendaftarkan akun baru.
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

  /// Memperbarui preferensi survei kesehatan & pemicu alergi pengguna aktif.
  Future<void> updateHealthSurvey({
    required List<String> conditions,
    required String primaryGoal,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      selectedConditions: List.from(conditions),
      primaryGoal: primaryGoal,
    );
    await _dataSource.updateUser(_currentUser!);
  }

  /// Memperbarui informasi profil pengguna aktif.
  Future<void> updateProfile({
    required String fullName,
    required String email,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
    );
    await _dataSource.updateUser(_currentUser!);
  }

  /// Logout dan bersihkan sesi aktif.
  Future<void> logout() async {
    await _dataSource.clearActiveSession();
    _currentUser = null;
  }

  /// Mengambil semua akun pengguna yang tersimpan (untuk keperluan dev / debugging).
  Future<List<UserModel>> getAllUsers() => _dataSource.getAllUsers();
}
