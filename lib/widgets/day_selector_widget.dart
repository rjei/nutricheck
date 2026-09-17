import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DaySelectorWidget extends StatelessWidget {
  const DaySelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDayItem('Sen', isSelected: false),
          _buildDayItem('Sel', isSelected: false),
          _buildDayItem('Rab', isSelected: false),
          _buildDayItem('Kam', isSelected: false),
          _buildDayItem('Jum', isSelected: false),
          _buildDayItem('Sab', isSelected: false),
          _buildDayItem('Min', isSelected: true),
        ],
      ),
    );
  }

  Widget _buildDayItem(String day, {required bool isSelected}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          day,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F5132) : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 4),
        // Indicator dot untuk hari aktif (Min)
        if (isSelected)
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF0F5132),
              shape: BoxShape.circle,
            ),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }
}