import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../data/models/additive.dart';
import '../data/models/nutrition.dart';
import '../data/models/product.dart';
import '../data/models/product_analysis.dart';
import '../data/repositories/additive_repository.dart';
import '../data/repositories/product_repository.dart';

/// Hasil ekstraksi dan pengenalan teks dari pemindaian OCR label makanan
class OcrScanResult {
  final String rawText;
  final String cleanedIngredients;
  final List<Additive> detectedAdditives;
  final Nutrition extractedNutrition;
  final Product product;
  final ProductAnalysis analysis;

  const OcrScanResult({
    required this.rawText,
    required this.cleanedIngredients,
    required this.detectedAdditives,
    required this.extractedNutrition,
    required this.product,
    required this.analysis,
  });
}

/// Service pemrosesan OCR untuk label kemasan makanan / informasi nilai gizi
class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  static OcrService get instance => _instance;

  OcrService._internal();

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Mengambil gambar dari Kamera atau Galeri
  Future<File?> pickImage(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (xFile == null) return null;
      return File(xFile.path);
    } catch (_) {
      return null;
    }
  }

  /// Memproses gambar kemasan untuk mengekstrak bahan & gizi dengan Google ML Kit OCR
  Future<OcrScanResult> processImage(
    File imageFile, {
    String? existingBarcode,
    String? fallbackName,
    Product? baseProduct,
  }) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final rawText = recognizedText.text;

    return analyzeOcrText(
      rawText,
      existingBarcode: existingBarcode,
      fallbackName: fallbackName,
      baseProduct: baseProduct,
    );
  }

  /// Menganalisis teks hasil OCR secara langsung
  Future<OcrScanResult> analyzeOcrText(
    String rawText, {
    String? existingBarcode,
    String? fallbackName,
    Product? baseProduct,
  }) async {
    final cleaned = _extractIngredientsSection(rawText);
    final additives =
        await AdditiveRepository.instance.findInIngredients(cleaned.isNotEmpty ? cleaned : rawText);

    final nutrition = _extractNutrition(rawText);

    final barcode = existingBarcode ??
        (baseProduct?.barcode.isNotEmpty == true
            ? baseProduct!.barcode
            : 'OCR-${DateTime.now().millisecondsSinceEpoch}');

    final productName = baseProduct?.name ??
        (fallbackName != null && fallbackName.trim().isNotEmpty
            ? fallbackName.trim()
            : _guessProductName(rawText));

    final combinedNutrition = baseProduct != null && !baseProduct.nutrition.isEmpty
        ? baseProduct.nutrition
        : nutrition;

    final product = Product(
      barcode: barcode,
      name: productName,
      brand: baseProduct?.brand,
      quantity: baseProduct?.quantity,
      imageUrl: baseProduct?.imageUrl,
      ingredientsText: cleaned.isNotEmpty ? cleaned : rawText,
      additiveCodes: additives.map((a) => a.id).toList(),
      categoryTags: baseProduct?.categoryTags ?? const [],
      nutriscoreGrade: baseProduct?.nutriscoreGrade,
      nutrition: combinedNutrition,
      countryTags: const [Product.indonesiaCountryTag],
      isComplete: true,
      fetchedAt: DateTime.now(),
    );

    // Lakukan analisis komprehensif terhadap aditif & profil alergi pengguna
    final analysis = await ProductRepository.instance.analyze(product);

    // Simpan ke cache lokal agar saat di-lookup barcode selanjutnya data sudah lengkap
    await ProductRepository.instance.cache.put(product);

    return OcrScanResult(
      rawText: rawText,
      cleanedIngredients: cleaned.isNotEmpty ? cleaned : rawText,
      detectedAdditives: additives,
      extractedNutrition: combinedNutrition,
      product: product,
      analysis: analysis,
    );
  }

  /// Memfilter area teks yang memuat kata kunci komposisi bahan
  String _extractIngredientsSection(String text) {
    if (text.trim().isEmpty) return '';

    final lower = text.toLowerCase();
    final markers = [
      'komposisi:',
      'komposisi :',
      'komposisi',
      'ingredients:',
      'ingredients :',
      'ingredients',
      'bahan-bahan:',
      'bahan-bahan',
    ];

    int startIndex = -1;
    for (final marker in markers) {
      final idx = lower.indexOf(marker);
      if (idx != -1) {
        startIndex = idx + marker.length;
        break;
      }
    }

    if (startIndex == -1) {
      return text.trim();
    }

    final endMarkers = [
      'informasi nilai gizi',
      'nutrition facts',
      'takaran saji',
      'diproduksi oleh',
      'didistribusikan oleh',
      'bpom ri',
      'kode produksi',
      'baik digunakan sebelum',
      'exp',
    ];

    int endIndex = text.length;
    for (final endMarker in endMarkers) {
      final idx = lower.indexOf(endMarker, startIndex);
      if (idx != -1 && idx < endIndex) {
        endIndex = idx;
      }
    }

    final section = text.substring(startIndex, endIndex).trim();
    return section.isNotEmpty ? section : text.trim();
  }

  /// Ekstraksi perkiraan nilai gizi dasar (Gula, Natrium, Kalori) dari label
  Nutrition _extractNutrition(String text) {
    double? energyKcal;
    double? sugarG;
    double? sodiumMg;

    final kcalRegex = RegExp(
        r'(?:energi|kalori|energy)[^\d]*(\d+[\.,]?\d*)\s*(?:kkal|kcal)',
        caseSensitive: false);
    final kcalMatch = kcalRegex.firstMatch(text);
    if (kcalMatch != null) {
      energyKcal = double.tryParse(kcalMatch.group(1)!.replaceAll(',', '.'));
    }

    final sugarRegex = RegExp(
        r'(?:gula|sugars?)[^\d]*(\d+[\.,]?\d*)\s*(?:g|gram)',
        caseSensitive: false);
    final sugarMatch = sugarRegex.firstMatch(text);
    if (sugarMatch != null) {
      sugarG = double.tryParse(sugarMatch.group(1)!.replaceAll(',', '.'));
    }

    final sodiumRegex = RegExp(
        r'(?:natrium|sodium)[^\d]*(\d+[\.,]?\d*)\s*(?:mg|miligram)',
        caseSensitive: false);
    final sodiumMatch = sodiumRegex.firstMatch(text);
    if (sodiumMatch != null) {
      sodiumMg = double.tryParse(sodiumMatch.group(1)!.replaceAll(',', '.'));
    }

    if (energyKcal == null && sugarG == null && sodiumMg == null) {
      return Nutrition.empty;
    }

    return Nutrition(
      energyKcal: energyKcal,
      sugarsG: sugarG,
      sodiumMg: sodiumMg,
    );
  }

  String _guessProductName(String text) {
    final lines =
        text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isNotEmpty) {
      for (final line in lines) {
        final low = line.toLowerCase();
        if (!low.contains('komposisi') &&
            !low.contains('informasi') &&
            !low.contains('bpom') &&
            !low.contains('halal') &&
            line.length > 2) {
          return line;
        }
      }
    }
    return 'Produk Hasil Scan OCR';
  }

  void dispose() {
    _textRecognizer.close();
  }
}
