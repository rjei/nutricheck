/// Penyaring khusus untuk memastikan hanya produk makanan/minuman
/// konsumsi manusia yang beredar di Indonesia yang ditampilkan oleh aplikasi NutriCheck.
///
/// Menyaring keluar:
/// 1. Makanan hewan peliharaan (kucing, anjing, ikan, burung, hamster, dll.)
/// 2. Produk non-makanan (pupuk, benih, bibit, racun serangga, sabun, kosmetik, dll.)
/// 3. Produk murni luar negeri yang tidak relevan dengan konsumen makanan Indonesia.
class IndonesianFoodFilter {
  IndonesianFoodFilter._();

  /// Tag negara Open Food Facts untuk Indonesia.
  static const String indonesiaCountryTag = 'en:indonesia';

  /// Awalan barcode GS1 Indonesia (semua produk lokal resmi Indonesia).
  static const String gs1IndonesiaPrefix = '899';

  /// Awalan barcode perusahaan Indofood (UPC 12/13 digit untuk Indomie, Chitato, dll).
  static const String indofoodUpcPrefix = '089686';
  static const String indofoodGtinPrefix = '0089686';

  /// Kategori Open Food Facts yang BUKAN makanan/minuman konsumsi manusia.
  static const Set<String> disallowedCategoryTags = {
    // Pet food & perlengkapan hewan
    'en:pet-food',
    'en:cats-food',
    'en:dogs-food',
    'en:fishes-food',
    'en:birds-food',
    'en:pet-supplies',
    'en:pets',
    'en:cat-treats',
    'en:dog-treats',
    // Non-food & kosmetik
    'en:non-food-products',
    'en:open-beauty-facts',
    'en:open-products-facts',
    'en:cosmetics',
    'en:beauty',
    'en:hygiene',
    'en:body-care',
    'en:skin-care',
    // Pembersih & rumah tangga
    'en:cleaning-products',
    'en:detergents',
    'en:household-supplies',
    // Pertanian & kebun
    'en:fertilizers',
    'en:seeds',
    'en:gardening',
    'en:pesticides',
    // Obat keras / medis non-pangan
    'en:medicines',
    'en:drugs',
    'en:medical',
  };

  /// Kata kunci makanan peliharaan / hewan.
  static final List<RegExp> _petFoodPatterns = [
    _boundaryPattern(r'cat\s+food'),
    _boundaryPattern(r'dog\s+food'),
    _boundaryPattern(r'pet\s+food'),
    _boundaryPattern(r'pet\s+snack'),
    _boundaryPattern(r'pet\s+treat'),
    _boundaryPattern(r'fish\s+food'),
    _boundaryPattern(r'turtle\s+food'),
    _boundaryPattern(r'bird\s+food'),
    _boundaryPattern(r'hamster\s+food'),
    _boundaryPattern(r'rabbit\s+food'),
    _boundaryPattern(r'cichlid'),
    _boundaryPattern(r'guppy'),
    _boundaryPattern(r'whiskas'),
    _boundaryPattern(r'royal\s+canin'),
    _boundaryPattern(r'pedigree'),
    _boundaryPattern(r'sheba'),
    _boundaryPattern(r'me-o'),
    _boundaryPattern(r'meo\b'),
    _boundaryPattern(r'felix'),
    _boundaryPattern(r'pro\s+plan'),
    _boundaryPattern(r'purina'),
    _boundaryPattern(r'temptation'),
    _boundaryPattern(r'temptations'),
    _boundaryPattern(r'super\s+cat'),
    _boundaryPattern(r'friskies'),
    _boundaryPattern(r'fancy\s+feast'),
    _boundaryPattern(r'dog\s+choize'),
    _boundaryPattern(r'doggy\s+man'),
    _boundaryPattern(r'alpo'),
    _boundaryPattern(r'kitten'),
    _boundaryPattern(r'puppy'),
    _boundaryPattern(r'hikari'),
    _boundaryPattern(r'takari'),
    _boundaryPattern(r'pelet\s+ikan'),
    _boundaryPattern(r'pellet\s+ikan'),
    _boundaryPattern(r'pakan\s+ikan'),
    _boundaryPattern(r'pakan\s+burung'),
    _boundaryPattern(r'pakan\s+ayam'),
    _boundaryPattern(r'pakan\s+ternak'),
    _boundaryPattern(r'pakan\s+hewan'),
    _boundaryPattern(r'makanan\s+kucing'),
    _boundaryPattern(r'makanan\s+anjing'),
    _boundaryPattern(r'makanan\s+ikan'),
    _boundaryPattern(r'makanan\s+burung'),
    _boundaryPattern(r'makanan\s+hamster'),
    _boundaryPattern(r'makanan\s+kelinci'),
    _boundaryPattern(r'cat\s+litter'),
    _boundaryPattern(r'pasir\s+kucing'),
    _boundaryPattern(r'flea\s+&\s+tick'),
    _boundaryPattern(r'flea\s+and\s+tick'),
    _boundaryPattern(r'housebreaking'),
  ];

