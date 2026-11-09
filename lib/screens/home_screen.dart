import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/models/product.dart';
import '../models/home_dashboard_data.dart';
import '../services/home_data_service.dart';
import '../widgets/adi_card_widget.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_header.dart';
import '../widgets/dominant_component_widget.dart';
import '../widgets/recent_scan_widget.dart';
import 'activity_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';
import 'search_screen.dart';

/// Halaman Utama Nutricheck dengan Integrasi Data Dinamis
/// Merujuk persis pada spesifikasi desain target (Gambar 1).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final HomeDataService _dataService = HomeDataService.instance;

  void _onNavigationTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleRecentProductTap(RecentScanItem item) {
    // Navigasi ke detail produk saat riwayat scan diklik
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          product: Product.local(
            name: item.productName,
            brand: item.brand,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        showDefaultActions: true,
      ),
      body: ListenableBuilder(
        listenable: _dataService,
        builder: (context, _) {
          final dailyAdiSummary = _dataService.dailyAdiSummary;
          final weeklyPoints = _dataService.weeklyTrendPoints;
          final dominantComponents = _dataService.dominantComponents;
          final latestScan = _dataService.latestScanItem;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              // Simulasi refresh data dinamis
              await Future.delayed(const Duration(milliseconds: 600));
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Batas Harian ADI (Circular Progress) & Tren Toleransi (Line Chart fl_chart)
                  // Terintegrasi dalam Unified Card persis seperti Gambar 1
                  AdiCardWidget(
                    summary: dailyAdiSummary,
                    weeklyPoints: weeklyPoints,
                  ),

                  const SizedBox(height: 24),

                  // 2. Komponen Dominan (Dynamic ListView)
                  DominantComponentWidget(
                    items: dominantComponents,
                  ),

                  const SizedBox(height: 24),

                  // 3. Riwayat Pindai Terbaru (Bottom Section dengan Empty State)
                  RecentScanWidget(
                    recentItem: latestScan,
                    onSeeAllTap: () => _onNavigationTap(3), // Pindah ke tab Riwayat
                    onStartScanTap: () => _onNavigationTap(2), // Pindah ke tab Scan
                    onItemTap: _handleRecentProductTap,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage;
    switch (_currentIndex) {
      case 0:
        activePage = _buildHomeContent();
        break;
      case 1:
        activePage = const SearchScreen();
        break;
      case 2:
        activePage = const ScanScreen();
        break;
      case 3:
        activePage = const ActivityScreen();
        break;
      case 4:
        activePage = const ProfileScreen();
        break;
      default:
        activePage = _buildHomeContent();
    }

    return Scaffold(
      body: activePage,
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
        onTap: _onNavigationTap,
      ),
    );
  }
}
