import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const NutriCheckApp());
}

class NutriCheckApp extends StatelessWidget {
  const NutriCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NutriCheck',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: authService.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
