/// Model data pengguna NutriCheck.
///
/// Menyimpan informasi profil, kredensial, dan preferensi kondisi kesehatan/alergi.
/// Dirancang serializable (JSON) agar kompatibel dengan penyimpanan lokal
/// ([SharedPreferences]) saat ini dan dokumen Firestore ([cloud_firestore]) di masa depan.
class UserModel {
  final String id;
  String fullName;
  String email;
  String password;
  List<String> selectedConditions;
  String primaryGoal;
  String membershipStatus;
  int level;
  int nutritionScore;
  String avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    this.selectedConditions = const [],
    this.primaryGoal = 'Deteksi Bahan Berbahaya & ADI',
    this.membershipStatus = 'Premium Member since January 2024',
    this.level = 12,
    this.nutritionScore = 85,
    this.avatarUrl =
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Konversi ke Map/JSON untuk penyimpanan lokal maupun dokumen Firestore.
  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'password': password,
        'selectedConditions': selectedConditions,
        'primaryGoal': primaryGoal,
        'membershipStatus': membershipStatus,
        'level': level,
        'nutritionScore': nutritionScore,
        'avatarUrl': avatarUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Rekonstruksi dari Map/JSON lokal atau dokumen Firestore.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      selectedConditions: (json['selectedConditions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      primaryGoal:
          json['primaryGoal'] as String? ?? 'Deteksi Bahan Berbahaya & ADI',
      membershipStatus:
          json['membershipStatus'] as String? ?? 'Member since 2024',
      level: json['level'] as int? ?? 1,
      nutritionScore: json['nutritionScore'] as int? ?? 85,
      avatarUrl: json['avatarUrl'] as String? ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Membuat salinan objek dengan field tertentu yang diperbarui secara aman.
  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? password,
    List<String>? selectedConditions,
    String? primaryGoal,
    String? membershipStatus,
    int? level,
    int? nutritionScore,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      selectedConditions: selectedConditions != null
          ? List.from(selectedConditions)
          : List.from(this.selectedConditions),
      primaryGoal: primaryGoal ?? this.primaryGoal,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      level: level ?? this.level,
      nutritionScore: nutritionScore ?? this.nutritionScore,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email.toLowerCase() == other.email.toLowerCase();

  @override
  int get hashCode => id.hashCode ^ email.toLowerCase().hashCode;
}
