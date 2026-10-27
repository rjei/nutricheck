import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/additive_dataset.dart';

/// Kontrak sumber data aditif.
///
/// Saat ini hanya ada [LocalAdditiveDataSource] (aset JSON). Saat fase cloud,
/// tambahkan `FirestoreAdditiveDataSource implements AdditiveDataSource`
/// tanpa perlu mengubah repository maupun UI.
abstract class AdditiveDataSource {
  /// Mengambil seluruh dataset aditif.
  Future<AdditiveDataset> fetchDataset();

  /// Versi dataset yang tersedia di sumber ini, tanpa mengunduh seluruh data.
  /// Dipakai untuk mengecek apakah perlu sinkronisasi.
  Future<int> fetchVersion();
}

/// Membaca basis data aditif statis dari `assets/data/additives.json`.
class LocalAdditiveDataSource implements AdditiveDataSource {
  LocalAdditiveDataSource({
    AssetBundle? bundle,
    this.assetPath = defaultAssetPath,
  }) : _bundle = bundle ?? rootBundle;

  static const String defaultAssetPath = 'assets/data/additives.json';

  final AssetBundle _bundle;
  final String assetPath;

  AdditiveDataset? _cache;

  @override
  Future<AdditiveDataset> fetchDataset() async {
    if (_cache != null) return _cache!;
    final raw = await _bundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _cache = AdditiveDataset.fromJson(json);
  }

  @override
  Future<int> fetchVersion() async => (await fetchDataset()).version;
}
