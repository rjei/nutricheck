import 'additive.dart';

/// Paket lengkap basis data aditif beserta metadata versinya.
///
/// [version] dipakai untuk sinkronisasi cloud: aplikasi cukup membandingkan
/// versi lokal dengan dokumen `meta/additives` di Firestore untuk tahu apakah
/// perlu mengunduh ulang data.
class AdditiveDataset {
  const AdditiveDataset({
    required this.version,
    required this.updatedAt,
    required this.additives,
  });

  final int version;
  final DateTime updatedAt;
  final List<Additive> additives;

  factory AdditiveDataset.fromJson(Map<String, dynamic> json) {
    final rawList = json['additives'] as List? ?? const [];
    return AdditiveDataset(
      version: (json['version'] as num?)?.toInt() ?? 0,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime(2026),
      additives: rawList
          .map((e) => Additive.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'updatedAt': updatedAt.toIso8601String(),
        'additives': additives.map((a) => a.toJson()).toList(),
      };
}
