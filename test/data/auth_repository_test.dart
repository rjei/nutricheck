import 'package:flutter_test/flutter_test.dart';
import 'package:nutricheck/data/datasources/auth_data_source.dart';
import 'package:nutricheck/data/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalAuthDataSource & AuthRepository', () {
    late LocalAuthDataSource dataSource;
    late AuthRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dataSource = LocalAuthDataSource();
      repository = AuthRepository(dataSource: dataSource);
    });

    test('memuat seed user default saat pertama kali diinisialisasi', () async {
      await repository.initialize();
      final users = await repository.getAllUsers();

      expect(users, isNotEmpty);
      expect(users.first.email, 'budi.santoso@gmail.com');
      expect(users.first.fullName, 'Budi Santoso');
    });

    test('login berhasil dengan email dan kata sandi yang cocok', () async {
      final user = await repository.login(
        email: 'budi.santoso@gmail.com',
        password: 'password123',
      );

      expect(user, isNotNull);
      expect(user!.fullName, 'Budi Santoso');
      expect(repository.isLoggedIn, isTrue);
      expect(repository.currentUser?.id, user.id);
    });

    test('login gagal bila kata sandi salah', () async {
      final user = await repository.login(
        email: 'budi.santoso@gmail.com',
        password: 'passwordSalah',
      );

      expect(user, isNull);
      expect(repository.isLoggedIn, isFalse);
    });

    test('mendaftarkan user baru dan menetapkannya sebagai sesi aktif', () async {
      final newUser = await repository.register(
        fullName: 'Ahmad Dahlan',
        email: 'ahmad@example.com',
        password: 'secretPassword',
      );

      expect(newUser.fullName, 'Ahmad Dahlan');
      expect(newUser.email, 'ahmad@example.com');
      expect(repository.isLoggedIn, isTrue);
      expect(repository.currentUser?.email, 'ahmad@example.com');

      final allUsers = await repository.getAllUsers();
      expect(allUsers.any((u) => u.email == 'ahmad@example.com'), isTrue);
    });

    test('memperbarui survei kesehatan dan tersimpan di database', () async {
      await repository.login(
        email: 'budi.santoso@gmail.com',
        password: 'password123',
      );

      await repository.updateHealthSurvey(
        conditions: ['Intoleransi Laktosa', 'Riwayat Asma'],
        primaryGoal: 'Batasi Natrium & Alergen',
      );

      expect(repository.currentUser?.selectedConditions, [
        'Intoleransi Laktosa',
        'Riwayat Asma',
      ]);
      expect(repository.currentUser?.primaryGoal, 'Batasi Natrium & Alergen');

      // Verifikasi tersimpan di data source
      final fetched = await dataSource.getUserById('usr_001');
      expect(fetched?.selectedConditions, [
        'Intoleransi Laktosa',
        'Riwayat Asma',
      ]);
    });

    test('memperbarui profil pengguna', () async {
      await repository.login(
        email: 'budi.santoso@gmail.com',
        password: 'password123',
      );

      await repository.updateProfile(
        fullName: 'Budi Santoso S.Kom',
        email: 'budi.new@gmail.com',
      );

      expect(repository.currentUser?.fullName, 'Budi Santoso S.Kom');
      expect(repository.currentUser?.email, 'budi.new@gmail.com');
    });

    test('logout menghapus sesi aktif dari repository dan storage', () async {
      await repository.login(
        email: 'budi.santoso@gmail.com',
        password: 'password123',
      );
      expect(repository.isLoggedIn, isTrue);

      await repository.logout();

      expect(repository.isLoggedIn, isFalse);
      expect(repository.currentUser, isNull);

      final session = await dataSource.getActiveSession();
      expect(session, isNull);
    });

    test('sesi aktif bertahan saat aplikasi di-restart (re-initialization)', () async {
      // 1. Simulasikan pengguna login
      await repository.login(
        email: 'budi.santoso@gmail.com',
        password: 'password123',
      );
      expect(repository.isLoggedIn, isTrue);

      // 2. Simulasikan instance repository baru (seperti setelah restart app)
      final newRepositoryInstance = AuthRepository(dataSource: LocalAuthDataSource());
      expect(newRepositoryInstance.isLoggedIn, isFalse);

      // 3. Panggil initialize() seperti di main()
      await newRepositoryInstance.initialize();

      expect(newRepositoryInstance.isLoggedIn, isTrue);
      expect(newRepositoryInstance.currentUser?.email, 'budi.santoso@gmail.com');
    });
  });
}
