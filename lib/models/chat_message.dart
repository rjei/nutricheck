import '../data/models/product_analysis.dart';

enum ChatRole { user, assistant }

/// Satu pesan dalam percakapan Chat AI NutriCheck.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.isError = false,
    this.recommendedProducts = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final ChatRole role;
  final String text;
  final DateTime timestamp;
  final bool isError;

  /// Produk alternatif lebih sehat yang direkomendasikan AI (dapat diklik ke detail).
  final List<ProductAnalysis> recommendedProducts;
}
