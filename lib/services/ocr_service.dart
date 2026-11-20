import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../data/models/additive.dart';
import '../data/models/nutrition.dart';
import '../data/models/product.dart';
import '../data/models/product_analysis.dart';
import '../data/repositories/additive_repository.dart';
import '../data/repositories/product_repository.dart';

/// Exception khusus proses OCR (misal teks tidak terbaca pada gambar).
class OcrException implements Exception {
  final String message;
  const OcrException(this.message);

  @override
  String toString() => message;
}

/// Hasil ekstraksi dan pengenalan teks dari pemindaian OCR label makanan.
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

/// Service pemrosesan OCR untuk label kemasan makanan / informasi nilai gizi.
class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  static OcrService get instance => _instance;

  OcrService._internal();

  final ImagePicker _picker = ImagePicker();
  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer =>
      _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  // Pre-compiled regex untuk ekstraksi bagian komposisi
  static final RegExp _ingredientsStartRegex = RegExp(
    r'\b(?:komposisi|ingredients|bahan-bahan|bahan)\s*:?',
    caseSensitive: false,
  );
  static final RegExp _ingredientsEndRegex = RegExp(
    r'\b(?:informasi nilai gizi|nutrition facts|takaran saji|diproduksi oleh|didistribusikan oleh|bpom ri|kode produksi|baik digunakan sebelum|exp\.?\s*date)\b',
    caseSensitive: false,
  );

  // Pre-compiled regex untuk normalisasi kode E/INS yang sering salah baca OCR
  static final RegExp _eCodeTypoRegex = RegExp(
    r'\b(E|INS)\s*[-:]?\s*([0-9OlI]{3,4}[a-zA-Z]?)\b',
    caseSensitive: false,
  );
  static final RegExp _multiWhitespaceRegex = RegExp(r'\s+');
  static final RegExp _numericOrUnitOnlyRegex = RegExp(r'^[\d\s.,%/gmkcal]+$', caseSensitive: false);

  // Pre-compiled regex untuk ekstraksi tabel nilai gizi
  static final RegExp _kcalRegex = RegExp(
    r'(?:energi(?:\s+total)?|kalori|energy)[^\d\n]{0,20}(\d+(?:[.,]\d+)?)\s*(?:kkal|kcal)',
    caseSensitive: false,
  );
  static final RegExp _kjRegex = RegExp(
    r'(?:energi(?:\s+total)?|energy)[^\d\n]{0,20}(\d+(?:[.,]\d+)?)\s*kj\b',
    caseSensitive: false,
  );
  static final RegExp _sugarRegex = RegExp(
    r'(?:gula(?:\s+total)?|sugars?)[^\d\n]{0,20}(\d+(?:[.,]\d+)?)\s*(?:g|gram)\b',
    caseSensitive: false,
  );
  static final RegExp _saturatedFatRegex = RegExp(
    r'(?:lemak\s+jenuh|saturated\s+fat)[^\d\n]{0,20}(\d+(?:[.,]\d+)?)\s*(?:g|gram)\b',
    caseSensitive: false,
  );
  static final RegExp _fatRegex = RegExp(
    r'(?:lemak(?:\s+total)?|total\s+fat)(?!\s+jenuh)[^\d\n]{0,20}(\d+(?:[.,]\d+)?)\s*(?:g|gram)\b',
    caseSensitive: false,
  );
  static final RegExp _carbRegex = RegExp(
    r'(?:karbohidrat(?:\s+total)?|carbohydrates?)[^\d\n]{0,20}(\d+(?:[.,]\d+)?)\s*(?:g|gram)\b',
    caseSensitive: false,
  );
  static final RegExp _proteinRegex = RegExp(
    r'(?:protein)[^\d\n]{0,20}(\d+(?:[.,]\d+)?)\s*(?:g|gram)\b',
    caseSensitive: false,
  );
  static final RegExp _fiberRegex = RegExp(
    r'(?:serat(?:\s+pangan)?|dietary\s+fiber|fiber)[^\d\n]{0,20}(\d+(?:[.,]\d+)?)\s*(?:g|gram)\b',
    caseSensitive: false,
  );
  static final RegExp _sodiumMgRegex = RegExp(
    r'(?:natrium|sodium)[^\d\n]{0,20}(\d+(?:[.,]\d+)?)\s*(?:mg|miligram)\b',
    caseSensitive: false,
  );
  static final RegExp _sodiumGRegex = RegExp(
    r'(?:natrium|sodium)[^\d\n]{0,20}(\d+(?:[.,]\d+)?)\s*(?:g|gram)\b',
    caseSensitive: false,
  );
  static final RegExp _saltGRegex = RegExp(
    r'(?:garam|salt)[^\d\n]{0,20}(\d+(?:[.,]\d+)?)\s*(?:g|gram)\b',
    caseSensitive: false,
  );

  /// Mengambil gambar dari Kamera atau Galeri.
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

  /// Memproses gambar kemasan untuk mengekstrak bahan & gizi dengan Google ML Kit OCR.
  Future<OcrScanResult> processImage(
    File imageFile, {
    String? existingBarcode,
    String? fallbackName,
    Product? baseProduct,
    ProductRepository? productRepository,
    AdditiveRepository? additiveRepository,
  }) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _recognizer.processImage(inputImage);
    final rawText = recognizedText.text;

    return analyzeOcrText(
      rawText,
      existingBarcode: existingBarcode,
      fallbackName: fallbackName,
      baseProduct: baseProduct,
      productRepository: productRepository,
      additiveRepository: additiveRepository,
    );
  }

  /// Menganalisis teks hasil OCR secara langsung.
  /// Melempar [OcrException] jika teks kosong sehingga cache tidak tercemar.
  Future<OcrScanResult> analyzeOcrText(
    String rawText, {
    String? existingBarcode,
    String? fallbackName,
    Product? baseProduct,
    ProductRepository? productRepository,
    AdditiveRepository? additiveRepository,
  }) async {
    final trimmedRaw = rawText.trim();
    if (trimmedRaw.isEmpty) {
      throw const OcrException(
        'Tidak ada teks yang terbaca. Pastikan label komposisi terlihat jelas dan tidak buram.',
      );
    }

    final prodRepo = productRepository ?? ProductRepository.instance;
    final addRepo = additiveRepository ?? AdditiveRepository.instance;

    final extractedSection = extractIngredientsSection(trimmedRaw);
    final normalizedIngredients = normalizeOcrText(
      extractedSection.isNotEmpty ? extractedSection : trimmedRaw,
    );

    final additives = await addRepo.findInIngredients(normalizedIngredients);
    final nutrition = extractNutrition(trimmedRaw);

    final barcode = existingBarcode ??
        (baseProduct?.barcode.isNotEmpty == true
            ? baseProduct!.barcode
            : 'OCR-${DateTime.now().millisecondsSinceEpoch}');

    final productName = baseProduct?.name ??
        (fallbackName != null && fallbackName.trim().isNotEmpty
            ? fallbackName.trim()
            : _guessProductName(trimmedRaw));

    final combinedNutrition =
        baseProduct != null && !baseProduct.nutrition.isEmpty
            ? baseProduct.nutrition
            : nutrition;

    final product = Product(
      barcode: barcode,
      name: productName,
      brand: baseProduct?.brand,
      quantity: baseProduct?.quantity,
      imageUrl: baseProduct?.imageUrl,
      ingredientsText: normalizedIngredients,
      additiveCodes: additives.map((a) => a.id).toList(),
      categoryTags: baseProduct?.categoryTags ?? const [],
      nutriscoreGrade: baseProduct?.nutriscoreGrade,
      nutrition: combinedNutrition,
      countryTags: const [Product.indonesiaCountryTag],
      isComplete: true,
      fetchedAt: DateTime.now(),
    );

    // Lakukan analisis komprehensif terhadap aditif & profil alergi pengguna
    final analysis = await prodRepo.analyze(product);

    // Simpan ke cache lokal agar saat di-lookup barcode selanjutnya data sudah lengkap
    await prodRepo.cache.put(product);

    return OcrScanResult(
      rawText: rawText,
      cleanedIngredients: normalizedIngredients,
      detectedAdditives: additives,
      extractedNutrition: combinedNutrition,
      product: product,
      analysis: analysis,
    );
  }

  /// Menormalkan teks hasil OCR: menyambung kata yang terpotong baris baru,
  /// merapikan spasi, dan memperbaiki salah baca angka pada kode E/INS.
  String normalizeOcrText(String text) {
    if (text.trim().isEmpty) return '';

    // Gabungkan kata yang terpotong tanda hubung di akhir baris (mis. "Ben-\nzoat")
    var normalized = text.replaceAll(RegExp(r'-\s*\n\s*'), '');

    // Ganti newline & spasi berlebih menjadi satu spasi agar frasa multi-kata cocok
    normalized = normalized.replaceAll(_multiWhitespaceRegex, ' ').trim();

    // Perbaiki salah baca OCR pada kode E/INS (O->0, l/I->1)
    normalized = normalized.replaceAllMapped(_eCodeTypoRegex, (match) {
      final prefix = match.group(1)!.toUpperCase();
      final rawDigits = match.group(2)!;
      final fixedDigits = rawDigits
          .replaceAll('O', '0')
          .replaceAll('o', '0')
          .replaceAll('l', '1')
          .replaceAll('I', '1');
      return prefix == 'INS' ? 'INS $fixedDigits' : 'E$fixedDigits';
    });

    return normalized;
  }

  /// Memfilter area teks yang memuat kata kunci komposisi bahan.
  String extractIngredientsSection(String text) {
    if (text.trim().isEmpty) return '';

    final startMatch = _ingredientsStartRegex.firstMatch(text);
    if (startMatch == null) {
      return text.trim();
    }

    final startIndex = startMatch.end;
    final tail = text.substring(startIndex);
    final endMatch = _ingredientsEndRegex.firstMatch(tail);

    final section =
        (endMatch != null ? tail.substring(0, endMatch.start) : tail).trim();
    return section.isNotEmpty ? section : text.trim();
  }

  /// Ekstraksi perkiraan nilai gizi dari label (Energi, Gula, Lemak, Karbo, Protein, Serat, Garam/Natrium).
  Nutrition extractNutrition(String text) {
    final kj = _matchNumber(_kjRegex, text);
    final energyKcal =
        _matchNumber(_kcalRegex, text) ?? (kj != null ? kj / 4.184 : null);
    final sugarsG = _matchNumber(_sugarRegex, text);
    final saturatedFatG = _matchNumber(_saturatedFatRegex, text);
    final fatG = _matchNumber(_fatRegex, text);
    final carbohydratesG = _matchNumber(_carbRegex, text);
    final proteinsG = _matchNumber(_proteinRegex, text);
    final fiberG = _matchNumber(_fiberRegex, text);

    final saltGDirect = _matchNumber(_saltGRegex, text);
    final sodiumG = _matchNumber(_sodiumGRegex, text);
    final sodiumMg = _matchNumber(_sodiumMgRegex, text) ??
        (sodiumG != null
            ? sodiumG * 1000
            : (saltGDirect != null ? saltGDirect * 400 : null));
    final saltG =
        saltGDirect ?? (sodiumMg != null ? sodiumMg * 2.5 / 1000 : null);

    if (energyKcal == null &&
        sugarsG == null &&
        fatG == null &&
        saturatedFatG == null &&
        carbohydratesG == null &&
        proteinsG == null &&
        fiberG == null &&
        saltG == null &&
        sodiumMg == null) {
      return Nutrition.empty;
    }

    return Nutrition(
      energyKcal: energyKcal,
      sugarsG: sugarsG,
      fatG: fatG,
      saturatedFatG: saturatedFatG,
      carbohydratesG: carbohydratesG,
      proteinsG: proteinsG,
      fiberG: fiberG,
      saltG: saltG,
      sodiumMg: sodiumMg,
    );
  }

  double? _matchNumber(RegExp pattern, String text) {
    final match = pattern.firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  String _guessProductName(String text) {
    const ignoredKeywords = [
      'komposisi',
      'ingredients',
      'bahan-bahan',
      'informasi nilai gizi',
      'nutrition facts',
      'takaran saji',
      'jumlah sajian',
      'bpom',
      'halal',
      'kode produksi',
      'baik digunakan',
    ];

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 2 && !_numericOrUnitOnlyRegex.hasMatch(l));

    for (final line in lines) {
      final low = line.toLowerCase();
      if (!ignoredKeywords.any(low.contains)) {
        return line;
      }
    }
    return 'Produk Hasil Scan OCR';
  }

  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}
