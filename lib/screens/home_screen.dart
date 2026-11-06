import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/adi_card_widget.dart';
import '../widgets/trend_chart_widget.dart';
import '../widgets/dominant_component_widget.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'scan_screen.dart';
import 'activity_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = {0};

  Widget _buildHomeContent() {
    return Scaffold(
      appBar: const AppHeader(
        showDefaultActions: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            AdiCardWidget(),
            SizedBox(height: 20),
            TrendChartWidget(),
            SizedBox(height: 20),
            DominantComponentWidget(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loadedTabs.add(_currentIndex);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          _loadedTabs.contains(1) ? const SearchScreen() : const SizedBox.shrink(),
          _currentIndex == 2 ? const ScanScreen() : const SizedBox.shrink(),
          _loadedTabs.contains(3) ? const ActivityScreen() : const SizedBox.shrink(),
          _loadedTabs.contains(4) ? const ProfileScreen() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}