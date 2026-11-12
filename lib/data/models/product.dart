import '../helpers/indonesian_food_filter.dart';
import 'nutrition.dart';

/// Produk makanan/minuman kemasan.
///
/// Sumber data utama adalah Open Food Facts, tetapi model ini tidak
/// bergantung pada format API tersebut sehingga bisa dipakai ulang oleh
/// sumber lain (mis. Firestore / input manual).
class Product {
  const Product({
    required this.barcode,
    required this.name,
    required this.countryTags,
    required this.fetchedAt,
    this.brand,
    this.quantity,
    this.imageUrl,
    this.ingredientsText,
    this.additiveCodes = const [],
    this.categoryTags = const [],
    this.nutriscoreGrade,
    this.nutrition = Nutrition.empty,
    this.isComplete = false,
  });

  /// Tag negara Open Food Facts untuk Indonesia. Aplikasi hanya
  /// menampilkan produk yang memiliki tag ini.
  static const String indonesiaCountryTag = 'en:indonesia';

  /// Produk lokal sederhana (tanpa barcode), mis. untuk data riwayat contoh.
  factory Product.local({
    required String name,
    String? brand,
    String barcode = '8990000000000',
  }) {
    return Product(
      barcode: barcode,
      name: name,
      brand: brand,
      countryTags: const [indonesiaCountryTag],
      fetchedAt: DateTime.now(),
      isComplete: true,
    );
  }

  /// Barcode EAN/UPC. Kosong untuk produk lokal tanpa barcode.
  final String barcode;
  final String name;
  final String? brand;

  /// Ukuran kemasan, mis. "500 ml".
  final String? quantity;
  final String? imageUrl;

  /// Teks komposisi mentah dari label.
  final String? ingredientsText;

  /// Kode aditif ternormalisasi (`E211`, `E330i`) dari tag Open Food Facts.
  final List<String> additiveCodes;
  final List<String> categoryTags;

  /// Grade Nutri-Score `a`..`e` (huruf kecil), `null` jika tidak tersedia.
  final String? nutriscoreGrade;

  /// Gizi per 100 g / 100 ml.
  final Nutrition nutrition;

  /// Tag negara tempat produk dijual, mis. `en:indonesia`.
  final List<String> countryTags;

  /// `false` untuk hasil pencarian yang hanya berisi ringkasan (belum ada
  /// komposisi lengkap). Detail diambil lewat lookup barcode.
  final bool isComplete;

  final DateTime fetchedAt;

  bool get isSoldInIndonesia => IndonesianFoodFilter.isValidIndonesianFood(
        barcode: barcode,
        name: name,
        brand: brand,
        countryTags: countryTags,
        categoryTags: categoryTags,
        ingredientsText: ingredientsText,
      );

  bool get hasIngredientData =>
      (ingredientsText?.trim().isNotEmpty ?? false) || additiveCodes.isNotEmpty;

  bool hasCategory(String tag) => categoryTags.contains(tag);

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];

    return Product(
      barcode: json['barcode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String?,
      quantity: json['quantity'] as String?,
      imageUrl: json['imageUrl'] as String?,
      ingredientsText: json['ingredientsText'] as String?,
      additiveCodes: strings(json['additiveCodes']),
      categoryTags: strings(json['categoryTags']),
      nutriscoreGrade: json['nutriscoreGrade'] as String?,
      nutrition: json['nutrition'] is Map
          ? Nutrition.fromJson(Map<String, dynamic>.from(json['nutrition'] as Map))
          : Nutrition.empty,
      countryTags: strings(json['countryTags']),
      isComplete: json['isComplete'] as bool? ?? false,
      fetchedAt: DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'ingredientsText': ingredientsText,
        'additiveCodes': additiveCodes,
        'categoryTags': categoryTags,
        'nutriscoreGrade': nutriscoreGrade,
        'nutrition': nutrition.toJson(),
        'countryTags': countryTags,
        'isComplete': isComplete,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is Product && other.barcode == barcode && other.name == name;

  @override
  int get hashCode => Object.hash(barcode, name);

  @override
  String toString() => 'Product($barcode, $name)';
}

/// Satu halaman hasil pencarian produk.
class ProductSearchResult {
  const ProductSearchResult({
    required this.products,
    required this.page,
    required this.totalCount,
    required this.hasMore,
  });

  static const ProductSearchResult empty = ProductSearchResult(
    products: [],
    page: 1,
    totalCount: 0,
    hasMore: false,
  );

  final List<Product> products;
  final int page;

  /// Total produk yang cocok di server (seluruh halaman).
  final int totalCount;
  final bool hasMore;
}
