import 'additive.dart';
import 'health_condition.dart';
import 'product.dart';
import 'risk_level.dart';

/// Peringatan untuk satu kondisi kesehatan pengguna: aditif apa saja pada
/// produk yang perlu diwaspadai.
class ConditionWarning {
  const ConditionWarning({required this.condition, required this.additives});

  final HealthCondition condition;
  final List<Additive> additives;
}

/// Hasil analisis aditif sebuah produk terhadap basis data aditif lokal.
class ProductAnalysis {
  const ProductAnalysis({
    required this.product,
    required this.additives,
    this.unknownAdditiveCodes = const [],
  });

  final Product product;

  /// Aditif yang dikenali basis data, diurutkan dari risiko tertinggi.
  final List<Additive> additives;

  /// Kode aditif pada produk yang belum ada di basis data lokal.
  final List<String> unknownAdditiveCodes;

  /// `false` bila produk tidak punya data komposisi sama sekali, sehingga
  /// tidak boleh dinyatakan "Aman".
  bool get hasIngredientData => product.hasIngredientData;

  /// Risiko tertinggi di antara aditif. `null` bila data komposisi tidak ada.
  RiskLevel? get overallRisk {
    if (!hasIngredientData) return null;
    if (additives.isEmpty) return RiskLevel.aman;
    return additives
        .map((a) => a.riskLevel)
        .reduce((a, b) => a.severity >= b.severity ? a : b);
  }

  int countOf(RiskLevel level) =>
      additives.where((a) => a.riskLevel == level).length;

  /// Mencocokkan aditif produk dengan kondisi kesehatan pengguna.
  /// Hanya kondisi yang terpicu yang dikembalikan.
  List<ConditionWarning> warningsFor(Iterable<String> conditionIds) {
    final warnings = <ConditionWarning>[];
    for (final id in conditionIds.toSet()) {
      final condition = HealthCondition.byId(id);
      if (condition == null) continue;
      final triggered =
          additives.where((a) => a.conditionTriggers.contains(id)).toList();
      if (triggered.isNotEmpty) {
        warnings.add(ConditionWarning(condition: condition, additives: triggered));
      }
    }
    return warnings;
  }
}
