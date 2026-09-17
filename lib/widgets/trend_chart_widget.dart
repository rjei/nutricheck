import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'day_selector_widget.dart'; // Import day selector

class TrendChartWidget extends StatelessWidget {
  const TrendChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tren Toleransi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            DropdownButton<String>(
              value: 'Minggu ini',
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: [
                DropdownMenuItem(
                  value: 'Minggu ini',
                  child: Text(
                    'Minggu ini',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[700]),
                  ),
                )
              ],
              onChanged: (_) {},
            )
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: const [
              Expanded(
                child: Center(
                  child: Icon(Icons.show_chart_rounded, color: Color(0xFF0F5132), size: 48),
                ),
              ),
              DaySelectorWidget(), // Panggil widget di sini
            ],
          ),
        ),
      ],
    );
  }
}