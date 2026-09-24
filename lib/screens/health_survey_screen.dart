import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class HealthSurveyScreen extends StatefulWidget {
  const HealthSurveyScreen({super.key});

  @override
  State<HealthSurveyScreen> createState() => _HealthSurveyScreenState();
}

class _HealthSurveyScreenState extends State<HealthSurveyScreen> {
  final _authService = AuthService();

  // Multi-select allergy & health condition chips
  final List<String> _availableConditions = [
    'Intoleransi Sulfite / Pengawet',
    'Alergi Kacang & Kedelai',
    'Hipertensi / Sensitif Garam',
    'Intoleransi Laktosa',
    'Diabetes / Batasi Gula',
    'Riwayat Asma',
  ];

  late Set<String> _selectedConditions;
  String _selectedGoal = 'Deteksi Bahan Berbahaya & ADI';

  @override
  void initState() {
    super.initState();
    // Default selected conditions from active user or initial survey
    final user = _authService.currentUser;
    _selectedConditions = user != null && user.selectedConditions.isNotEmpty
        ? Set.from(user.selectedConditions)
        : {'Intoleransi Sulfite / Pengawet', 'Alergi Kacang & Kedelai', 'Riwayat Asma'};

    if (user != null) {
      _selectedGoal = user.primaryGoal;
    }
  }

  void _handleSaveAndContinue() {
    _authService.updateHealthSurvey(
      conditions: _selectedConditions.toList(),
      primaryGoal: _selectedGoal,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F5132);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F4F8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    'LANGKAH 1 DARI 3',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 1.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleSaveAndContinue,
                    child: Text(
                      'Lewati',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress Bar Line (33%)
            Container(
              width: double.infinity,
              height: 4,
              color: const Color(0xFFF0F4F8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.33,
                  height: 4,
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Main Body Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge: Profil Kesehatan Aman
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4EA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded, color: primaryGreen, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Profil Kesehatan Aman',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Main Title
                    Text(
                      'Personalisasi Profil Sehat Anda',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bantu Nutricheck menyaring bahan pangan & aditif yang aman untuk tubuh Anda.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Section 1: Pilih Kondisi atau Alergi Utama
                    Text(
                      'Pilih Kondisi atau Alergi Utama Anda',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bisa pilih lebih dari satu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Wrap Chips
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _availableConditions.map((condition) {
                        final isSelected = _selectedConditions.contains(condition);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedConditions.remove(condition);
                              } else {
                                _selectedConditions.add(condition);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE8F4EA) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? primaryGreen : Colors.grey[300]!,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  size: 16,
                                  color: isSelected ? primaryGreen : Colors.grey[400],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  condition,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? primaryGreen : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // Section 2: Tujuan Utama Penggunaan
                    Text(
                      'Tujuan Utama Penggunaan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pilih salah satu prioritas terbesar Anda saat ini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Goal Card 1: Deteksi Bahan Berbahaya & ADI
                    _buildGoalCard(
                      title: 'Deteksi Bahan Berbahaya & ADI',
                      subtitle: 'Waspadai bahan pewarna, pemanis & aditif berlebih',
                      icon: Icons.shield_outlined,
                      isSelected: _selectedGoal == 'Deteksi Bahan Berbahaya & ADI',
                      onTap: () {
                        setState(() {
                          _selectedGoal = 'Deteksi Bahan Berbahaya & ADI';
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Goal Card 2: Pantau Diet & Nutrisi Harian
                    _buildGoalCard(
                      title: 'Pantau Diet & Nutrisi Harian',
                      subtitle: 'Cek kalori, sodium & takaran gizi real-time',
                      icon: Icons.insert_chart_outlined_rounded,
                      isSelected: _selectedGoal == 'Pantau Diet & Nutrisi Harian',
                      onTap: () {
                        setState(() {
                          _selectedGoal = 'Pantau Diet & Nutrisi Harian';
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    // Bottom Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleSaveAndContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          elevation: 2,
                          shadowColor: primaryGreen.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Simpan & Lanjutkan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const primaryGreen = Color(0xFF0F5132);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F4EA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? primaryGreen : const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryGreen : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isSelected ? primaryGreen.withValues(alpha: 0.8) : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? primaryGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryGreen : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.check,
                size: 14,
                color: isSelected ? Colors.white : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
