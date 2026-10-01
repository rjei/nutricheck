import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final List<String> _recentSearches = [
    'Oat Milk Unsweetened',
    'Natrium Benzoat E211',
    'Kecap Low Sodium',
  ];

  final List<String> _categories = [
    'Semua',
    'Minuman',
    'Snack Sehat',
    'Susu & Olahan',
    'Bumbu Dapur',
    'Bebas Gula',
    'Rendah Natrium',
    'Aditif & E-Code',
  ];

  final List<Map<String, dynamic>> _allProducts = [
    {
      'id': '1',
      'name': 'Oat Milk Unsweetened Barista',
      'brand': 'Oatly Premium',
      'category': 'Minuman',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 5.0,
      'ecode': 'E412 (Guar Gum)',
      'rating': 4.9,
      'tags': ['Bebas Gula', 'Minuman', 'Bebas Gluten'],
      'description': 'Susu gandum murni tanpa gula tambahan. Kandungan aditif penstabil minimal & aman untuk dikonsumsi harian.',
      'recommendation': 'Sangat disarankan untuk diet bebas laktosa dan rendah gula.',
    },
    {
      'id': '2',
      'name': 'Kecap Manis Rendah Gula',
      'brand': 'Tropicana Slim',
      'category': 'Bumbu Dapur',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 8.0,
      'ecode': 'E955 (Sukralosa)',
      'rating': 4.8,
      'tags': ['Bumbu Dapur', 'Rendah Natrium', 'Bebas Gula'],
      'description': 'Kecap manis alternatif bagi penderita diabetes dan hipertensi, menggunakan pemanis tingkat keamanan tinggi.',
      'recommendation': 'Penggunaan sukralosa berada di bawah 2% dari ADI maksimum BPOM.',
    },
    {
      'id': '3',
      'name': 'Yogurt Greek Plain 0% Fat',
      'brand': 'Heavenly Blush',
      'category': 'Susu & Olahan',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 2.0,
      'ecode': 'Bakteri L. Bulgaricus',
      'rating': 4.9,
      'tags': ['Susu & Olahan', 'Snack Sehat', 'Bebas Gula'],
      'description': 'Yogurt Greek tanpa bahan pengawet sintesis, kaya protein cair whey terpisah alami.',
      'recommendation': 'Sumber kalsium dan probiotik yang aman untuk pencernaan sensitif.',
    },
    {
      'id': '4',
      'name': 'Extra Virgin Olive Oil Cold Pressed',
      'brand': 'Borges Organics',
      'category': 'Bumbu Dapur',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 0.0,
      'ecode': 'Alami (100% Organik)',
      'rating': 4.9,
      'tags': ['Bumbu Dapur', 'Snack Sehat'],
      'description': 'Minyak zaitun murni pemerasan dingin pertama. Tanpa aditif pewarna, pemutih, atau pengawet kimia.',
      'recommendation': 'Sangat baik untuk kesehatan jantung dan pemeliharaan lemak baik.',
    },
    {
      'id': '5',
      'name': 'Keripik Kentang Rasa Wagyu BBQ',
      'brand': 'Chitato Select',
      'category': 'Snack Sehat',
      'safetyStatus': 'Perlu Perhatian',
      'safetyColor': const Color(0xFFD97706),
      'safetyBg': const Color(0xFFFEF3C7),
      'adiPercentage': 48.0,
      'ecode': 'E621 (MSG) & E211',
      'rating': 4.3,
      'tags': ['Snack Sehat'],
      'description': 'Keripik kentang renyah dengan rasa gurih. Mengandung penguat rasa Monosodium Glutamat & Natrium Benzoat.',
      'recommendation': 'Batasi konsumsi 1 kemasan per hari untuk mencegah paparan natrium berlebih.',
    },
    {
      'id': '6',
      'name': 'Natrium Benzoat (E211)',
      'brand': 'Aditif Pengawet',
      'category': 'Aditif & E-Code',
      'safetyStatus': 'Risiko Moderat',
      'safetyColor': const Color(0xFFD97706),
      'safetyBg': const Color(0xFFFEF3C7),
      'adiPercentage': 65.0,
      'ecode': 'E211',
      'rating': 3.5,
      'tags': ['Aditif & E-Code'],
      'description': 'Zat pengawet anti-jamur dan bakteri pada makanan & minuman bersoda atau saus.',
      'recommendation': 'ADI maksimum BPOM: 5 mg/kg berat badan. Hindari konsumsi bersama Vitamin C berlebih.',
    },
    {
      'id': '7',
      'name': 'Ekstrak Stevia R-A (E960)',
      'brand': 'Pemanis Alami',
      'category': 'Aditif & E-Code',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 4.0,
      'ecode': 'E960',
      'rating': 4.8,
      'tags': ['Aditif & E-Code', 'Bebas Gula'],
      'description': 'Glikosida steviol dari daun Stevia rebaudiana. Memiliki kalori 0 dan tidak memicu lonjakan glukosa.',
      'recommendation': 'ADI BPOM: 4 mg/kg BB per hari. Aman digunakan untuk gaya hidup bebas gula.',
    },
    {
      'id': '8',
      'name': 'Susu UHT Full Cream Low Fat',
      'brand': 'Greenfields',
      'category': 'Susu & Olahan',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 3.0,
      'ecode': 'E407 (Karagenan Minimal)',
      'rating': 4.7,
      'tags': ['Susu & Olahan', 'Minuman'],
      'description': 'Susu segar UHT dengan kandungan lemak terdistribusi rendah dan kalsium tinggi.',
      'recommendation': 'Cocok untuk konsumsi harian keluarga dan pemenuhan kalsium harian.',
    },
    {
      'id': '9',
      'name': 'Kecap Asin Rendah Natrium',
      'brand': 'Kikkoman Less Sodium',
      'category': 'Bumbu Dapur',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 12.0,
      'ecode': 'Fermentasi Alami',
      'rating': 4.8,
      'tags': ['Bumbu Dapur', 'Rendah Natrium'],
      'description': 'Kecap asin fermentasi kedelai alami dengan pengurangan garam hingga 40% dari standar.',
      'recommendation': 'Pilihan ideal untuk masakan seimbang tanpa kehilangan cita rasa khas.',
    },
    {
      'id': '10',
      'name': 'Granola Bites Chocolate Vanilla',
      'brand': 'East Bali Cashews',
      'category': 'Snack Sehat',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 10.0,
      'ecode': 'Alami (Madu & Kakao)',
      'rating': 4.9,
      'tags': ['Snack Sehat', 'Rendah Natrium'],
      'description': 'Camilan oat dipanggang dengan kacang mete lokal, vanila alami, dan cokelat murni.',
      'recommendation': 'Tinggi serat pangan alami tanpa pengawet sintetis.',
    },
    {
      'id': '11',
      'name': 'Almond Milk Unsweetened',
      'brand': 'Almond Breeze',
      'category': 'Minuman',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 4.0,
      'ecode': 'E322 (Lestin Kedelai)',
      'rating': 4.8,
      'tags': ['Minuman', 'Bebas Gula', 'Rendah Natrium'],
      'description': 'Minuman olahan kacang almond murni kaya Vitamin E tanpa penambahan gula pasir.',
      'recommendation': 'Rendah kalori (hanya 30 kkal per sajian) dan ramah bagi penderita intoleransi laktosa.',
    },
    {
      'id': '12',
      'name': 'Monosodium Glutamat (E621)',
      'brand': 'Penguat Rasa MSG',
      'category': 'Aditif & E-Code',
      'safetyStatus': 'Perlu Perhatian',
      'safetyColor': const Color(0xFFD97706),
      'safetyBg': const Color(0xFFFEF3C7),
      'adiPercentage': 55.0,
      'ecode': 'E621',
      'rating': 4.0,
      'tags': ['Aditif & E-Code'],
      'description': 'Zat penguat rasa umami asam glutamat terfermentasi.',
      'recommendation': 'Disetujui BPOM & FDA. Konsumsi secukupnya untuk menghindari kepekaan rasa manis/gurih berlebih.',
    },
    {
      'id': '13',
      'name': 'Tartrazin Kuning (E102)',
      'brand': 'Pewarna Sintetis',
      'category': 'Aditif & E-Code',
      'safetyStatus': 'Risiko Moderat',
      'safetyColor': const Color(0xFFD97706),
      'safetyBg': const Color(0xFFFEF3C7),
      'adiPercentage': 60.0,
      'ecode': 'E102',
      'rating': 3.2,
      'tags': ['Aditif & E-Code'],
      'description': 'Pewarna sintetis kuning lemon yang digunakan dalam minuman ringan, permen, dan makanan ringan.',
      'recommendation': 'ADI maksimum 7.5 mg/kg BB. Dapat memicu reaksi hiperaktif pada anak sensitif.',
    },
    {
      'id': '14',
      'name': 'Sari Buah Apel Murni 100%',
      'brand': 'Country Choice',
      'category': 'Minuman',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 6.0,
      'ecode': 'E300 (Asam Askorbat)',
      'rating': 4.6,
      'tags': ['Minuman'],
      'description': 'Jus buah apel segar yang diperkaya Vitamin C alami sebagai antioksidan pengawet.',
      'recommendation': 'Tanpa pemanis buatan, mengandung gula alami dari buah (fruktosa).',
    },
    {
      'id': '15',
      'name': 'Dark Chocolate 85% Cocoa',
      'brand': 'Lindt Excellence',
      'category': 'Snack Sehat',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 5.0,
      'ecode': 'E476 (Polirisinoleat)',
      'rating': 4.9,
      'tags': ['Snack Sehat', 'Bebas Gula'],
      'description': 'Cokelat hitam intens dengan kadar flavonoid antioksidan tinggi dan rendah kadar pemanis.',
      'recommendation': 'Sangat baik untuk konsumsi camilan diet rendah kalori dan menjaga kesehatan pembuluh darah.',
    },
    {
      'id': '16',
      'name': 'Garam Laut Alami Unrefined',
      'brand': 'Puravita Pure',
      'category': 'Bumbu Dapur',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 15.0,
      'ecode': 'Mineral Alami',
      'rating': 4.7,
      'tags': ['Bumbu Dapur', 'Rendah Natrium'],
      'description': 'Garam kristal laut murni kaya mineral jejak tanpa pemutih atau anti-kempal kimiawi.',
      'recommendation': 'Mengandung magnesium & kalium alami yang memperlembut asupan natrium.',
    },
    {
      'id': '17',
      'name': 'Krimer Nabati Multi-Serat',
      'brand': 'Fiber Creme',
      'category': 'Bumbu Dapur',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 7.0,
      'ecode': 'Oligosakarida Alami',
      'rating': 4.8,
      'tags': ['Bumbu Dapur', 'Rendah Natrium'],
      'description': 'Pengganti santan dan krimer tinggi serat oligosakarida bebas kolesterol.',
      'recommendation': 'Aman digunakan untuk sajian kopi, sup, dan hidangan penutup sehat.',
    },
    {
      'id': '18',
      'name': 'Sirup Rasa Karamel Zero Sugar',
      'brand': 'Torani Sugar Free',
      'category': 'Minuman',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 9.0,
      'ecode': 'E950 (Acesulfame-K)',
      'rating': 4.6,
      'tags': ['Minuman', 'Bebas Gula'],
      'description': 'Sirup perisa karamel tanpa kalori untuk racikan kopi & minuman dingin.',
      'recommendation': 'Aman bagi program kadiovaskular dan manajemen berat badan.',
    },
    {
      'id': '19',
      'name': 'Asam Sitrat (E330)',
      'brand': 'Pengatur Keasaman',
      'category': 'Aditif & E-Code',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 2.0,
      'ecode': 'E330',
      'rating': 4.9,
      'tags': ['Aditif & E-Code'],
      'description': 'Senyawa keasaman alami yang umumnya diekstrak dari jeruk dan buah sitrus.',
      'recommendation': 'Tingkat keamanan sangat tinggi (ADI Not Specified / Bebas Batas Kuota BPOM).',
    },
    {
      'id': '20',
      'name': 'Keju Cheddar High Calcium',
      'brand': 'Kraft Singles Light',
      'category': 'Susu & Olahan',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 18.0,
      'ecode': 'E200 (Asam Sorbat)',
      'rating': 4.7,
      'tags': ['Susu & Olahan'],
      'description': 'Keju lembaran rendah lemak tinggi kalsium & protein olahan.',
      'recommendation': 'Pengawet asam sorbat berada di tingkat minimal yang aman bagi anak-anak.',
    },
    {
      'id': '21',
      'name': 'Biskuit Gandum Whole Wheat',
      'brand': 'Roma Whole Wheat',
      'category': 'Snack Sehat',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 12.0,
      'ecode': 'E500 (Natrium Bikarbonat)',
      'rating': 4.6,
      'tags': ['Snack Sehat', 'Rendah Natrium'],
      'description': 'Biskuit kaya gandum utuh dengan serat tinggi untuk membantu rasa kenyang lebih lama.',
      'recommendation': 'Menggunakan pengembang Soda Kue alami yang sangat aman.',
    },
    {
      'id': '22',
      'name': 'Minyak Wijen Murni 100%',
      'brand': 'Lee Kum Kee Pure',
      'category': 'Bumbu Dapur',
      'safetyStatus': 'Aman',
      'safetyColor': const Color(0xFF0F5132),
      'safetyBg': const Color(0xFFD1E7DD),
      'adiPercentage': 0.0,
      'ecode': 'Murni Biji Wijen Sangrai',
      'rating': 4.9,
      'tags': ['Bumbu Dapur'],
      'description': 'Minyak wijen murni hasil pemerasan biji wijen pilihan tanpa pengawet sintetis.',
      'recommendation': 'Kaya antioksidan sesamol dan asam lemak tak jenuh ganda.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty && !_recentSearches.contains(query.trim())) {
      setState(() {
        _recentSearches.insert(0, query.trim());
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _allProducts.where((product) {
      final nameMatches = product['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final brandMatches = product['brand'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final ecodeMatches = product['ecode'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final categoryMatches = product['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesQuery = _searchQuery.isEmpty || nameMatches || brandMatches || ecodeMatches || categoryMatches;

      bool matchesCategory = true;
      if (_selectedCategory != 'Semua') {
        if (_selectedCategory == 'Bebas Gula') {
          matchesCategory = (product['tags'] as List).contains('Bebas Gula');
        } else if (_selectedCategory == 'Rendah Natrium') {
          matchesCategory = (product['tags'] as List).contains('Rendah Natrium');
        } else {
          matchesCategory = product['category'] == _selectedCategory;
        }
      }

      return matchesQuery && matchesCategory;
    }).toList();
  }

  void _showProductDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['brand'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6D7A77),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['name'],
                          style: GoogleFonts.comfortaa(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF191C1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: item['safetyBg'],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['safetyStatus'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item['safetyColor'],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KODE / ADITIF',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['ecode'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F5132),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KONTRIBUSI ADI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item['adiPercentage']}% dari batas',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: item['safetyColor'],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Deskripsi Produk & Komposisi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item['description'],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF3D4947),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF0F5132), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['recommendation'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F5132),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5132),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    'Selesai Mengulas',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'nutricheck',
          style: GoogleFonts.comfortaa(
            color: const Color(0xFF0F5132),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Search Bar & Filter Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar Input
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: _onSearchSubmitted,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFF191C1E),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Cari produk, merek, aditif (E-Code)...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF6D7A77),
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF0F5132),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                      color: Colors.grey,
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune_rounded, color: Color(0xFF0F5132)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Filter pencarian disesuaikan untuk standar BPOM'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Horizontal Category Chips
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0F5132) : Colors.white,
                              borderRadius: BorderRadius.circular(9999),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0C000000),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                )
                              ],
                            ),
                            child: Text(
                              category,
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? Colors.white : const Color(0xFF3D4947),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Results Title Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Katalog & Hasil Pencarian',
                        style: GoogleFonts.comfortaa(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF191C1E),
                        ),
                      ),
                      Text(
                        '${_filteredProducts.length} Produk',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Product / Search Result List
          _filteredProducts.isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada produk ditemukan',
                          style: GoogleFonts.comfortaa(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF191C1E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Coba cari kata kunci lain seperti "E211", "Oat Milk", atau "Stevia"',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = _filteredProducts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GestureDetector(
                            onTap: () => _showProductDetail(product),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x06000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      product['category'] == 'Aditif & E-Code'
                                          ? Icons.science_rounded
                                          : Icons.fastfood_rounded,
                                      color: const Color(0xFF0F5132),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['brand'],
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF6D7A77),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          product['name'],
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF191C1E),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.security_rounded,
                                              size: 13,
                                              color: Color(0xFF0F5132),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              product['ecode'],
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF0F5132),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: product['safetyBg'],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          product['safetyStatus'],
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: product['safetyColor'],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${product['rating']}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF3D4947),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _filteredProducts.length,
                    ),
                  ),
                ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 30),
          ),
        ],
      ),
    );
  }
}
