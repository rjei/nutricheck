import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

/// Penyimpanan lokal produk yang pernah dibuka/dipindai, agar tetap bisa
/// dilihat saat offline dan mengurangi permintaan ke API.
abstract class ProductCache {
  Future<Product?> get(String barcode);
  Future<void> put(Product product);
}

class InMemoryProductCache implements ProductCache {
  final Map<String, Product> _entries = {};

  @override
  Future<Product?> get(String barcode) async => _entries[barcode];

  @override
  Future<void> put(Product product) async => _entries[product.barcode] = product;
}

/// Cache persisten berbasis `shared_preferences` (JSON). Menyimpan maksimal
/// [maxEntries] produk; yang paling lama diambil akan dibuang lebih dulu.
class SharedPrefsProductCache implements ProductCache {
  SharedPrefsProductCache({this.maxEntries = 200});

  static const String storageKey = 'product_cache_v1';

  final int maxEntries;
  Map<String, Product>? _entries;

  Future<Map<String, Product>> _load() async {
    if (_entries != null) return _entries!;
    final entries = <String, Product>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          entries[entry.key] = Product.fromJson(Map<String, dynamic>.from(entry.value as Map));
        }
      }
    } catch (_) {
      // Cache rusak/tidak tersedia: mulai dari kosong, jangan ganggu aplikasi.
      entries.clear();
    }
    return _entries = entries;
  }

  @override
  Future<Product?> get(String barcode) async => (await _load())[barcode];

  @override
  Future<void> put(Product product) async {
    final entries = await _load();
    entries[product.barcode] = product;

    if (entries.length > maxEntries) {
      final sorted = entries.values.toList()
        ..sort((a, b) => a.fetchedAt.compareTo(b.fetchedAt));
      for (final old in sorted.take(entries.length - maxEntries)) {
        entries.remove(old.barcode);
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        storageKey,
        jsonEncode(entries.map((k, v) => MapEntry(k, v.toJson()))),
      );
    } catch (_) {
      // Gagal menyimpan tidak boleh menggagalkan lookup produk.
    }
  }
}
