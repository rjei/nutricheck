import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/nutrition.dart';
import '../models/product.dart';
import 'product_data_source.dart';

/// Mengambil data produk dari [Open Food Facts](https://world.openfoodfacts.org).
///
/// - Lookup barcode: `world.openfoodfacts.org/api/v2/product/{barcode}`
/// - Pencarian teks: `search.openfoodfacts.org` (Search-a-licious). Endpoint
///   pencarian klasik (`/api/v2/search`) menolak akses anonim (HTTP 503).
///
/// **Hanya produk Indonesia.** Pencarian difilter di server dengan
/// `countries_tags:"en:indonesia"` dan hasilnya diperiksa ulang di sisi klien;
/// lookup barcode menolak produk tanpa tag negara Indonesia.
///
/// Data Open Food Facts berlisensi ODbL; tampilkan atribusi di UI.
class OpenFoodFactsDataSource implements ProductDataSource {
  OpenFoodFactsDataSource({
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
    this.userAgent = 'NutriCheck/1.0.0 (Flutter; student project)',
  }) : _client = client ?? http.Client();

  static const String productHost = 'world.openfoodfacts.org';
  static const String searchHost = 'search.openfoodfacts.org';

  static const List<String> _productFields = [
    'code',
    'product_name',
    'product_name_id',
    'generic_name',
    'brands',
    'quantity',
    'countries_tags',
    'categories_tags',
    'ingredients_text',
    'ingredients_text_id',
    'additives_tags',
    'nutriments',
    'nutriscore_grade',
    'image_front_url',
    'image_front_small_url',
  ];

  static const List<String> _searchFields = [
    'code',
    'product_name',
    'brands',
    'quantity',
    'countries_tags',
    'categories_tags',
    'nutriments',
    'nutriscore_grade',
    'image_front_small_url',
  ];

  final http.Client _client;
  final Duration timeout;
  final String userAgent;

  @override
  Future<Product?> fetchByBarcode(String barcode) async {
    final uri = Uri.https(productHost, '/api/v2/product/$barcode', {
      'fields': _productFields.join(','),
    });

    final response = await _get(uri, notFoundIsNull: true);
    if (response == null) return null;

    final json = _decodeObject(response.body);
    if (json['status'] == 0 || json['product'] is! Map) return null;

    final product = parseProduct(
      Map<String, dynamic>.from(json['product'] as Map),
      complete: true,
      fallbackBarcode: barcode,
    );
    if (product == null) return null;
    return product.isSoldInIndonesia ? product : null;
  }

