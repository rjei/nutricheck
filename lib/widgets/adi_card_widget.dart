import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdiCardWidget extends StatelessWidget {
  const AdiCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ANALISIS KUMULATIF',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F5132),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Batas Harian (ADI)',
                    style: GoogleFonts.comfortaa(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1E7DD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 3, backgroundColor: Color(0xFF0F5132)),
                    const SizedBox(width: 4),
                    Text(
                      'Status Terjaga',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF0F5132),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            width: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: CircularProgressIndicator(
                    value: 0.42,
                    strokeWidth: 14,
                    strokeCap: StrokeCap.round,
                    backgroundColor: const Color(0xFFE9ECEF),
                    color: const Color(0xFF0F5132),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '42%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F5132),
                      ),
                    ),
                    Text(
                      'Batas Harian Terjaga',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F5132),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Beban toksin & aditif rendah',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4EA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0F5132)),
                const SizedBox(width: 6),
                Text(
                  'Zona Aman ADI (< 60% Toleransi)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF0F5132),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}