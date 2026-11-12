# Basis Data Pengguna & Autentikasi

Basis data pengguna dan autentikasi NutriCheck (SRS 6.1 & 6.2). Tahap awal diimplementasikan secara **lokal & persisten** menggunakan `SharedPreferences` (`LocalAuthDataSource`), dan dirancang mengikuti arsitektur Clean Repository agar dapat dipindah ke **Firebase Authentication & Cloud Firestore** tanpa merombak UI.

---

## Arsitektur

```
UI (LoginScreen, RegisterScreen, ProfileScreen, HealthSurveyScreen)
        │  memanggil
        ▼
AuthService / AuthRepository     lib/data/repositories/auth_repository.dart
  (currentUser, isLoggedIn, login, register, updateSurvey, updateProfile)
        │  bergantung pada interface
        ▼
AuthDataSource                   lib/data/datasources/auth_data_source.dart
  ├─ LocalAuthDataSource         ← sekarang (SharedPreferences persisten)
  └─ FirebaseAuthDataSource       ← nanti (fase cloud: Firebase Auth + Firestore)
```

| File | Isi |
| :--- | :--- |
| `lib/data/models/user_model.dart` | Model data `UserModel` + `fromJson`, `toJson`, `copyWith` |
| `lib/data/datasources/auth_data_source.dart` | Interface `AuthDataSource`, `LocalAuthDataSource`, dan blueprint `FirebaseAuthDataSource` |
| `lib/data/repositories/auth_repository.dart` | Repository layer pengelola sesi, cache aktif, dan abstraksi data source |
| `lib/services/auth_service.dart` | Singleton facade reaktif (`ChangeNotifier`) untuk konsumsi UI |

---

## Skema Data (`UserModel`)

Format dokumen yang disimpan baik pada storage lokal (JSON) maupun dokumen Firestore masa depan:

```jsonc
{
  "id": "usr_001",
  "fullName": "Budi Santoso",
  "email": "budi.santoso@gmail.com",
  "password": "password123",                    // Pada fase Firebase dikelola Firebase Auth
  "selectedConditions": [
    "Bebas Gluten",
    "Hipertensi / Sensitif Garam"
  ],
  "primaryGoal": "Pantau Diet & Nutrisi Harian",
  "membershipStatus": "Member since February 2024",
  "level": 12,
  "nutritionScore": 85,
  "avatarUrl": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80",
  "createdAt": "2026-10-27T00:00:00.000Z"
}
```

---

## Contoh Pemakaian

### 1. Inisialisasi pada Bootstrap Aplikasi
Pada `main.dart`, sesi dimuat sebelum aplikasi berjalan:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().initialize();
  runApp(const NutriCheckApp());
}
```

### 2. Autentikasi Pengguna
```dart
final auth = AuthService();

// Login
final sukses = auth.login('budi.santoso@gmail.com', 'password123');

// Register akun baru
final userBaru = auth.registerUser(
  fullName: 'Rizki Muda',
  email: 'rizki@example.com',
  password: 'passwordRahasia',
);

// Logout
auth.logout();
```

### 3. Update Kondisi Kesehatan & Profil
```dart
// Memperbarui survei kesehatan (alergi/kondisi)
auth.updateHealthSurvey(
  conditions: ['Intoleransi Sulfite / Pengawet', 'Riwayat Asma'],
  primaryGoal: 'Deteksi Bahan Berbahaya & ADI',
);

// Mengambil profil pengguna aktif
final userAktif = auth.currentUser;
print('User: ${userAktif?.fullName}, Alergi: ${userAktif?.selectedConditions}');
```

---

## Rencana Migrasi ke Firebase

### Struktur Firestore
```
users/{userId}               ← Dokumen profil per pengguna (UserModel.toJson())
  ├─ fullName: String
  ├─ email: String
  ├─ selectedConditions: Array<String>
  ├─ primaryGoal: String
  ├─ level: Number
  ├─ nutritionScore: Number
  └─ createdAt: Timestamp
```

### Langkah Migrasi:
1. **Tambahkan Paket**:
   Tambahkan `firebase_core`, `firebase_auth`, dan `cloud_firestore` pada `pubspec.yaml`.
2. **Implementasikan `FirebaseAuthDataSource`**:
   Aktifkan kelas `FirebaseAuthDataSource` pada `lib/data/datasources/auth_data_source.dart`:
   - `login()` → memanggil `FirebaseAuth.instance.signInWithEmailAndPassword()` lalu mengambil data profil dari `FirebaseFirestore.instance.collection('users').doc(uid)`.
   - `register()` → memanggil `FirebaseAuth.instance.createUserWithEmailAndPassword()` lalu membuat dokumen Firestore awal.
   - `updateUser()` → memanggil `doc(uid).update(user.toJson())`.
3. **Ganti Data Source**:
   Cukup panggil saat bootstrap:
   ```dart
   AuthRepository.instance.setDataSource(FirebaseAuthDataSource());
   ```
   **UI tidak perlu diubah sama sekali** karena seluruh layar hanya berinteraksi dengan `AuthService` dan `UserModel`.
4. **Offline Persistence**:
   Firestore secara default telah mendukung *offline persistence*, sehingga pengguna tetap dapat mengakses profil dan preferensi kesehatan saat tidak ada jaringan internet.
