/// Tingkat risiko zat aditif, ditampilkan sebagai indikator warna
/// (hijau / kuning / merah) sesuai SRS 6.1.
///
/// Nilai [key] dipakai sebagai representasi string di JSON lokal maupun
/// dokumen Firestore, jadi jangan diubah tanpa migrasi data.
enum RiskLevel {
  aman('aman', 'Aman'),
  waspada('waspada', 'Waspada'),
  bahaya('bahaya', 'Bahaya');

  const RiskLevel(this.key, this.label);

  final String key;
  final String label;

  /// Semakin besar semakin berisiko. Berguna untuk mengurutkan / menentukan
  /// risiko tertinggi dalam satu produk.
  int get severity => index;

  static RiskLevel fromKey(String? value) {
    return RiskLevel.values.firstWhere(
      (level) => level.key == value?.trim().toLowerCase(),
      orElse: () => RiskLevel.waspada,
    );
  }
}
