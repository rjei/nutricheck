import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutricheck/data/datasources/open_food_facts_data_source.dart';
import 'package:nutricheck/data/datasources/product_data_source.dart';
import 'package:nutricheck/data/models/nutrition.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('buildSearchQuery', () {
    test('selalu menyertakan filter Indonesia', () {
      expect(
        OpenFoodFactsDataSource.buildSearchQuery(''),
        'countries_tags:"en:indonesia"',
      );
    });

    test('multi-kata digabung dengan AND (format yang bekerja di OFF)', () {
      expect(
        OpenFoodFactsDataSource.buildSearchQuery('Teh  Botol'),
        'countries_tags:"en:indonesia" AND teh AND botol',
      );
    });

    test('karakter spesial Lucene dan operator tidak bisa disisipkan', () {
      final q = OpenFoodFactsDataSource.buildSearchQuery(
        'indomie" OR countries_tags:"en:france (x) -y*',
      );
      // Tanpa titik dua tidak mungkin ada filter field tambahan: satu-satunya
      // `:` adalah milik filter negara (`countries_tags:"en:indonesia"`).
      expect(':'.allMatches(q).length, 2);
      expect(q.contains('en:france'), isFalse);
      expect(q.split('"').length, 3, reason: 'hanya sepasang tanda kutip dari filter');
      expect(q.contains(' OR '), isFalse);
      expect(q.contains('*'), isFalse);
      expect(q.contains('('), isFalse);
    });

    test('filter kategori hanya menerima tag yang valid', () {
      expect(
        OpenFoodFactsDataSource.buildSearchQuery('kecap', categoryTag: 'en:condiments'),
        'countries_tags:"en:indonesia" AND categories_tags:"en:condiments" AND kecap',
      );
      expect(
        OpenFoodFactsDataSource.buildSearchQuery('x', categoryTag: 'bad" OR 1'),
        'countries_tags:"en:indonesia" AND x',
      );
    });

    test('jumlah kata dibatasi', () {
      final q = OpenFoodFactsDataSource.buildSearchQuery('a b c d e f g h');
      expect(' AND '.allMatches(q).length, 6);
    });
  });

  group('parseAdditiveTags', () {
    test('mengubah tag OFF menjadi kode E dan membuang yang bukan kode', () {
      expect(
        OpenFoodFactsDataSource.parseAdditiveTags(
          ['en:e211', 'en:e330i', 'en:e150d', 'en:e211', 'en:not-a-code', 'e621'],
        ),
        ['E211', 'E330i', 'E150d', 'E621'],
      );
    });
  });

  group('Nutrition.fromOpenFoodFacts', () {
    test('natrium dalam gram dikonversi ke mg dan kJ ke kkal', () {
      final n = Nutrition.fromOpenFoodFacts({
        'energy-kcal_100g': 60,
        'sugars_100g': '14.5',
        'sodium_100g': 0.044,
        'proteins_100g': 0,
      });
      expect(n.energyKcal, 60);
      expect(n.sugarsG, 14.5);
      expect(n.sodiumMg, closeTo(44, 1e-9));
      expect(n.saltG, closeTo(0.11, 1e-9));
      expect(n.proteinsG, 0);
      expect(n.fatG, isNull, reason: 'tidak diketahui bukan nol');

      final fromKj = Nutrition.fromOpenFoodFacts({'energy_100g': 418.4});
      expect(fromKj.energyKcal, closeTo(100, 1e-9));
    });

    test('natrium diturunkan dari garam bila tidak ada', () {
      final n = Nutrition.fromOpenFoodFacts({'salt_100g': 2.5});
      expect(n.sodiumMg, closeTo(1000, 1e-9));
    });

    test('tanpa data menghasilkan Nutrition kosong', () {
      expect(Nutrition.fromOpenFoodFacts(null).isEmpty, isTrue);
    });
  });

  group('fetchByBarcode', () {
    Map<String, dynamic> productJson({List<String> countries = const ['en:indonesia']}) => {
          'status': 1,
          'code': '8997035600546',
          'product': {
            'code': '8997035600546',
            'product_name': 'Ion Supply Drink',
            'brands': 'Pocari, Otsuka',
            'quantity': '900 ml',
            'countries_tags': countries,
            'ingredients_text': 'Air, gula, _kedelai_, natrium benzoat',
            'additives_tags': ['en:e211', 'en:e330'],
            'nutriments': {'energy-kcal_100g': 60, 'sugars_100g': 14},
            'nutriscore_grade': 'E',
            'image_front_url': 'https://img/front.jpg',
          },
        };

    test('mem-parsing produk Indonesia dan mengirim User-Agent', () async {
      late http.Request captured;
      final source = OpenFoodFactsDataSource(
        client: MockClient((request) async {
          captured = request;
          return _json(productJson());
        }),
      );

      final product = await source.fetchByBarcode('8997035600546');

      expect(captured.url.host, 'world.openfoodfacts.org');
      expect(captured.url.path, '/api/v2/product/8997035600546');
      expect(captured.headers['User-Agent'], contains('NutriCheck'));

      expect(product, isNotNull);
      expect(product!.name, 'Ion Supply Drink');
      expect(product.brand, 'Pocari', reason: 'hanya merek pertama');
      expect(product.quantity, '900 ml');
      expect(product.additiveCodes, ['E211', 'E330']);
      expect(product.ingredientsText, 'Air, gula, kedelai, natrium benzoat');
      expect(product.nutriscoreGrade, 'e');
      expect(product.nutrition.energyKcal, 60);
      expect(product.isComplete, isTrue);
      expect(product.isSoldInIndonesia, isTrue);
    });

    test('produk yang tidak dijual di Indonesia ditolak', () async {
      final source = OpenFoodFactsDataSource(
        client: MockClient((_) async => _json(productJson(countries: ['en:france']))),
      );
      expect(await source.fetchByBarcode('8997035600546'), isNull);
    });

    test('produk tanpa data negara ditolak', () async {
      final source = OpenFoodFactsDataSource(
        client: MockClient((_) async => _json(productJson(countries: []))),
      );
      expect(await source.fetchByBarcode('8997035600546'), isNull);
    });

    test('status 0 dan HTTP 404 berarti tidak ditemukan', () async {
      final notFound = OpenFoodFactsDataSource(
        client: MockClient((_) async => _json({'status': 0, 'status_verbose': 'product not found'})),
      );
      expect(await notFound.fetchByBarcode('1234567890123'), isNull);

      final http404 = OpenFoodFactsDataSource(
        client: MockClient((_) async => _json({'status': 0}, 404)),
      );
      expect(await http404.fetchByBarcode('1234567890123'), isNull);
    });

    test('server sibuk dan jaringan putus menjadi ProductSourceException', () async {
      final busy = OpenFoodFactsDataSource(
        client: MockClient((_) async => http.Response('<html>503</html>', 503)),
      );
      await expectLater(busy.fetchByBarcode('8997035600546'), throwsA(isA<ProductSourceException>()));

      final offline = OpenFoodFactsDataSource(
        client: MockClient((_) async => throw http.ClientException('no route')),
      );
      await expectLater(offline.fetchByBarcode('8997035600546'), throwsA(isA<ProductSourceException>()));
    });

    test('respons non-JSON menjadi ProductSourceException', () async {
      final source = OpenFoodFactsDataSource(
        client: MockClient((_) async => http.Response('<html>oops</html>', 200)),
      );
      await expectLater(source.fetchByBarcode('8997035600546'), throwsA(isA<ProductSourceException>()));
    });
  });

  group('search', () {
    test('memakai Search-a-licious dengan filter Indonesia dan memfilter ulang hasil', () async {
      late Uri captured;
      final source = OpenFoodFactsDataSource(
        client: MockClient((request) async {
          captured = request.url;
          return _json({
            'count': 38,
            'page': 1,
            'page_count': 2,
            'hits': [
              {
                'code': '0089686010824',
                'product_name': 'Indomie Mi Goreng',
                'brands': ['Indomie'],
                'quantity': '80g',
                'countries_tags': ['en:indonesia'],
                'image_front_small_url': 'https://img/indomie.jpg',
              },
              {
                // Server "bocor": produk non-Indonesia tidak boleh lolos.
                'code': '3017620422003',
                'product_name': 'Nutella',
                'brands': ['Ferrero'],
                'countries_tags': ['en:france'],
              },
              {
                // Tanpa nama: tidak berguna di daftar.
                'code': '8990000000002',
                'countries_tags': ['en:indonesia'],
              },
            ],
          });
        }),
      );

      final result = await source.search('indomie goreng', page: 1, pageSize: 20);

      expect(captured.host, 'search.openfoodfacts.org');
      expect(captured.queryParameters['q'],
          'countries_tags:"en:indonesia" AND indomie AND goreng');
      expect(captured.queryParameters['page_size'], '20');

      expect(result.products.map((p) => p.name), ['Indomie Mi Goreng']);
      expect(result.products.single.brand, 'Indomie');
      expect(result.products.single.isComplete, isFalse);
      expect(result.totalCount, 38);
      expect(result.hasMore, isTrue);
    });

    test('hasMore false di halaman terakhir', () async {
      final source = OpenFoodFactsDataSource(
        client: MockClient((_) async => _json({'count': 1, 'page_count': 1, 'hits': []})),
      );
      final result = await source.search('x');
      expect(result.products, isEmpty);
      expect(result.hasMore, isFalse);
    });
  });
}
