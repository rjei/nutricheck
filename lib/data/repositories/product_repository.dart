import '../datasources/open_food_facts_data_source.dart';
import '../datasources/product_cache.dart';
import '../datasources/product_data_source.dart';
import '../models/additive.dart';
import '../models/product.dart';
import '../models/product_analysis.dart';
import 'additive_repository.dart';

/// Titik akses tunggal data produk untuk seluruh aplikasi.
///
/// Menjamin dua hal terlepas dari sumber datanya:
/// 1. **Hanya produk yang beredar di Indonesia** yang pernah keluar dari sini.
/// 2. Strategi cache-first: produk yang pernah dibuka tetap tersedia offline.
class ProductRepository {
  ProductRepository({
    required ProductDataSource dataSource,
    ProductCache? cache,
    AdditiveRepository? additives,
    this.maxCacheAge = const Duration(days: 7),
    DateTime Function()? clock,
  })  : _dataSource = dataSource,
        _cache = cache ?? InMemoryProductCache(),
        _additives = additives ?? AdditiveRepository.instance,
        _clock = clock ?? DateTime.now;

  /// Instance default: Open Food Facts + cache persisten.
  static final ProductRepository instance = ProductRepository(
    dataSource: OpenFoodFactsDataSource(),
    cache: SharedPrefsProductCache(),
  );

  final ProductDataSource _dataSource;
  final ProductCache _cache;
  final AdditiveRepository _additives;
  final DateTime Function() _clock;

  /// Cache lebih tua dari ini dianggap kedaluwarsa dan diambil ulang
  /// (tetap dipakai sebagai cadangan bila jaringan gagal).
  final Duration maxCacheAge;

  /// Membersihkan input barcode. Hanya angka 8-14 digit (EAN-8, UPC-A,
  /// EAN-13, GTIN-14) yang valid; selain itu (mis. QR berisi URL) `null`.
  static String? normalizeBarcode(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^\d{8,14}$').hasMatch(cleaned) ? cleaned : null;
  }

  /// Mencari produk berdasarkan barcode.
  ///
  /// Mengembalikan `null` bila barcode tidak valid, produk tidak ada, atau
  /// produk tidak beredar di Indonesia. Melempar [ProductSourceException]
  /// bila gagal terhubung dan tidak ada cache sebagai cadangan.
  Future<Product?> getByBarcode(String raw, {bool forceRefresh = false}) async {
    final barcode = normalizeBarcode(raw);
    if (barcode == null) return null;

    final cached = await _cache.get(barcode);
    final cachedUsable = cached != null && cached.isComplete && cached.isSoldInIndonesia;
    final fresh = cachedUsable && _clock().difference(cached.fetchedAt) < maxCacheAge;
    if (fresh && !forceRefresh) return cached;

    try {
      for (final candidate in _barcodeCandidates(barcode)) {
        final product = await _dataSource.fetchByBarcode(candidate);
        if (product != null && product.isSoldInIndonesia) {
          await _cache.put(product);
          return product;
        }
      }
      return null;
    } on ProductSourceException {
      if (cachedUsable) return cached; // offline: pakai data lama
      rethrow;
    }
  }

  /// Open Food Facts menyimpan sebagian UPC-A (12 digit) sebagai EAN-13 dengan
  /// awalan 0 dan sebaliknya; coba bentuk alternatif bila bentuk asli tidak ada.
  List<String> _barcodeCandidates(String barcode) {
    return [
      barcode,
      if (barcode.length == 12) '0$barcode',
      if (barcode.length == 13 && barcode.startsWith('0')) barcode.substring(1),
    ];
  }

  /// Mencari produk Indonesia. [query] kosong menampilkan katalog.
  Future<ProductSearchResult> search(
    String query, {
    String? categoryTag,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _dataSource.search(
      query.trim(),
      categoryTag: categoryTag,
      page: page,
      pageSize: pageSize,
    );

    final seen = <String>{};
    final products = result.products
        .where((p) => p.isSoldInIndonesia && seen.add(p.barcode))
        .toList();

    return ProductSearchResult(
      products: products,
      page: result.page,
      totalCount: result.totalCount,
      hasMore: result.hasMore,
    );
  }

  /// Melengkapi produk hasil pencarian (ringkasan) dengan komposisi lengkap.
  /// Bila gagal diambil, mengembalikan produk apa adanya agar UI tetap tampil.
  Future<Product> ensureComplete(Product product) async {
    if (product.isComplete || product.barcode.isEmpty) return product;
    return await getByBarcode(product.barcode) ?? product;
  }

  /// Menganalisis aditif produk terhadap basis data aditif lokal, memakai
  /// tag aditif Open Food Facts dan deteksi teks pada komposisi.
  Future<ProductAnalysis> analyze(Product product) async {
    await _additives.load();

    final found = <String, Additive>{};
    final unknown = <String>[];

    for (final code in product.additiveCodes) {
      final additive = await _lookupCode(code);
      if (additive != null) {
        found[additive.id] = additive;
      } else {
        unknown.add(code);
      }
    }

    for (final additive in await _additives.findInIngredients(product.ingredientsText ?? '')) {
      found.putIfAbsent(additive.id, () => additive);
    }

    final sorted = found.values.toList()
      ..sort((a, b) {
        final bySeverity = b.riskLevel.severity.compareTo(a.riskLevel.severity);
        return bySeverity != 0 ? bySeverity : a.name.compareTo(b.name);
      });

    return ProductAnalysis(
      product: product,
      additives: sorted,
      unknownAdditiveCodes: unknown,
    );
  }

  /// Mencari aditif berdasarkan kode; untuk varian (`E330i`, `E450iii`) yang
  /// tidak ada persis, gunakan kode induknya (`E330`, `E450`).
  Future<Additive?> _lookupCode(String code) async {
    final exact = await _additives.getById(code);
    if (exact != null) return exact;

    final match = RegExp(r'^E(\d{3,4})[a-z]+$').firstMatch(code);
    return match == null ? null : _additives.getById('E${match.group(1)}');
  }
}
