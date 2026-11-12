import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/home_dashboard_data.dart';
import '../services/home_data_service.dart';

/// Widget daftar dinamis Komponen Dominan (Natrium, Gula Bebas, Pengawet, dll)
/// sesuai dengan tampilan Gambar 1.
class DominantComponentWidget extends StatelessWidget {
  final List<DominantComponentItem>? items;

  const DominantComponentWidget({
    super.key,
    this.items,
  });

  @override
  Widget build(BuildContext context) {
    final componentItems =
        items ?? HomeDataService.instance.dominantComponents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Komponen Dominan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Standar BPOM',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Dynamic List of Dominant Components
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: componentItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = componentItems[index];
            return _buildComponentCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildComponentCard(DominantComponentItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Kategori dengan soft background
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.iconBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: item.iconColor,
            ),
          ),

          const SizedBox(width: 14),

          // Nama Komponen, Titik Indikator, & Subtitle Deskripsi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: item.status.dotColor,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Persentase & Badge Status Warna (Aman = Hijau, Stabil = Oranye, Sangat Rendah = Hijau Muda)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.percentage.toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.status.label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: item.status.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
