/// Kondisi kesehatan / alergi yang dapat dipilih pengguna.
///
/// Basis data aditif mereferensikan [id] (bukan label) di field
/// `conditionTriggers`, sehingga label tampilan bisa diubah tanpa merusak data
/// lokal maupun Firestore.
class HealthCondition {
  const HealthCondition({required this.id, required this.label});

  final String id;
  final String label;

  static const sulfitePreservative = HealthCondition(
    id: 'sulfite_preservative_sensitivity',
    label: 'Intoleransi Sulfite / Pengawet',
  );
  static const peanutSoyAllergy = HealthCondition(
    id: 'peanut_soy_allergy',
    label: 'Alergi Kacang & Kedelai',
  );
  static const hypertension = HealthCondition(
    id: 'hypertension',
    label: 'Hipertensi / Sensitif Garam',
  );
  static const lactoseIntolerance = HealthCondition(
    id: 'lactose_intolerance',
    label: 'Intoleransi Laktosa',
  );
  static const diabetes = HealthCondition(
    id: 'diabetes',
    label: 'Diabetes / Batasi Gula',
  );
  static const asthma = HealthCondition(
    id: 'asthma',
    label: 'Riwayat Asma',
  );
  static const phenylketonuria = HealthCondition(
    id: 'phenylketonuria',
    label: 'Fenilketonuria (PKU)',
  );
  static const children = HealthCondition(
    id: 'children',
    label: 'Konsumsi Anak-anak',
  );

  static const List<HealthCondition> all = [
    sulfitePreservative,
    peanutSoyAllergy,
    hypertension,
    lactoseIntolerance,
    diabetes,
    asthma,
    phenylketonuria,
    children,
  ];

  static HealthCondition? byId(String id) {
    for (final condition in all) {
      if (condition.id == id) return condition;
    }
    return null;
  }

  static HealthCondition? byLabel(String label) {
    for (final condition in all) {
      if (condition.label == label) return condition;
    }
    return null;
  }

  /// Mengonversi label yang tersimpan di `UserModel.selectedConditions`
  /// menjadi daftar id. Label yang tidak dikenal diabaikan.
  static List<String> idsFromLabels(Iterable<String> labels) {
    return labels
        .map(byLabel)
        .whereType<HealthCondition>()
        .map((condition) => condition.id)
        .toList();
  }
}
