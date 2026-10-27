import 'additive_category.dart';
import 'risk_level.dart';

/// Satu entri zat aditif di basis data.
///
/// Struktur sengaja dibuat "Firestore-friendly":
/// - hanya tipe primitif, list, dan map (tanpa `Color`, `IconData`, dll.)
/// - [id] dipakai sebagai document id di koleksi `additives`
/// - [updatedAt] disimpan sebagai string ISO-8601 di JSON; data source
///   Firestore nanti cukup mengonversi `Timestamp` <-> `DateTime`.
class Additive {
  const Additive({
    required this.id,
    required this.name,
    required this.category,
    required this.riskLevel,
    required this.summary,
    required this.updatedAt,
    this.eNumber,
    this.aliases = const [],
    this.healthEffects = const [],
    this.adiMgPerKgBw,
    this.adiNote,
    this.conditionTriggers = const [],
    this.bpomPermitted = true,
    this.commonIn = const [],
    this.sources = const [],
  });

  /// Id unik & stabil. Untuk BTP ber-kode, sama dengan kode E (mis. `E211`).
  /// Untuk bahan dilarang tanpa kode, berupa slug (mis. `formalin`).
  final String id;

  /// Kode E / INS, mis. `E211`, `E150d`. `null` untuk bahan tanpa kode.
  final String? eNumber;

  /// Nama Indonesia yang ditampilkan.
  final String name;

  /// Nama lain (Inggris, nama dagang, sinonim) untuk pencarian & pencocokan
  /// teks komposisi.
  final List<String> aliases;

  final AdditiveCategory category;
  final RiskLevel riskLevel;

  /// Penjelasan singkat yang mudah dipahami konsumen awam.
  final String summary;

  /// Potensi efek kesehatan (poin-poin).
  final List<String> healthEffects;

  /// Acceptable Daily Intake dalam mg per kg berat badan per hari.
  /// `null` berarti tidak ditentukan ("not specified") atau tidak berlaku.
  final double? adiMgPerKgBw;

  /// Keterangan tambahan ADI, mis. "Tidak ditentukan (aman)".
  final String? adiNote;

  /// Id [HealthCondition] yang perlu diwaspadai terhadap aditif ini.
  final List<String> conditionTriggers;

  /// Apakah diizinkan sebagai BTP oleh BPOM.
  final bool bpomPermitted;

  /// Contoh produk yang umum mengandung aditif ini.
  final List<String> commonIn;

  /// Sumber referensi (BPOM, JECFA, EFSA, dll.).
  final List<String> sources;

  final DateTime updatedAt;

  /// Nama untuk tampilan ringkas, mis. "E211 (Natrium Benzoat)".
  String get displayName => eNumber == null ? name : '$eNumber ($name)';

  /// Estimasi batas harian (mg) berdasarkan berat badan.
  double? maxDailyIntakeMg(double bodyWeightKg) =>
      adiMgPerKgBw == null ? null : adiMgPerKgBw! * bodyWeightKg;

  bool isTriggerFor(Iterable<String> conditionIds) =>
      conditionTriggers.any(conditionIds.contains);

  factory Additive.fromJson(Map<String, dynamic> json) {
    return Additive(
      id: json['id'] as String,
      eNumber: json['eNumber'] as String?,
      name: json['name'] as String,
      aliases: _stringList(json['aliases']),
      category: AdditiveCategory.fromKey(json['category'] as String?),
      riskLevel: RiskLevel.fromKey(json['riskLevel'] as String?),
      summary: json['summary'] as String? ?? '',
      healthEffects: _stringList(json['healthEffects']),
      adiMgPerKgBw: (json['adiMgPerKgBw'] as num?)?.toDouble(),
      adiNote: json['adiNote'] as String?,
      conditionTriggers: _stringList(json['conditionTriggers']),
      bpomPermitted: json['bpomPermitted'] as bool? ?? true,
      commonIn: _stringList(json['commonIn']),
      sources: _stringList(json['sources']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eNumber': eNumber,
      'name': name,
      'aliases': aliases,
      'category': category.key,
      'riskLevel': riskLevel.key,
      'summary': summary,
      'healthEffects': healthEffects,
      'adiMgPerKgBw': adiMgPerKgBw,
      'adiNote': adiNote,
      'conditionTriggers': conditionTriggers,
      'bpomPermitted': bpomPermitted,
      'commonIn': commonIn,
      'sources': sources,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static List<String> _stringList(Object? value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  static DateTime _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime(2026);
    return DateTime(2026);
  }

  @override
  bool operator ==(Object other) => other is Additive && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Additive($id, ${riskLevel.key})';
}