  /// Kata kunci produk non-makanan manusia.
  static final List<RegExp> _nonFoodPatterns = [
    // Pertanian & Kebun
    _boundaryPattern(r'pupuk'),
    _boundaryPattern(r'benih'),
    _boundaryPattern(r'bibit'),
    _boundaryPattern(r'pestisida'),
    _boundaryPattern(r'herbisida'),
    _boundaryPattern(r'insektisida'),
    _boundaryPattern(r'anti\s+rayap'),
    _boundaryPattern(r'pembasmi\s+gulma'),
    _boundaryPattern(r'panah\s+merah'),
    _boundaryPattern(r'speedgro'),
    _boundaryPattern(r'calgary'),
    _boundaryPattern(r'rootone'),
    _boundaryPattern(r'fertilizer'),
    _boundaryPattern(r'hibrida\s+f1'),
    // Pembersih, Antiseptik & Racun
    _boundaryPattern(r'sabun'),
    _boundaryPattern(r'shampo'),
    _boundaryPattern(r'shampoo'),
    _boundaryPattern(r'deterjen'),
    _boundaryPattern(r'detergent'),
    _boundaryPattern(r'pembersih'),
    _boundaryPattern(r'pewangi'),
    _boundaryPattern(r'antiseptik'),
    _boundaryPattern(r'dettol'),
    _boundaryPattern(r'bayclin'),
    _boundaryPattern(r'molto'),
    _boundaryPattern(r'rinso'),
    _boundaryPattern(r'soklin'),
    _boundaryPattern(r'downy'),
    _boundaryPattern(r'sunlight'),
    _boundaryPattern(r'wipol'),
    _boundaryPattern(r'karbol'),
    _boundaryPattern(r'baygon'),
    _boundaryPattern(r'obat\s+nyamuk'),
    _boundaryPattern(r'k-othrine'),
    _boundaryPattern(r'cislin'),
    // Kosmetik & Skincare
    _boundaryPattern(r'masker\s+wajah'),
    _boundaryPattern(r'facial\s+mask'),
    _boundaryPattern(r'neem\s+mask'),
    _boundaryPattern(r'serum\s+wajah'),
    _boundaryPattern(r'body\s+lotion'),
    _boundaryPattern(r'hydrating\s+mist'),
    _boundaryPattern(r'sunscreen'),
    _boundaryPattern(r'hanasui'),
    _boundaryPattern(r'skincare'),
    _boundaryPattern(r'skin\s+care'),
    _boundaryPattern(r'deodorant'),
    _boundaryPattern(r'face\s+wash'),
    _boundaryPattern(r'facial\s+wash'),
    // Obat Medis Kimia Bebas Terbatas
    _boundaryPattern(r'diapet'),
    _boundaryPattern(r'panadol'),
    _boundaryPattern(r'paracetamol'),
    _boundaryPattern(r'bodrex'),
    _boundaryPattern(r'xentium'),
    // Lainnya
    _boundaryPattern(r'balloon\b'),
    _boundaryPattern(r'mainan\b'),
  ];

  /// Brand makanan/minuman yang lazim dipasarkan/ditemukan di Indonesia.
  static const Set<String> _knownIndonesianBrands = {
    'indomie',
    'sedap',
    'sedaap',
    'wings',
    'indofood',
    'mayora',
    'kapal api',
    'torabika',
    'bango',
    'abc',
    'garudafood',
    'dua kelinci',
    'silverqueen',
    'chitato',
    'chiki',
    'taro',
    'pop mie',
    'sarimi',
    'supermi',
    'indomilk',
    'ultra',
    'ultra milk',
    'ultra jaya',
    'cimory',
    'frisian flag',
    'khong guan',
    'tango',
    'nabati',
    'richeese',
    'sosro',
    'teh botol',
    'teh pucuk',
    'luwak',
    'good day',
    'marjan',
    'nutrisari',
    'tropicana slim',
    'heavenly blush',
    'aice',
    'campina',
    'walls',
    'sari roti',
    'biokul',
    'koepoe koepoe',
    'bamboe',
    'astro',
    'blue band',
    'pocari',
    'pocari sweat',
    'otsuka',
    'danone',
    'aqua',
    'vit',
    'cleo',
    'le minerale',
    'kratingdaeng',
    'extra joss',
    'hemaviton',
    'milo',
    'dancow',
    'bebelac',
    'bebelove',
    'sgm',
    'morinaga',
    'chil kid',
    'japota',
    'roma',
    'beng beng',
    'chunky bar',
  };

