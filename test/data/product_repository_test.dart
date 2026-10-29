import 'package:flutter_test/flutter_test.dart';
import 'package:nutricheck/data/datasources/product_cache.dart';
import 'package:nutricheck/data/datasources/product_data_source.dart';
import 'package:nutricheck/data/models/health_condition.dart';
import 'package:nutricheck/data/models/product.dart';
import 'package:nutricheck/data/models/risk_level.dart';
import 'package:nutricheck/data/repositories/additive_repository.dart';
import 'package:nutricheck/data/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_support.dart';

void main() {
  late AdditiveRepository additives;
  late FakeProductDataSource dataSource;
  late InMemoryProductCache cache;
  late DateTime now;
  late ProductRepository repo;

  setUp(() {
    additives = AdditiveRepository(dataSource: FileAdditiveDataSource());
    dataSource = FakeProductDataSource();
    cache = InMemoryProductCache();
    now = DateTime(2026, 10, 29, 12);
    repo = ProductRepository(
      dataSource: dataSource,
      cache: cache,
      additives: additives,
      clock: () => now,
    );
  });

  group('normalizeBarcode', () {
    test('menerima 8-14 digit dan membuang spasi/strip', () {
      expect(ProductRepository.normalizeBarcode('8997035600546'), '8997035600546');
      expect(ProductRepository.normalizeBarcode(' 8997 0356-00546 '), '8997035600546');
      expect(ProductRepository.normalizeBarcode('12345678'), '12345678');
    });

    test('menolak yang bukan barcode produk', () {
      expect(ProductRepository.normalizeBarcode('https://example.com'), isNull);
      expect(ProductRepository.normalizeBarcode('1234567'), isNull);
      expect(ProductRepository.normalizeBarcode('123456789012345'), isNull);
      expect(ProductRepository.normalizeBarcode('ABC12345678'), isNull);
      expect(ProductRepository.normalizeBarcode(''), isNull);
    });
  });

  group('getByBarcode: hanya produk Indonesia', () {
    test('produk Indonesia dikembalikan dan di-cache', () async {
      dataSource.byBarcode = {'8997035600546': makeProduct(barcode: '8997035600546')};

      final product = await repo.getByBarcode('8997035600546');

      expect(product?.barcode, '8997035600546');
      expect((await cache.get('8997035600546')), isNotNull);
    });

    test('produk non-Indonesia ditolak walau datasource mengembalikannya', () async {
      dataSource.byBarcode = {
        '3017620422003': makeProduct(
          barcode: '3017620422003',
          name: 'Nutella',
          countryTags: ['en:france'],
        ),
      };

      expect(await repo.getByBarcode('3017620422003'), isNull);
      expect(await cache.get('3017620422003'), isNull, reason: 'tidak boleh di-cache');
    });

    test('barcode tidak valid tidak memanggil jaringan', () async {
      expect(await repo.getByBarcode('https://example.com/qr'), isNull);
      expect(dataSource.barcodeCalls, isEmpty);
    });

    test('mencoba bentuk alternatif UPC-A 12 digit menjadi EAN-13', () async {
      dataSource.byBarcode = {'0089686010824': makeProduct(barcode: '0089686010824')};

      final product = await repo.getByBarcode('089686010824');

      expect(product?.barcode, '0089686010824');
      expect(dataSource.barcodeCalls, ['089686010824', '0089686010824']);
    });

    test('EAN-13 berawalan 0 mencoba tanpa nol di depan', () async {
      dataSource.byBarcode = {'089686010824': makeProduct(barcode: '089686010824')};

      expect((await repo.getByBarcode('0089686010824'))?.barcode, '089686010824');
    });
  });

  group('getByBarcode: cache', () {
    test('cache segar dipakai tanpa jaringan', () async {
      await cache.put(makeProduct(barcode: '8997035600546', fetchedAt: now.subtract(const Duration(days: 1))));

      final product = await repo.getByBarcode('8997035600546');

      expect(product, isNotNull);
      expect(dataSource.barcodeCalls, isEmpty);
    });

    test('cache kedaluwarsa diambil ulang', () async {
      await cache.put(makeProduct(
        barcode: '8997035600546',
        name: 'Lama',
        fetchedAt: now.subtract(const Duration(days: 30)),
      ));
      dataSource.byBarcode = {
        '8997035600546': makeProduct(barcode: '8997035600546', name: 'Baru', fetchedAt: now),
      };

      expect((await repo.getByBarcode('8997035600546'))?.name, 'Baru');
    });

    test('offline: cache kedaluwarsa tetap dipakai sebagai cadangan', () async {
      await cache.put(makeProduct(
        barcode: '8997035600546',
        name: 'Lama',
        fetchedAt: now.subtract(const Duration(days: 30)),
      ));
      dataSource.failWithNetworkError = true;

      expect((await repo.getByBarcode('8997035600546'))?.name, 'Lama');
    });

    test('offline tanpa cache melempar ProductSourceException', () async {
      dataSource.failWithNetworkError = true;

      await expectLater(
        repo.getByBarcode('8997035600546'),
        throwsA(isA<ProductSourceException>()),
      );
    });

    test('forceRefresh melewati cache segar', () async {
      await cache.put(makeProduct(barcode: '8997035600546', name: 'Lama', fetchedAt: now));
      dataSource.byBarcode = {
        '8997035600546': makeProduct(barcode: '8997035600546', name: 'Baru', fetchedAt: now),
      };

      expect((await repo.getByBarcode('8997035600546', forceRefresh: true))?.name, 'Baru');
    });

    test('ringkasan hasil pencarian (belum lengkap) tidak dianggap cache valid', () async {
      await cache.put(makeProduct(barcode: '8997035600546', name: 'Ringkasan', isComplete: false, fetchedAt: now));
      dataSource.byBarcode = {
        '8997035600546': makeProduct(barcode: '8997035600546', name: 'Lengkap', fetchedAt: now),
      };

      expect((await repo.getByBarcode('8997035600546'))?.name, 'Lengkap');
    });
  });

  group('search', () {
    test('menyaring produk non-Indonesia dan duplikat', () async {
      dataSource.searchResults = [
        makeProduct(barcode: '8990000000001', name: 'Produk A', isComplete: false),
        makeProduct(barcode: '8990000000001', name: 'Produk A duplikat', isComplete: false),
        makeProduct(barcode: '3017620422003', name: 'Produk Asing', countryTags: ['en:france'], isComplete: false),
        makeProduct(barcode: '8990000000002', name: 'Produk B', countryTags: ['en:indonesia', 'en:malaysia'], isComplete: false),
      ];

      final result = await repo.search('  a  ');

      expect(result.products.map((p) => p.name), ['Produk A', 'Produk B']);
      expect(dataSource.searchQueries, ['a'], reason: 'query di-trim');
    });
  });

  group('ensureComplete', () {
    test('produk ringkasan dilengkapi lewat lookup barcode', () async {
      dataSource.byBarcode = {
        '8990000000001': makeProduct(
          barcode: '8990000000001',
          ingredientsText: 'Air, gula',
        ),
      };
      final summary = makeProduct(barcode: '8990000000001', isComplete: false);

      final full = await repo.ensureComplete(summary);

      expect(full.isComplete, isTrue);
      expect(full.ingredientsText, 'Air, gula');
    });

    test('produk lengkap/lokal tidak memanggil jaringan', () async {
      await repo.ensureComplete(makeProduct());
      await repo.ensureComplete(Product.local(name: 'Lokal'));
      expect(dataSource.barcodeCalls, isEmpty);
    });

    test('gagal diambil: kembalikan ringkasan agar UI tetap tampil', () async {
      dataSource.byBarcode = const {};
      final summary = makeProduct(barcode: '8990000000009', isComplete: false);

      expect(await repo.ensureComplete(summary), same(summary));
    });
  });

  group('analyze', () {
    test('menggabungkan tag aditif dan deteksi komposisi, urut risiko tertinggi', () async {
      final product = makeProduct(
        additiveCodes: ['E330', 'E211'],
        ingredientsText: 'Air, gula, pewarna tartrazin, pemanis aspartam',
      );

      final analysis = await repo.analyze(product);
      final ids = analysis.additives.map((a) => a.id).toList();

      expect(ids, containsAll(['E330', 'E211', 'E102', 'E951']));
      expect(ids.toSet().length, ids.length, reason: 'tanpa duplikat');
      expect(analysis.additives.first.riskLevel, RiskLevel.waspada);
      expect(analysis.overallRisk, RiskLevel.waspada);
      expect(analysis.countOf(RiskLevel.aman), 1);
    });

    test('varian kode memakai kode induk, kode asing masuk unknown', () async {
      final analysis = await repo.analyze(makeProduct(
        additiveCodes: ['E330i', 'E450iii', 'E999', 'E1520'],
      ));

      expect(analysis.additives.map((a) => a.id), containsAll(['E330', 'E450']));
      expect(analysis.unknownAdditiveCodes, ['E999', 'E1520']);
    });

    test('bahan berbahaya mengangkat risiko keseluruhan menjadi bahaya', () async {
      final analysis = await repo.analyze(makeProduct(
        ingredientsText: 'Tepung, air, boraks, garam',
      ));

      expect(analysis.additives.map((a) => a.id), contains('boraks'));
      expect(analysis.overallRisk, RiskLevel.bahaya);
    });

    test('tanpa aditif tapi ada komposisi dianggap aman', () async {
      final analysis = await repo.analyze(makeProduct(ingredientsText: 'Air mineral'));

      expect(analysis.additives, isEmpty);
      expect(analysis.overallRisk, RiskLevel.aman);
    });

    test('tanpa data komposisi TIDAK boleh dinyatakan aman', () async {
      final analysis = await repo.analyze(makeProduct());

      expect(analysis.hasIngredientData, isFalse);
      expect(analysis.overallRisk, isNull);
    });

    test('warningsFor mencocokkan aditif dengan kondisi pengguna', () async {
      final analysis = await repo.analyze(makeProduct(
        additiveCodes: ['E211', 'E220', 'E330'],
      ));

      final warnings = analysis.warningsFor([
        HealthCondition.asthma.id,
        HealthCondition.diabetes.id,
        'kondisi_tak_dikenal',
      ]);

      expect(warnings.map((w) => w.condition.id), [HealthCondition.asthma.id]);
      expect(warnings.single.additives.map((a) => a.id), containsAll(['E211', 'E220']));
      expect(warnings.single.additives.map((a) => a.id), isNot(contains('E330')));
    });
  });

  group('serialisasi', () {
    test('Product toJson -> fromJson', () {
      final p = makeProduct(
        brand: 'Merek',
        additiveCodes: ['E211'],
        ingredientsText: 'Air',
      );
      expect(Product.fromJson(p.toJson()).toJson(), p.toJson());
    });
  });

  group('SharedPrefsProductCache', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('persisten antar instance', () async {
      await SharedPrefsProductCache().put(makeProduct(barcode: '8990000000001', name: 'Tersimpan'));

      final restored = await SharedPrefsProductCache().get('8990000000001');
      expect(restored?.name, 'Tersimpan');
    });

    test('membuang entri terlama saat melebihi batas', () async {
      final small = SharedPrefsProductCache(maxEntries: 2);
      await small.put(makeProduct(barcode: '1', name: '1', fetchedAt: DateTime(2026, 1, 1)));
      await small.put(makeProduct(barcode: '2', name: '2', fetchedAt: DateTime(2026, 1, 2)));
      await small.put(makeProduct(barcode: '3', name: '3', fetchedAt: DateTime(2026, 1, 3)));

      final reloaded = SharedPrefsProductCache(maxEntries: 2);
      expect(await reloaded.get('1'), isNull);
      expect(await reloaded.get('2'), isNotNull);
      expect(await reloaded.get('3'), isNotNull);
    });

    test('data rusak tidak membuat aplikasi crash', () async {
      SharedPreferences.setMockInitialValues({SharedPrefsProductCache.storageKey: '{bukan json'});

      final cache = SharedPrefsProductCache();
      expect(await cache.get('x'), isNull);
      await cache.put(makeProduct(barcode: '8990000000001'));
      expect(await cache.get('8990000000001'), isNotNull);
    });
  });
}
