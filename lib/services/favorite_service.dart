import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/product.dart';

class FavoriteService extends ChangeNotifier {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  static FavoriteService get instance => _instance;

  FavoriteService._internal() {
    loadFavorites();
  }

  static const String _storageKey = 'nutricheck_favorites_v1';

  final List<Product> _favorites = [];
  bool _isLoaded = false;

  List<Product> get favorites => List.unmodifiable(_favorites);
  bool get isLoaded => _isLoaded;

  Future<void> loadFavorites() async {
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
    } catch (_) {
      _favorites.clear();
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  bool isFavorite(Product product) {
    return _favorites.any(
          (item) =>
      (item.barcode.isNotEmpty &&
          product.barcode.isNotEmpty &&
          item.barcode == product.barcode) ||
          (item.name.toLowerCase() == product.name.toLowerCase() &&
              (item.brand ?? '').toLowerCase() ==
                  (product.brand ?? '').toLowerCase()),
    );
  }

  Future<void> toggleFavorite(Product product) async {
    final existingIndex = _favorites.indexWhere(
          (item) =>
      (item.barcode.isNotEmpty &&
          product.barcode.isNotEmpty &&
          item.barcode == product.barcode) ||
          (item.name.toLowerCase() == product.name.toLowerCase() &&
              (item.brand ?? '').toLowerCase() ==
                  (product.brand ?? '').toLowerCase()),
    );

    if (existingIndex != -1) {
      _favorites.removeAt(existingIndex);
    } else {
      final toSave = Product(
        barcode: product.barcode.isNotEmpty ? product.barcode : '8990000000000',
        name: product.name,
        brand: product.brand,
        quantity: product.quantity,
        imageUrl: product.imageUrl,
        ingredientsText: product.ingredientsText,
        additiveCodes: product.additiveCodes,
        categoryTags: product.categoryTags,
        nutriscoreGrade: product.nutriscoreGrade,
        nutrition: product.nutrition,
        countryTags: product.countryTags,
        isComplete: product.isComplete,
        fetchedAt: DateTime.now(),
      );
      _favorites.insert(0, toSave);
    }

    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(_favorites.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, payload);
    } catch (_) {}
  }
}