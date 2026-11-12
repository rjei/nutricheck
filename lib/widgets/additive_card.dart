import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/risk_level_style.dart';
import '../data/models/additive.dart';

class AdditiveCard extends StatelessWidget {
  const AdditiveCard({
    super.key,
    required this.additive,
    required this.onTap,
  });

  final Additive additive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final risk = additive.riskLevel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: risk.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.science_rounded, color: risk.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      additive.category.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6D7A77),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      additive.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF191C1E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: risk.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  additive.bpomPermitted ? risk.label : 'Dilarang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: risk.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}