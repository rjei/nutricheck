import '../models/product.dart';

/// Kegagalan mengambil data produk dari sumber (jaringan putus, timeout,
/// server sibuk, respons tidak valid). Berbeda dari "produk tidak ditemukan",
/// yang dinyatakan dengan hasil `null` / daftar kosong.
class ProductSourceException implements Exception {
  const ProductSourceException(this.message, {this.cause});

  /// Pesan yang aman ditampilkan ke pengguna (Bahasa Indonesia).
  final String message;
  final Object? cause;

  @override
  String toString() => 'ProductSourceException: $message';
}

/// Kontrak sumber data produk.
///
/// Implementasi saat ini: `OpenFoodFactsDataSource`. Sumber lain (mis.
/// Firestore untuk produk yang dikurasi tim) dapat ditambahkan tanpa
/// mengubah repository maupun UI.
abstract class ProductDataSource {
  /// Mengambil detail lengkap produk berdasarkan barcode, atau `null` bila
  /// tidak ditemukan. Melempar [ProductSourceException] bila gagal.
  Future<Product?> fetchByBarcode(String barcode);

  /// Mencari produk yang beredar di Indonesia.
  ///
  /// [query] kosong berarti menjelajah seluruh katalog. [categoryTag]
  /// opsional, mis. `en:beverages`. Halaman dimulai dari 1.
  Future<ProductSearchResult> search(
    String query, {
    String? categoryTag,
    int page = 1,
    int pageSize = 20,
  });
}
