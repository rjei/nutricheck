import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../data/models/product_analysis.dart';
import '../screens/ai_chat_screen.dart';

/// Tombol floating NutriAI yang dapat diakses kapan saja untuk bertanya
/// seputar zat aditif atau mencari alternatif produk yang lebih sehat.
class AiFloatingButton extends StatelessWidget {
  const AiFloatingButton({
    super.key,
    this.productAnalysis,
    this.label = 'Tanya AI',
  });

  final ProductAnalysis? productAnalysis;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: null,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      tooltip: 'Tanya NutriAI seputar zat aditif & alternatif sehat',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AiChatScreen(
              initialProductContext: productAnalysis,
            ),
          ),
        );
      },
    );
  }
}
