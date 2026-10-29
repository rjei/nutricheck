import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutricheck/data/models/product.dart';
import 'package:nutricheck/data/repositories/additive_repository.dart';
import 'package:nutricheck/data/repositories/product_repository.dart';
import 'package:nutricheck/screens/product_detail_screen.dart';
import 'package:nutricheck/screens/search_screen.dart';
import 'package:nutricheck/services/auth_service.dart';
import 'package:nutricheck/widgets/scan_result_sheet.dart';

import '../data/support/test_support.dart';

ProductRepository _repo(FakeProductDataSource dataSource) => ProductRepository(
      dataSource: dataSource,
      additives: AdditiveRepository(dataSource: FileAdditiveDataSource()),
    );

/// Memperbesar layar agar seluruh isi ListView dan chip horizontal ikut ter-render.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Product _indomie({bool withIngredients = true}) => makeProduct(
      barcode: '0089686010824',
      name: 'Indomie Mi Goreng',
      brand: 'Indomie',
      additiveCodes: withIngredients ? ['E211', 'E330', 'E621'] : const [],
      ingredientsText: withIngredients ? 'Mi, minyak, garam, natrium benzoat' : null,
    );

void main() {
  group('SearchScreen', () {
    testWidgets('menampilkan produk Indonesia dari repository', (tester) async {
      _useTallScreen(tester);
      final source = FakeProductDataSource(searchResults: [
        _indomie().copyForList(),
        makeProduct(barcode: '8990000000002', name: 'Teh Botol', brand: 'Sosro', isComplete: false),
      ]);

      await tester.pumpWidget(MaterialApp(
        home: SearchScreen(
          productRepository: _repo(source),
          additiveRepository: AdditiveRepository(dataSource: FileAdditiveDataSource()),
        ),
      ));
      await tester.pump();

      expect(find.text('Katalog & Hasil Pencarian'), findsOneWidget);
      expect(find.text('Indomie Mi Goreng'), findsOneWidget);
      expect(find.text('Teh Botol'), findsOneWidget);
      expect(find.text('2 Produk'), findsOneWidget);
      expect(find.textContaining('Hanya produk yang beredar di Indonesia'), findsOneWidget);
      expect(source.searchQueries, ['']);
    });

    testWidgets('mengetik memicu pencarian setelah jeda (debounce)', (tester) async {
      final source = FakeProductDataSource();
      await tester.pumpWidget(MaterialApp(
        home: SearchScreen(
          productRepository: _repo(source),
          additiveRepository: AdditiveRepository(dataSource: FileAdditiveDataSource()),
        ),
      ));
      await tester.pump();
      source.searchQueries.clear();

      await tester.enterText(find.byType(TextField), 'indomie goreng');
      await tester.pump(const Duration(milliseconds: 200));
      expect(source.searchQueries, isEmpty, reason: 'belum lewat jeda');

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(source.searchQueries, ['indomie goreng']);
      expect(find.text('Tidak ada produk ditemukan'), findsOneWidget);
    });

    testWidgets('jaringan gagal menampilkan pesan dan tombol coba lagi', (tester) async {
      final source = FakeProductDataSource()..failWithNetworkError = true;
      await tester.pumpWidget(MaterialApp(
        home: SearchScreen(
          productRepository: _repo(source),
          additiveRepository: AdditiveRepository(dataSource: FileAdditiveDataSource()),
        ),
      ));
      await tester.pump();

      expect(find.text('Tidak dapat memuat data'), findsOneWidget);
      expect(find.text('Tidak dapat terhubung ke internet.'), findsOneWidget);

      source
        ..failWithNetworkError = false
        ..searchResults = [makeProduct(name: 'Kecap Bango', isComplete: false)];
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Kecap Bango'), findsOneWidget);
      expect(find.text('Tidak dapat memuat data'), findsNothing);
    });

    testWidgets('chip Zat Aditif menampilkan basis data lokal dan detailnya', (tester) async {
      _useTallScreen(tester);
      final source = FakeProductDataSource();
      await tester.pumpWidget(MaterialApp(
        home: SearchScreen(
          productRepository: _repo(source),
          additiveRepository: AdditiveRepository(dataSource: FileAdditiveDataSource()),
        ),
      ));
      await tester.pumpAndSettle();
      source.searchQueries.clear();

      await tester.tap(find.text('Zat Aditif'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Basis data zat aditif lokal'), findsOneWidget);
      expect(source.searchQueries, isEmpty, reason: 'mode aditif tidak memanggil API produk');

      final additiveItem = find.text('E211 (Natrium Benzoat)');
      await tester.scrollUntilVisible(
        additiveItem,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(additiveItem, findsOneWidget);

      await tester.tap(additiveItem);
      await tester.pumpAndSettle();
      expect(find.text('Penjelasan'), findsOneWidget);
      expect(find.text('20 mg/kg BB'), findsOneWidget);
    });

    testWidgets('mengetik kode E otomatis mencari di basis data aditif', (tester) async {
      final source = FakeProductDataSource();
      await tester.pumpWidget(MaterialApp(
        home: SearchScreen(
          productRepository: _repo(source),
          additiveRepository: AdditiveRepository(dataSource: FileAdditiveDataSource()),
        ),
      ));
      await tester.pump();
      source.searchQueries.clear();

      await tester.enterText(find.byType(TextField), 'E621');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('E621 (Mononatrium Glutamat (MSG))'), findsOneWidget);
      expect(source.searchQueries, isEmpty);
    });

    testWidgets('mengetuk produk membuka detail', (tester) async {
      _useTallScreen(tester);
      final source = FakeProductDataSource(
        searchResults: [_indomie().copyForList()],
        byBarcode: {'0089686010824': _indomie()},
      );
      final repo = _repo(source);
      await tester.pumpWidget(MaterialApp(
        home: SearchScreen(
          productRepository: repo,
          additiveRepository: AdditiveRepository(dataSource: FileAdditiveDataSource()),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Indomie Mi Goreng'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Produk'), findsOneWidget);
      expect(find.text('Barcode • 0089686010824'), findsOneWidget);
      expect(source.barcodeCalls, ['0089686010824'], reason: 'komposisi lengkap diambil saat detail dibuka');
    });
  });

  group('ProductDetailScreen', () {
    tearDown(() => AuthService().logout());

    testWidgets('menampilkan aditif nyata, risiko, dan peringatan profil kesehatan', (tester) async {
      _useTallScreen(tester);
      // Budi punya kondisi "Hipertensi / Sensitif Garam"; E211 & E621 memicunya.
      AuthService().login('budi.santoso@gmail.com', 'password123');

      await tester.pumpWidget(MaterialApp(
        home: ProductDetailScreen(
          product: _indomie(),
          repository: _repo(FakeProductDataSource()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Indomie Mi Goreng'), findsOneWidget);
      expect(find.text('Indomie • '), findsNothing);
      expect(find.text('Waspada'), findsWidgets);
      expect(find.text('E211 (Natrium Benzoat)'), findsOneWidget);
      expect(find.text('E330 (Asam Sitrat)'), findsOneWidget);
      expect(find.textContaining('Mi, minyak, garam'), findsOneWidget);

      expect(find.text('Hipertensi / Sensitif Garam'), findsOneWidget);
      expect(find.textContaining('Mengandung E621'), findsOneWidget);
      expect(find.textContaining('E211 (Natrium Benzoat)'), findsWidgets);
      // Kondisi lain yang tidak terpicu tampil tanpa peringatan.
      expect(find.text('Bebas Gluten'), findsOneWidget);
      expect(find.text('Tidak ada aditif pemicu terdeteksi'), findsOneWidget);
      expect(find.text('Open Food Facts'), findsOneWidget);
    });

    testWidgets('tanpa data komposisi tidak dinyatakan Aman', (tester) async {
      _useTallScreen(tester);
      final loggedIn = AuthService().login('budi.santoso@gmail.com', 'password123');
      // ignore: avoid_print
      print('DEBUG: loggedIn=$loggedIn, user=${AuthService().currentUser?.email}, conditions=${AuthService().currentUser?.selectedConditions}');

      await tester.pumpWidget(MaterialApp(
        home: ProductDetailScreen(
          product: _indomie(withIngredients: false),
          repository: _repo(FakeProductDataSource()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Data Terbatas'), findsOneWidget);
      expect(find.text('Aman'), findsNothing);
      expect(find.textContaining('belum tersedia di Open Food Facts'), findsOneWidget);
      expect(find.textContaining('belum bisa diperiksa'), findsOneWidget);
    });

    testWidgets('gagal melengkapi data menampilkan error dan bisa dicoba ulang', (tester) async {
      _useTallScreen(tester);
      final source = FakeProductDataSource()..failWithNetworkError = true;

      await tester.pumpWidget(MaterialApp(
        home: ProductDetailScreen(
          product: _indomie().copyForList(),
          repository: _repo(source),
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Tidak dapat terhubung ke internet.'), findsOneWidget);

      source
        ..failWithNetworkError = false
        ..byBarcode = {'0089686010824': _indomie()};
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      await tester.pump();

      expect(find.text('E211 (Natrium Benzoat)'), findsOneWidget);
    });
  });

  group('ScanResultSheet', () {
    Future<void> pumpSheet(WidgetTester tester, String code, FakeProductDataSource source) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ScanResultSheet(code: code, repository: _repo(source)),
        ),
      ));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('produk Indonesia ditemukan: ringkasan dan tombol detail', (tester) async {
      _useTallScreen(tester);
      await pumpSheet(
        tester,
        '0089686010824',
        FakeProductDataSource(byBarcode: {'0089686010824': _indomie()}),
      );

      expect(find.text('Indomie Mi Goreng'), findsOneWidget);
      expect(find.text('Waspada'), findsOneWidget);
      expect(find.textContaining('aditif terdeteksi'), findsOneWidget);
      expect(find.text('Lihat Detail Analisis'), findsOneWidget);
      expect(find.text('Pindai Lagi'), findsOneWidget);
    });

    testWidgets('produk tidak ada / bukan produk Indonesia: pesan tidak ditemukan', (tester) async {
      _useTallScreen(tester);
      await pumpSheet(
        tester,
        '3017620422003',
        FakeProductDataSource(byBarcode: {
          '3017620422003': makeProduct(
            barcode: '3017620422003',
            name: 'Nutella',
            countryTags: ['en:france'],
          ),
        }),
      );

      expect(find.text('Produk tidak ditemukan'), findsOneWidget);
      expect(find.text('Nutella'), findsNothing);
      expect(find.text('Lihat Detail Analisis'), findsNothing);
    });

    testWidgets('kode QR bukan barcode produk tidak memanggil jaringan', (tester) async {
      _useTallScreen(tester);
      final source = FakeProductDataSource();
      await pumpSheet(tester, 'https://example.com/qr', source);

      expect(find.text('Bukan barcode produk'), findsOneWidget);
      expect(source.barcodeCalls, isEmpty);
    });

    testWidgets('jaringan gagal: pesan error dan coba lagi berhasil', (tester) async {
      _useTallScreen(tester);
      final source = FakeProductDataSource()..failWithNetworkError = true;
      await pumpSheet(tester, '0089686010824', source);

      expect(find.text('Gagal memuat produk'), findsOneWidget);
      expect(find.text('Tidak dapat terhubung ke internet.'), findsOneWidget);

      source
        ..failWithNetworkError = false
        ..byBarcode = {'0089686010824': _indomie()};
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Indomie Mi Goreng'), findsOneWidget);
    });
  });
}

extension on Product {
  /// Versi ringkasan seperti hasil pencarian (tanpa komposisi lengkap).
  Product copyForList() => Product(
        barcode: barcode,
        name: name,
        brand: brand,
        countryTags: countryTags,
        fetchedAt: fetchedAt,
        isComplete: false,
      );
}
