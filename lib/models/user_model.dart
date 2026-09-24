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
    this.avatarUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
  });
}
