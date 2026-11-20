import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/product.dart';

/// Service pengelola daftar produk favorit pengguna berbasis [ChangeNotifier].
class FavoriteService extends ChangeNotifier {
  static const String _storageKey = 'nutricheck_favorite_products_v1';

  static final FavoriteService instance = FavoriteService._internal();
  factory FavoriteService() => instance;
  FavoriteService._internal();

  final List<Product> _favorites = [];
  bool _initialized = false;

  List<Product> get favorites => List.unmodifiable(_favorites);

  Future<void> initialize({bool forceReload = false}) async {
    if (_initialized && !forceReload) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      _favorites.clear();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map) {
            _favorites.add(
              Product.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }
      _initialized = true;
      notifyListeners();
    } catch (_) {
      _initialized = true;
    }
  }

  bool isFavorite(Product product) {
    return _favorites.any((item) => _isSameProduct(item, product));
  }

  bool isFavoriteBarcode(String barcode) {
    if (barcode.trim().isEmpty) return false;
    return _favorites.any((item) => item.barcode == barcode.trim());
  }

  Future<bool> toggleFavorite(Product product) async {
    await initialize();
    final existingIndex =
    _favorites.indexWhere((item) => _isSameProduct(item, product));

    late final bool added;
    if (existingIndex != -1) {
      _favorites.removeAt(existingIndex);
      added = false;
    } else {
      _favorites.insert(0, product);
      added = true;
    }

    await _saveToPrefs();
    notifyListeners();
    return added;
  }

  Future<void> removeFavorite(Product product) async {
    await initialize();
    _favorites.removeWhere((item) => _isSameProduct(item, product));
    await _saveToPrefs();
    notifyListeners();
  }

  bool _isSameProduct(Product a, Product b) {
    final cleanA = a.barcode.trim();
    final cleanB = b.barcode.trim();
    if (cleanA.isNotEmpty && cleanB.isNotEmpty && cleanA == cleanB) {
      return true;
    }
    return a.name.trim().toLowerCase() == b.name.trim().toLowerCase() &&
        (a.brand ?? '').trim().toLowerCase() ==
            (b.brand ?? '').trim().toLowerCase();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_favorites.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }
}