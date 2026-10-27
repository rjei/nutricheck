/// Kategori fungsi zat aditif (Bahan Tambahan Pangan / BTP) mengikuti
/// pengelompokan umum BPOM.
///
/// [key] adalah nilai yang disimpan di JSON / Firestore.
enum AdditiveCategory {
  pengawet('pengawet', 'Pengawet'),
  pewarna('pewarna', 'Pewarna'),
  pemanis('pemanis', 'Pemanis Buatan'),
  penguatRasa('penguat_rasa', 'Penguat Rasa'),
  antioksidan('antioksidan', 'Antioksidan'),
  pengemulsi('pengemulsi', 'Pengemulsi'),
  pengental('pengental', 'Pengental & Penstabil'),
  pengaturKeasaman('pengatur_keasaman', 'Pengatur Keasaman'),
  pengembang('pengembang', 'Pengembang'),
  dilarang('dilarang', 'Bahan Dilarang');

  const AdditiveCategory(this.key, this.label);

  final String key;
  final String label;

  static AdditiveCategory fromKey(String? value) {
    return AdditiveCategory.values.firstWhere(
      (category) => category.key == value?.trim().toLowerCase(),
      orElse: () => throw FormatException('Kategori aditif tidak dikenal: $value'),
    );
  }
}
