import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart'; // 1. Import paket flutter_svg
import 'home_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final isLoggedIn = AuthService().isLoggedIn;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => isLoggedIn ? const HomeScreen() : const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Column(
                children: [
                  // 2. Ganti ke SvgPicture.asset
                  SvgPicture.asset(
                    'assets/images/logo.svg', // Path file logo.svg kamu
                    width: 120,
                    height: 120,
                    // Opsional: jika mau ubah warna logo SVG lewat kode
                    // colorFilter: const ColorFilter.mode(Color(0xFF0F5132), BlendMode.srcIn),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'nutricheck',
                    style: GoogleFonts.comfortaa(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F5132),
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                'by nutri co.',
                style: GoogleFonts.comfortaa(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}