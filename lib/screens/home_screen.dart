import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/adi_card_widget.dart';
import '../widgets/trend_chart_widget.dart';
import '../widgets/dominant_component_widget.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Widget _buildHomeContent() {
    return Scaffold(
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
            onPressed: () {},
          ),
        ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderContent(String title) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.comfortaa(
            color: const Color(0xFF0F5132),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
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
      case 3:
        activePage = const ProfileScreen();
        break;
      case 4:
        activePage = _buildPlaceholderContent('Aktivitas');
        break;
      default:
        activePage = _buildHomeContent();
    }

    return Scaffold(
      body: activePage,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF0F5132),
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Cari'),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFF0F5132),
              child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
            ),
            label: 'Scan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Aktivitas'),
        ],
      ),
    );
  }
}