  /// Kosakata makanan/minuman Bahasa Indonesia untuk memastikan produk
  /// yang ber-barcode non-899 memang pangan konsumsi Indonesia.
  static final List<RegExp> _indonesianFoodVocabulary = [
    _boundaryPattern(r'kecap'),
    _boundaryPattern(r'sambal'),
    _boundaryPattern(r'kerupuk'),
    _boundaryPattern(r'keripik'),
    _boundaryPattern(r'biskuit'),
    _boundaryPattern(r'kopi'),
    _boundaryPattern(r'teh'),
    _boundaryPattern(r'susu'),
    _boundaryPattern(r'sirup'),
    _boundaryPattern(r'minuman'),
    _boundaryPattern(r'makanan'),
    _boundaryPattern(r'bumbu'),
    _boundaryPattern(r'perisa'),
    _boundaryPattern(r'pengawet'),
    _boundaryPattern(r'pewarna'),
    _boundaryPattern(r'kedelai'),
    _boundaryPattern(r'tepung'),
    _boundaryPattern(r'gula'),
    _boundaryPattern(r'garam'),
    _boundaryPattern(r'tempe'),
    _boundaryPattern(r'tahu'),
    _boundaryPattern(r'mie'),
    _boundaryPattern(r'mi\s+goreng'),
    _boundaryPattern(r'mi\s+kuah'),
    _boundaryPattern(r'santan'),
    _boundaryPattern(r'mentega'),
    _boundaryPattern(r'keju'),
    _boundaryPattern(r'cokelat'),
    _boundaryPattern(r'coklat'),
    _boundaryPattern(r'penyedap'),
    _boundaryPattern(r'kental\s+manis'),
    _boundaryPattern(r'rasa'),
    _boundaryPattern(r'ayam'),
    _boundaryPattern(r'sapi'),
  ];

  static RegExp _boundaryPattern(String pattern) =>
      RegExp('(?<=^|[^a-zA-Z0-9])$pattern(?=[^a-zA-Z0-9]|\$)', caseSensitive: false);

  /// Memeriksa apakah suatu produk adalah makanan/minuman konsumsi manusia yang
  /// sah dan beredar di Indonesia.
  static bool isValidIndonesianFood({
    required String barcode,
    required String name,
    String? brand,
    List<String> countryTags = const [],
    List<String> categoryTags = const [],
    String? ingredientsText,
  }) {
    // 1. Wajib memiliki tag negara Indonesia
    if (!countryTags.contains(indonesiaCountryTag)) return false;

    // 2. Validasi nama produk (tidak boleh kosong atau nama sampah)
    final cleanName = name.trim();
    if (cleanName.length < 3 || !RegExp(r'[a-zA-Z]').hasMatch(cleanName)) {
      return false;
    }

    // 3. Tolak kategori non-makanan atau pet-food
    for (final tag in categoryTags) {
      if (disallowedCategoryTags.contains(tag.toLowerCase())) {
        return false;
      }
    }

    // 4. Periksa teks komprehensif (nama, brand, komposisi, kategori)
    final fullText = '$cleanName ${brand ?? ''} ${ingredientsText ?? ''} ${categoryTags.join(' ')}'
        .toLowerCase();

    // 4a. Tolak makanan hewan peliharaan
    for (final pattern in _petFoodPatterns) {
      if (pattern.hasMatch(fullText)) return false;
    }

    // 4b. Tolak produk non-makanan
    for (final pattern in _nonFoodPatterns) {
      if (pattern.hasMatch(fullText)) return false;
    }

    // 5. Verifikasi Keaslian Produk Indonesia (Bukan Produk Luar Negeri)
    final cleanBarcode = barcode.replaceAll(RegExp(r'[\s-]'), '');

    // 5a. Barcode GS1 Indonesia (899...) pasti produk Indonesia
    if (cleanBarcode.startsWith(gs1IndonesiaPrefix)) return true;

    // 5b. Barcode Indofood global (089686... / 0089686...)
    if (cleanBarcode.startsWith(indofoodUpcPrefix) ||
        cleanBarcode.startsWith(indofoodGtinPrefix)) {
      return true;
    }

    // 5c. Periksa apakah brand terdaftar sebagai brand pangan Indonesia
    final cleanBrand = (brand ?? '').trim().toLowerCase();
    for (final indoBrand in _knownIndonesianBrands) {
      if (cleanBrand.contains(indoBrand) || cleanName.toLowerCase().contains(indoBrand)) {
        return true;
      }
    }

    // 5d. Periksa kosakata pangan khas Indonesia di nama atau komposisi
    for (final vocab in _indonesianFoodVocabulary) {
      if (vocab.hasMatch(cleanName) ||
          (ingredientsText != null && vocab.hasMatch(ingredientsText))) {
        return true;
      }
    }

    // Jika barcode BUKAN 899, dan tidak punya kaitan brand atau bahasa Indonesia,
    // maka produk ini adalah produk luar negeri yang salah ditandai di Open Food Facts.
    return false;
  }
}
