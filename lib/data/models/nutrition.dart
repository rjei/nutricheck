/// Informasi gizi produk per 100 g / 100 ml.
///
/// Semua field nullable karena data crowd-sourced (Open Food Facts) sering
/// tidak lengkap. `null` berarti "tidak diketahui", bukan nol.
class Nutrition {
  const Nutrition({
    this.energyKcal,
    this.sugarsG,
    this.fatG,
    this.saturatedFatG,
    this.carbohydratesG,
    this.proteinsG,
    this.fiberG,
    this.saltG,
    this.sodiumMg,
  });

  static const Nutrition empty = Nutrition();

  final double? energyKcal;
  final double? sugarsG;
  final double? fatG;
  final double? saturatedFatG;
  final double? carbohydratesG;
  final double? proteinsG;
  final double? fiberG;
  final double? saltG;
  final double? sodiumMg;

  bool get isEmpty =>
      energyKcal == null &&
      sugarsG == null &&
      fatG == null &&
      saturatedFatG == null &&
      carbohydratesG == null &&
      proteinsG == null &&
      fiberG == null &&
      saltG == null &&
      sodiumMg == null;

  /// Membaca objek `nutriments` dari Open Food Facts (nilai per 100 g).
  ///
  /// Catatan unit OFF: `sodium_100g` dan `salt_100g` dalam gram,
  /// `energy_100g` dalam kJ.
  factory Nutrition.fromOpenFoodFacts(Map<String, dynamic>? nutriments) {
    if (nutriments == null) return empty;

    double? read(String key) => _toDouble(nutriments[key]);

    var kcal = read('energy-kcal_100g');
    kcal ??= read('energy_100g') == null ? null : read('energy_100g')! / 4.184;

    final salt = read('salt_100g');
    final sodiumG = read('sodium_100g');
    // Natrium (mg) = garam (g) x 0,4 x 1000 bila hanya kadar garam yang ada.
    final sodiumMg =
        sodiumG != null ? sodiumG * 1000 : (salt != null ? salt * 400 : null);

    return Nutrition(
      energyKcal: kcal,
      sugarsG: read('sugars_100g'),
      fatG: read('fat_100g'),
      saturatedFatG: read('saturated-fat_100g'),
      carbohydratesG: read('carbohydrates_100g'),
      proteinsG: read('proteins_100g'),
      fiberG: read('fiber_100g'),
      saltG: salt ?? (sodiumG != null ? sodiumG * 2.5 : null),
      sodiumMg: sodiumMg,
    );
  }

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      energyKcal: _toDouble(json['energyKcal']),
      sugarsG: _toDouble(json['sugarsG']),
      fatG: _toDouble(json['fatG']),
      saturatedFatG: _toDouble(json['saturatedFatG']),
      carbohydratesG: _toDouble(json['carbohydratesG']),
      proteinsG: _toDouble(json['proteinsG']),
      fiberG: _toDouble(json['fiberG']),
      saltG: _toDouble(json['saltG']),
      sodiumMg: _toDouble(json['sodiumMg']),
    );
  }

  Map<String, dynamic> toJson() => {
        'energyKcal': energyKcal,
        'sugarsG': sugarsG,
        'fatG': fatG,
        'saturatedFatG': saturatedFatG,
        'carbohydratesG': carbohydratesG,
        'proteinsG': proteinsG,
        'fiberG': fiberG,
        'saltG': saltG,
        'sodiumMg': sodiumMg,
      };

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }
}
