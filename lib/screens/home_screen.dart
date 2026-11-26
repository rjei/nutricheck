import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/routes.dart';
import '../data/models/product.dart';
import '../models/home_dashboard_data.dart';
import '../services/home_data_service.dart';
import '../widgets/adi_card_widget.dart';
import '../widgets/ai_floating_button.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_header.dart';
import '../widgets/dominant_component_widget.dart';
import '../widgets/recent_scan_widget.dart';
import 'activity_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;
  final HomeDataService _dataService = HomeDataService.instance;

  late final Widget _homeTab = _buildHomeContent();
  late final Widget _searchTab = const SearchScreen();
  late final Widget _scanTab = const ScanScreen();
  late final Widget _activityTab = const ActivityScreen();
  late final Widget _profileTab = const ProfileScreen();

  void _onNavigationTap(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  void _handleRecentProductTap(RecentScanItem item) {
    AppRoutes.pushProductDetail(
      context,
      product: Product.local(
        name: item.productName,
        brand: item.brand,
      ),
    );
  }

  Widget _buildTabPage(int index) {
    switch (index) {
      case 0:
        return _homeTab;
      case 1:
        return _searchTab;
      case 2:
        return _scanTab;
      case 3:
        return _activityTab;
      case 4:
        return _profileTab;
      default:
        return _homeTab;
    }
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        const AppHeader(
          showDefaultActions: true,
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _dataService,
            builder: (context, _) {
              final dailyAdiSummary = _dataService.dailyAdiSummary;
              final weeklyPoints = _dataService.weeklyTrendPoints;
              final dominantComponents = _dataService.dominantComponents;
              final latestScan = _dataService.latestScanItem;

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdiCardWidget(
                        summary: dailyAdiSummary,
                        weeklyPoints: weeklyPoints,
                      ),
                      const SizedBox(height: 24),
                      DominantComponentWidget(
                        items: dominantComponents,
                      ),
                      const SizedBox(height: 24),
                      RecentScanWidget(
                        recentItem: latestScan,
                        onSeeAllTap: () => _onNavigationTap(3),
                        onStartScanTap: () => _onNavigationTap(2),
                        onItemTap: _handleRecentProductTap,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMovingBackward = _currentIndex < _previousIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 360),
        reverse: isMovingBackward,
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          final curvedPrimary = CurvedAnimation(
            parent: primaryAnimation,
            curve: Curves.easeInOutCubic,
          );
          final curvedSecondary = CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeInOutCubic,
          );

          return SharedAxisTransition(
            animation: curvedPrimary,
            secondaryAnimation: curvedSecondary,
            transitionType: SharedAxisTransitionType.horizontal,
            fillColor: AppColors.background,
            child: child,
          );
        },
        child: RepaintBoundary(
          key: ValueKey<int>(_currentIndex),
          child: _buildTabPage(_currentIndex),
        ),
      ),
      floatingActionButton: _currentIndex == 2
          ? null
          : Theme(
        data: Theme.of(context).copyWith(
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 0,
            highlightElevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
        child: const AiFloatingButton(),
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
        onTap: _onNavigationTap,
      ),
    );
  }
}