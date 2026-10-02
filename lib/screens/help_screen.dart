import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/help_footer.dart';

class HelpItem {
  final String title;
  final String content;

  const HelpItem({
    required this.title,
    required this.content,
  });
}

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<HelpItem> _allHelpItems = const [
    HelpItem(
      title: 'Cara scan barcode & komposisi kemasan',
      content:
          'Arahkan kamera smartphone Anda ke barcode produk makanan kemasan atau ambil foto daftar komposisi bahan. NutriCheck akan secara otomatis membaca dan menganalisis kandungan zat aditif.',
    ),
    HelpItem(
      title: 'Arti batas harian ADI & indikator risiko',
      content:
          'ADI (Acceptable Daily Intake) adalah perkiraan jumlah zat aditif makanan yang dapat dikonsumsi setiap hari seumur hidup tanpa menimbulkan risiko kesehatan. Indikator warna hijau menandakan aman, kuning peringatan, dan merah mendekati/melebihi batas.',
    ),
    HelpItem(
      title: 'Sumber database pangan & verifikasi BPOM',
      content:
          'Data bahan aditif dan status keamanan produk pada NutriCheck disinkronkan langsung dengan database resmi BPOM RI serta pedoman standar kesehatan WHO / Codex Alimentarius.',
    ),
    HelpItem(
      title: 'Pengaturan alergen & profil kesehatan',
      content:
          'Anda dapat mengatur riwayat alergi dan sensitivitas bahan (seperti pengawet, pemanis buatan, pewarna sintetis) pada menu Profil. Aplikasi akan memberi peringatan otomatis jika produk mengandung bahan sensitif.',
    ),
    HelpItem(
      title: 'Privasi & keamanan data pengguna',
      content:
          'Data profil kesehatan dan riwayat pemindaian Anda disimpan secara aman dan terenkripsi. NutriCheck berkomitmen tidak pernah membagikan data pribadi pengguna kepada pihak ketiga.',
    ),
  ];

  List<HelpItem> _filteredItems = [];
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(_allHelpItems);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(_allHelpItems);
      } else {
        _filteredItems = _allHelpItems
            .where((item) =>
                item.title.toLowerCase().contains(query) ||
                item.content.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        showBackButton: true,
        backgroundColor: Colors.white,
        customRightWidget: _buildLaporanSayaBadge(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Subtitle
            Text(
              'Bagaimana kami dapat membantu mu?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Temukan jawaban seputar pemindaian bahan dan profil Anda.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.searchBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  icon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  hintText: 'Cari bantuan atau topik...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // FAQ Items
            if (_filteredItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    'Topik bantuan tidak ditemukan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredItems.length,
                separatorBuilder: (context, index) => const Divider(
                  color: AppColors.border,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  final isExpanded = _expandedIndex == index;

                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        key: Key('help_tile_$index'),
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _expandedIndex = expanded ? index : null;
                          });
                        },
                        tilePadding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 0,
                        ),
                        childrenPadding: const EdgeInsets.only(
                          left: 0,
                          right: 0,
                          bottom: 16,
                        ),
                        title: Text(
                          item.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        trailing: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.content,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),

            // Reusable Help Footer (No APK versioning)
            const HelpFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildLaporanSayaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.badgeBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 15,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            'Laporan Saya',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
