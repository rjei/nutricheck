import 'package:flutter_test/flutter_test.dart';
import 'package:nutricheck/data/datasources/product_cache.dart';
import 'package:nutricheck/data/repositories/additive_repository.dart';
import 'package:nutricheck/data/repositories/product_repository.dart';
import 'package:nutricheck/services/ocr_service.dart';

import '../data/support/test_support.dart';

void main() {
  late OcrService ocrService;
  late AdditiveRepository additiveRepo;
  late ProductRepository productRepo;
  late InMemoryProductCache cache;

  setUp(() {
    ocrService = OcrService.instance;
    additiveRepo = AdditiveRepository(dataSource: FileAdditiveDataSource());
    cache = InMemoryProductCache();
    productRepo = ProductRepository(
      dataSource: FakeProductDataSource(),
      cache: cache,
      additives: additiveRepo,
    );
  });

  group('OcrService backend parsing & validation', () {
    test('analyzeOcrText melempar OcrException jika teks kosong', () async {
      await expectLater(
        () => ocrService.analyzeOcrText(
          '   \n  ',
          productRepository: productRepo,
          additiveRepository: additiveRepo,
        ),
        throwsA(isA<OcrException>()),
      );
    });

    test('normalizeOcrText menyambung baris terpotong dan memperbaiki typo E/INS', () {
      const raw = 'Air, Gula, Penga-\nwet Natrium\nBenzoat (ElO2), INS l02';
      final normalized = ocrService.normalizeOcrText(raw);

      expect(normalized, contains('Pengawet Natrium Benzoat'));
      expect(normalized, contains('E102'));
      expect(normalized, contains('INS 102'));
    });

    test('extractIngredientsSection memotong tepat antara Komposisi dan Informasi Nilai Gizi', () {
      const raw = '''
Minuman Segar
KOMPOSISI: Air, Gula, Pengawet Natrium Benzoat (E211), Asam Sitrat.
INFORMASI NILAI GIZI
Takaran saji 250 ml
Energi Total 100 kkal
''';
      final section = ocrService.extractIngredientsSection(raw);

      expect(section, startsWith('Air, Gula'));
      expect(section, isNot(contains('INFORMASI NILAI GIZI')));
      expect(section, isNot(contains('Takaran saji')));
    });

    test('extractNutrition membaca seluruh informasi gizi standar Indonesia', () {
      const raw = '''
INFORMASI NILAI GIZI
Energi Total 140 kkal
Lemak Total 4,5 g
Lemak Jenuh 2 g
Protein 3 g
Karbohidrat Total 22 g
Serat Pangan 1,5 g
Gula 12 g
Natrium 180 mg
''';
      final nutrition = ocrService.extractNutrition(raw);

      expect(nutrition.energyKcal, 140);
      expect(nutrition.fatG, 4.5);
      expect(nutrition.saturatedFatG, 2);
      expect(nutrition.proteinsG, 3);
      expect(nutrition.carbohydratesG, 22);
      expect(nutrition.fiberG, 1.5);
      expect(nutrition.sugarsG, 12);
      expect(nutrition.sodiumMg, 180);
    });

    test('analyzeOcrText mendeteksi aditif lintas baris & menyimpan ke cache', () async {
      const raw = '''
Teh Kemasan Nusantara
Komposisi: Air, Gula, Ekstrak Teh, Pengatur Keasaman Asam Sitrat,
Pengawet Natrium
Benzoat (E2l1).
Informasi Nilai Gizi: Energi 90 kkal, Gula 18 g, Natrium 25 mg.
''';
      final result = await ocrService.analyzeOcrText(
        raw,
        existingBarcode: '8999999123456',
        productRepository: productRepo,
        additiveRepository: additiveRepo,
      );

      expect(result.product.barcode, '8999999123456');
      expect(result.product.name, 'Teh Kemasan Nusantara');
      expect(result.detectedAdditives.any((a) => a.eNumber == 'E211'), isTrue);
      expect(result.extractedNutrition.sugarsG, 18);

      final cached = await cache.get('8999999123456');
      expect(cached, isNotNull);
      expect(cached!.isComplete, isTrue);
    });
  });
}
