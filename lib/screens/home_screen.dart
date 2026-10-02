import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/app_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/adi_card_widget.dart';
import '../widgets/trend_chart_widget.dart';
import '../widgets/dominant_component_widget.dart';
import 'activity_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    if (index == 3) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ActivityScreen(),
          transitionDuration: Duration.zero,
        ),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Widget _buildHomeContent() {
    return Scaffold(
      appBar: AppHeader(
        showDefaultActions: true,
        onNotificationTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationScreen()),
          );
        },
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

  Widget _buildPlaceholderContent(String title) {
    return Scaffold(
      appBar: AppHeader(title: title),
      body: Center(
        child: Text(
          'Halaman $title dalam pengembangan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
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
        activePage = _buildPlaceholderContent('Cari');
        break;
      case 2:
        activePage = _buildPlaceholderContent('Scan');
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
        onTap: _onTabTapped,
      ),
    );
  }
}
