import 'package:flutter_test/flutter_test.dart';
import 'package:nutricheck/data/helpers/indonesian_food_filter.dart';

void main() {
  group('IndonesianFoodFilter', () {
    test('menerima produk makanan/minuman Indonesia asli (barcode 899)', () {
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8999999002503',
          name: 'Kecap Manis',
          brand: 'Bango',
          countryTags: ['en:indonesia'],
        ),
        isTrue,
      );

      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8997035600546',
          name: 'Ion Supply Drink 900ml',
          brand: 'Pocari',
          countryTags: ['en:indonesia'],
        ),
        isTrue,
      );

      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8998009010637',
          name: 'Ultra Milk Low Fat',
          brand: 'Ultra',
          countryTags: ['en:indonesia'],
        ),
        isTrue,
      );
    });

    test('menerima produk Indomie dan Chitato dengan barcode Indofood (089686...)', () {
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '0089686010824',
          name: 'Indomie Mi Goreng',
          brand: 'Indomie',
          countryTags: ['en:indonesia'],
        ),
        isTrue,
      );

      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '0089686598018',
          name: 'Chitato Sapi Panggang',
          brand: 'Indofood',
          countryTags: ['en:indonesia'],
        ),
        isTrue,
      );
    });

    test('menerima produk ber-barcode non-899 yang merupakan makanan beredar di Indonesia', () {
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '0032439099928',
          name: 'Kental Manis Frisian Flag',
          brand: 'Frisian Flag',
          countryTags: ['en:indonesia'],
        ),
        isTrue,
      );
    });

    test('menolak makanan hewan peliharaan (kucing, anjing, ikan, kura-kura, hamster)', () {
      // Makanan kucing
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '6914973308282',
          name: 'Cat food whiskas',
          brand: 'Whiskas',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '10068117',
          name: 'RC Kitten Persian 2kg',
          brand: 'Royal Canin',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8851393000212',
          name: 'TEMPTATION TUNA',
          brand: 'Temptations',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      // Makanan anjing
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '10508808',
          name: 'Doggy man chips for dog',
          brand: 'Doggy man',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8994125000880',
          name: 'dog choize puppy 500g',
          brand: 'Dog Choize',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      // Makanan ikan & reptil
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '0042055221023',
          name: 'FISH FOOD Fancy Guppy 22gr',
          brand: 'Hikari',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '4714954860585',
          name: 'Royal cichlid premium fish pellet',
          brand: 'Ultra fresh',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      // Makanan hamster
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8994571011652',
          name: 'Hamster food selected seeds',
          brand: 'Morning sun',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      // Perlengkapan hewan
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '110128879',
          name: 'Flea & tick spray for pets',
          brand: 'Trick or treat',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );
    });

    test('menolak produk non-makanan (pupuk, benih, racun serangga, sabun, kosmetik)', () {
      // Benih & pupuk
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8997232590879',
          name: 'BENIH MENTIMUN VITANI',
          brand: 'Panah Merah',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '10469748',
          name: 'PUPUK SPEEDGRO BUNGA DAN BUAH',
          brand: 'Speedgro',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '10469464',
          name: 'PEMBASMI GULMA CALGARY 250ML',
          brand: 'Calgary',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8997020380040',
          name: 'ANTI RAYAP CISLIN 25 EC',
          brand: 'Cislin',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      // Sabun, kosmetik & perawatan
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8993560026073',
          name: 'Dettol cool body wash',
          brand: 'Dettol',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8901138830816',
          name: 'HIMALAYA Purifying Neem Mask',
          brand: 'Himalaya',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8998824552091',
          name: 'HANASUI Serum Cushion',
          brand: 'Hanasui',
          countryTags: ['en:indonesia'],
          categoryTags: ['en:non-food-products', 'en:open-beauty-facts'],
        ),
        isFalse,
      );
    });

    test('menolak produk murni luar negeri yang tidak relevan di Indonesia', () {
      // Produk UK yang salah tag di OFF
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '0610370670248',
          name: "Billy Frank's british beef jerky",
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      // Air minum botol Perancis tanpa kaitan Indonesia
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '4891133133385',
          name: 'Eau de source naturelle',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );
    });

    test('menolak produk tanpa tag negara Indonesia', () {
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8999999002503',
          name: 'Kecap Manis',
          countryTags: ['en:france'],
        ),
        isFalse,
      );
    });

    test('menolak nama kosong atau rusak', () {
      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8993118622627',
          name: '   ',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );

      expect(
        IndonesianFoodFilter.isValidIndonesianFood(
          barcode: '8997237300572',
          name: '---',
          countryTags: ['en:indonesia'],
        ),
        isFalse,
      );
    });
  });
}
