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

  static const List<String> _nutriScores = ['a', 'b', 'c', 'd', 'e'];
  static const List<String> _nutritionFilters = [
    'Gula Tinggi',
    'Natrium Tinggi',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Lanjutan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF191C1E),
                ),
              ),
              TextButton(
                onPressed: onReset,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Reset',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F5132),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Nutri-Score',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D4947),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _nutriScores.map((grade) {
              final isSelected = selectedNutriScore == grade;
              return ChoiceChip(
                label: Text(
                  grade.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF191C1E),
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF0F5132),
                backgroundColor: const Color(0xFFF7F9FB),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0F5132)
                      : const Color(0xFFE2E8F0),
                ),
                onSelected: (_) {
                  onNutriScoreSelected(isSelected ? null : grade);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Kandungan Gizi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D4947),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _nutritionFilters.map((label) {
              final isSelected = selectedNutritionFilter == label;
              return ChoiceChip(
                label: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF191C1E),
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF0F5132),
                backgroundColor: const Color(0xFFF7F9FB),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0F5132)
                      : const Color(0xFFE2E8F0),
                ),
                onSelected: (_) {
                  onNutritionSelected(isSelected ? null : label);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}