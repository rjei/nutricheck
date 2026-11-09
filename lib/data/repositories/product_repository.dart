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
    this.searchCacheTtl = const Duration(minutes: 10),
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

  /// Cache lebih tua dari ini dianggap kedaluwarsa dan diambil ulang.
  final Duration maxCacheAge;

  /// Durasi cache hasil pencarian di memori agar perpindahan kategori berlangsung instan.
  final Duration searchCacheTtl;
  final Map<String, (ProductSearchResult, DateTime)> _searchCache = {};
  final Map<String, List<Product>> _catalogCache = {};

  /// Mengambil daftar produk katalog ber-Nutri-Score yang tersimpan di memori.
  List<Product>? getCachedCatalog(String? categoryTag) =>
      _catalogCache[categoryTag ?? ''];

  /// Menyimpan produk katalog ber-Nutri-Score ke memori agar tersedia instan.
  void setCachedCatalog(String? categoryTag, List<Product> products) {
    _catalogCache[categoryTag ?? ''] = List.unmodifiable(products);
  }

  /// Membersihkan input barcode. Hanya angka 8-14 digit yang valid.
  static String? normalizeBarcode(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^\d{8,14}$').hasMatch(cleaned) ? cleaned : null;
  }

  /// Mencari produk berdasarkan barcode.
  Future<Product?> getByBarcode(String raw, {bool forceRefresh = false}) async {
    final barcode = normalizeBarcode(raw);
    if (barcode == null) return null;

    final cached = await _cache.get(barcode);
    final cachedUsable =
        cached != null && cached.isComplete && cached.isSoldInIndonesia;
    final fresh =
        cachedUsable && _clock().difference(cached.fetchedAt) < maxCacheAge;
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
      if (cachedUsable) return cached;
      rethrow;
    }
  }

  List<String> _barcodeCandidates(String barcode) {
    return [
      barcode,
      if (barcode.length == 12) '0$barcode',
      if (barcode.length == 13 && barcode.startsWith('0')) barcode.substring(1),
    ];
  }

  /// Mencari produk Indonesia dengan in-memory cache berkecepatan tinggi.
  Future<ProductSearchResult> search(
    String query, {
    String? categoryTag,
    int page = 1,
    int pageSize = 40,
    bool forceRefresh = false,
  }) async {
    final cleanQuery = query.trim();
    final cacheKey = '$cleanQuery|${categoryTag ?? ""}|$page|$pageSize';

    if (!forceRefresh && _searchCache.containsKey(cacheKey)) {
      final (cachedResult, cachedTime) = _searchCache[cacheKey]!;
      if (_clock().difference(cachedTime) < searchCacheTtl) {
        return cachedResult;
      }
    }

    try {
      final result = await _dataSource.search(
        cleanQuery,
        categoryTag: categoryTag,
        page: page,
        pageSize: pageSize,
      );

      final seen = <String>{};
      final products = result.products
          .where((p) => p.isSoldInIndonesia && seen.add(p.barcode))
          .toList();

      final filteredResult = ProductSearchResult(
        products: products,
        page: result.page,
        totalCount: result.totalCount,
        hasMore: result.hasMore,
      );

      _searchCache[cacheKey] = (filteredResult, _clock());
      return filteredResult;
    } on ProductSourceException {
      if (_searchCache.containsKey(cacheKey)) {
        return _searchCache[cacheKey]!.$1;
      }
      rethrow;
    }
  }

  /// Melengkapi produk hasil pencarian dengan data detail lengkap.
  Future<Product> ensureComplete(Product product) async {
    if (product.isComplete || product.barcode.isEmpty) return product;
    return await getByBarcode(product.barcode) ?? product;
  }

  /// Menganalisis kandungan aditif produk terhadap basis data aditif lokal.
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

    for (final additive
        in await _additives.findInIngredients(product.ingredientsText ?? '')) {
      found.putIfAbsent(additive.id, () => additive);
    }

    final sorted = found.values.toList()
      ..sort((a, b) => b.riskLevel.severity.compareTo(a.riskLevel.severity));

    return ProductAnalysis(
      product: product,
      additives: sorted,
      unknownAdditiveCodes: unknown,
    );
  }

  Future<Additive?> _lookupCode(String rawCode) async {
    final code = AdditiveRepository.normalizeCode(rawCode);
    if (code == null) return null;
    return await _additives.getById(code);
  }
}
