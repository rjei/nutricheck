import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  String fullName;
  String email;
  List<String> selectedConditions;
  String primaryGoal;
  String avatarUrl;
  bool hasCompletedHealthSurvey;
  String provider;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.selectedConditions = const [],
    this.primaryGoal = 'Deteksi Bahan Berbahaya & ADI',
    this.avatarUrl = '',
    this.hasCompletedHealthSurvey = false,
    this.provider = 'email',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'uid': id,
        'fullName': fullName,
        'email': email,
        'selectedConditions': selectedConditions,
        'primaryGoal': primaryGoal,
        'avatarUrl': avatarUrl,
        'hasCompletedHealthSurvey': hasCompletedHealthSurvey,
        'provider': provider,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'];
    DateTime parsedCreatedAt = DateTime.now();
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt != null) {
      parsedCreatedAt =
          DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now();
    }

    return UserModel(
      id: (json['uid'] ?? json['id'] ?? '') as String,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      selectedConditions: (json['selectedConditions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      primaryGoal:
          json['primaryGoal'] as String? ?? 'Deteksi Bahan Berbahaya & ADI',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      hasCompletedHealthSurvey:
          json['hasCompletedHealthSurvey'] as bool? ?? false,
      provider: json['provider'] as String? ?? 'email',
      createdAt: parsedCreatedAt,
    );
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    List<String>? selectedConditions,
    String? primaryGoal,
    String? avatarUrl,
    bool? hasCompletedHealthSurvey,
    String? provider,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      selectedConditions: selectedConditions != null
          ? List.from(selectedConditions)
          : List.from(this.selectedConditions),
      primaryGoal: primaryGoal ?? this.primaryGoal,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hasCompletedHealthSurvey:
          hasCompletedHealthSurvey ?? this.hasCompletedHealthSurvey,
      provider: provider ?? this.provider,
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
