import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchFilterPanel extends StatelessWidget {
  const SearchFilterPanel({
    super.key,
    required this.selectedNutriScore,
    required this.selectedNutritionFilter,
    required this.onNutriScoreSelected,
    required this.onNutritionSelected,
    required this.onReset,
  });

  final String? selectedNutriScore;
  final String? selectedNutritionFilter;
  final ValueChanged<String?> onNutriScoreSelected;
  final ValueChanged<String?> onNutritionSelected;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutri-Score Grade',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F5132),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['a', 'b', 'c', 'd', 'e'].map((grade) {
              final isSelected = selectedNutriScore == grade;
              return ChoiceChip(
                // Label tampil bersih tanpa ikon centang (✓)
                label: Text(grade.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  onNutriScoreSelected(selected ? grade : null);
                },
                // Warna latar belakang saat aktif menjadi hijau penuh
                selectedColor: const Color(0xFF0F5132),
                backgroundColor: Colors.grey.shade100,
                showCheckmark: false, // Menghilangkan ikon centang bawaan Flutter
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Kandungan Nutrisi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F5132),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Gula Tinggi', 'Natrium Tinggi'].map((nutri) {
              final isSelected = selectedNutritionFilter == nutri;
              return ChoiceChip(
                label: Text(nutri),
                selected: isSelected,
                onSelected: (selected) {
                  onNutritionSelected(selected ? nutri : null);
                },
                selectedColor: const Color(0xFF0F5132),
                backgroundColor: Colors.grey.shade100,
                showCheckmark: false, // Menghilangkan ikon centang bawaan Flutter
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onReset,
                child: Text(
                  'RESET FILTERS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}