  @override
  Future<ProductSearchResult> search(
    String query, {
    String? categoryTag,
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.https(searchHost, '/search', {
      'q': buildSearchQuery(query, categoryTag: categoryTag),
      'page': '$page',
      'page_size': '$pageSize',
      'fields': _searchFields.join(','),
    });

    final response = await _get(uri);
    final json = _decodeObject(response!.body);

    final hits = json['hits'] is List ? json['hits'] as List : const [];
    final products = <Product>[];
    for (final hit in hits) {
      if (hit is! Map) continue;
      final product = parseProduct(Map<String, dynamic>.from(hit), complete: false);
      // Pemeriksaan ulang di klien: server sudah memfilter, tetapi invarian
      // "hanya produk Indonesia" tidak boleh bergantung pada satu lapis saja.
      if (product != null && product.name.isNotEmpty && product.isSoldInIndonesia) {
        products.add(product);
      }
    }

    final total = (json['count'] as num?)?.toInt() ?? products.length;
    final pageCount = (json['page_count'] as num?)?.toInt() ?? page;
    return ProductSearchResult(
      products: products,
      page: page,
      totalCount: total,
      hasMore: page < pageCount,
    );
  }

  /// Membangun query Lucene untuk Search-a-licious.
  ///
  /// Format yang terbukti bekerja untuk multi-kata:
  /// `countries_tags:"en:indonesia" AND kata1 AND kata2`.
  /// (Teks bebas multi-kata tanpa `AND`, dengan tanda kurung, atau dalam
  /// tanda kutip menghasilkan 0 hasil bila digabung dengan filter negara.)
  static String buildSearchQuery(String text, {String? categoryTag}) {
    final buffer = StringBuffer('countries_tags:"${Product.indonesiaCountryTag}"');

    final category = categoryTag?.trim().toLowerCase();
    if (category != null && RegExp(r'^[a-z]{2}:[a-z0-9-]+$').hasMatch(category)) {
      buffer.write(' AND categories_tags:"$category"');
    }

    // Buang karakter spesial Lucene agar input pengguna tidak merusak query
    // atau menyisipkan filter lain.
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[+\-&|!(){}\[\]^"~*?:\\/]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(6);

    for (final word in words) {
      buffer.write(' AND $word');
    }
    return buffer.toString();
  }

  /// Mengubah objek produk Open Food Facts (versi API maupun hasil
  /// pencarian) menjadi [Product]. Mengembalikan `null` bila tanpa barcode.
  static Product? parseProduct(
    Map<String, dynamic> json, {
    required bool complete,
    String? fallbackBarcode,
  }) {
    final code = (json['code']?.toString() ?? fallbackBarcode ?? '').trim();
    if (code.isEmpty) return null;

    String? text(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    List<String> stringList(Object? v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];

    final brand = _firstBrand(json['brands']);
    var name = text(json['product_name_id']) ??
        text(json['product_name']) ??
        text(json['generic_name']) ??
        '';
    if (name.isEmpty && complete) name = brand ?? 'Produk tanpa nama';

    final ingredients = text(json['ingredients_text_id']) ??
        text(json['ingredients_text']);

    final grade = text(json['nutriscore_grade'])?.toLowerCase();

    return Product(
      barcode: code,
      name: name,
      brand: brand,
      quantity: text(json['quantity']),
      imageUrl: text(json['image_front_url']) ?? text(json['image_front_small_url']),
      // OFF menandai alergen dengan _garis bawah_; tidak relevan untuk tampilan.
      ingredientsText: ingredients?.replaceAll('_', ''),
      additiveCodes: parseAdditiveTags(stringList(json['additives_tags'])),
      categoryTags: stringList(json['categories_tags']),
      nutriscoreGrade: (grade != null && RegExp(r'^[a-e]$').hasMatch(grade)) ? grade : null,
      nutrition: Nutrition.fromOpenFoodFacts(
        json['nutriments'] is Map
            ? Map<String, dynamic>.from(json['nutriments'] as Map)
            : null,
      ),
      countryTags: stringList(json['countries_tags']),
      isComplete: complete,
      fetchedAt: DateTime.now(),
    );
  }

  /// `['en:e211', 'en:e330i']` -> `['E211', 'E330i']`. Tag non-kode diabaikan.
  static List<String> parseAdditiveTags(Iterable<String> tags) {
    final codes = <String>[];
    final pattern = RegExp(r'^(?:[a-z]{2}:)?e(\d{3,4})([a-z]*)$', caseSensitive: false);
    for (final tag in tags) {
      final match = pattern.firstMatch(tag.trim());
      if (match == null) continue;
      final code = 'E${match.group(1)}${match.group(2)!.toLowerCase()}';
      if (!codes.contains(code)) codes.add(code);
    }
    return codes;
  }

  static String? _firstBrand(Object? brands) {
    String? first;
    if (brands is List && brands.isNotEmpty) {
      first = brands.first.toString();
    } else if (brands is String) {
      first = brands.split(',').first;
    }
    first = first?.trim();
    return (first == null || first.isEmpty) ? null : first;
  }

  Future<http.Response?> _get(Uri uri, {bool notFoundIsNull = false}) async {
    final http.Response response;
    try {
      response = await _client.get(uri, headers: {
        'User-Agent': userAgent,
        'Accept': 'application/json',
      }).timeout(timeout);
    } on TimeoutException catch (e) {
      throw ProductSourceException(
        'Koneksi ke Open Food Facts terlalu lama. Coba lagi.',
        cause: e,
      );
    } catch (e) {
      throw ProductSourceException(
        'Tidak dapat terhubung ke internet. Periksa koneksi Anda.',
        cause: e,
      );
    }

    if (response.statusCode == 404 && notFoundIsNull) return null;
    if (response.statusCode == 429 || response.statusCode >= 500) {
      throw ProductSourceException(
        'Server Open Food Facts sedang sibuk. Coba beberapa saat lagi.',
        cause: 'HTTP ${response.statusCode}',
      );
    }
    if (response.statusCode != 200) {
      throw ProductSourceException(
        'Permintaan data produk gagal (kode ${response.statusCode}).',
        cause: 'HTTP ${response.statusCode}',
      );
    }
    return response;
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException catch (e) {
      throw ProductSourceException('Respons server tidak valid.', cause: e);
    }
    throw const ProductSourceException('Respons server tidak valid.');
  }

  void close() => _client.close();
}
