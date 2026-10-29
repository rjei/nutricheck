import 'dart:convert';
import 'dart:io';

import 'package:nutricheck/data/datasources/additive_data_source.dart';
import 'package:nutricheck/data/datasources/product_data_source.dart';
import 'package:nutricheck/data/models/additive_dataset.dart';
import 'package:nutricheck/data/models/nutrition.dart';
import 'package:nutricheck/data/models/product.dart';

/// Data source aditif yang membaca `assets/data/additives.json` dari disk.
class FileAdditiveDataSource implements AdditiveDataSource {
  @override
  Future<AdditiveDataset> fetchDataset() async {
    final raw = File('assets/data/additives.json').readAsStringSync();
    return AdditiveDataset.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<int> fetchVersion() async => (await fetchDataset()).version;
}

/// Membuat [Product] untuk test dengan nilai default yang masuk akal.
Product makeProduct({
  String barcode = '8990000000001',
  String name = 'Produk Uji',
  String? brand,
  List<String> countryTags = const [Product.indonesiaCountryTag],
  List<String> additiveCodes = const [],
  String? ingredientsText,
  bool isComplete = true,
  DateTime? fetchedAt,
}) {
  return Product(
    barcode: barcode,
    name: name,
    brand: brand,
    countryTags: countryTags,
    additiveCodes: additiveCodes,
    ingredientsText: ingredientsText,
    nutrition: Nutrition.empty,
    isComplete: isComplete,
    fetchedAt: fetchedAt ?? DateTime(2026, 10, 29),
  );
}

/// Data source palsu: menghitung pemanggilan dan bisa dipaksa gagal.
class FakeProductDataSource implements ProductDataSource {
  FakeProductDataSource({
    this.byBarcode = const {},
    this.searchResults = const [],
  });

  Map<String, Product> byBarcode;
  List<Product> searchResults;
  bool failWithNetworkError = false;

  final List<String> barcodeCalls = [];
  final List<String> searchQueries = [];

  @override
  Future<Product?> fetchByBarcode(String barcode) async {
    barcodeCalls.add(barcode);
    if (failWithNetworkError) {
      throw const ProductSourceException('Tidak dapat terhubung ke internet.');
    }
    return byBarcode[barcode];
  }

  @override
  Future<ProductSearchResult> search(
    String query, {
    String? categoryTag,
    int page = 1,
    int pageSize = 20,
  }) async {
    searchQueries.add(query);
    if (failWithNetworkError) {
      throw const ProductSourceException('Tidak dapat terhubung ke internet.');
    }
    return ProductSearchResult(
      products: searchResults,
      page: page,
      totalCount: searchResults.length,
      hasMore: false,
    );
  }
}
