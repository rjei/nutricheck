import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Semua', 'Peringatan ADI', 'Hasil Scan', 'Tips Nutrisi'];

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Batas ADI Mendekati 50%',
      'message': 'Konsumsi natrium Anda hari ini telah mencapai 42% dari Batas Harian (ADI). Tetap jaga pola makan Anda.',
      'time': '10 mnt yang lalu',
      'isUnread': true,
      'category': 'Peringatan ADI',
      'icon': Icons.warning_amber_rounded,
      'iconColor': Color(0xFFD97706),
      'iconBg': Color(0xFFFEF3C7),
    },
    {
      'id': 2,
      'title': 'Hasil Scan: Green Revitalize Bowl',
      'message': 'Produk ini terverifikasi bebas bahan pengawet sintetis & aman untuk batas toleransi harian.',
      'time': '2 jam yang lalu',
      'isUnread': true,
      'category': 'Hasil Scan',
      'icon': Icons.check_circle_outline_rounded,
      'iconColor': Color(0xFF0F5132),
      'iconBg': Color(0xFFD1E7DD),
    },
    {
      'id': 3,
      'title': 'Tips Nutrisi Harian',
      'message': 'Perbanyak konsumsi air putih untuk membantu proses metabolisme zat aditif dalam tubuh.',
      'time': 'Kemarin',
      'isUnread': false,
      'category': 'Tips Nutrisi',
      'icon': Icons.lightbulb_outline_rounded,
      'iconColor': Color(0xFF2563EB),
      'iconBg': Color(0xFFDBEAFE),
    },
    {
      'id': 4,
      'title': 'Pembaruan Standar BPOM 2026',
      'message': 'Daftar batas maksimum Toleransi Bahan Tambahan Pangan (BTP) telah diperbarui dalam sistem.',
      'time': '3 hari yang lalu',
      'isUnread': false,
      'category': 'Semua',
      'icon': Icons.info_outline_rounded,
      'iconColor': Color(0xFF6B7280),
      'iconBg': Color(0xFFF3F4F6),
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['isUnread'] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Semua notifikasi telah ditandai dibaca',
          style: GoogleFonts.plusJakartaSans(fontSize: 12),
        ),
        backgroundColor: const Color(0xFF0F5132),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F5132);

    List<Map<String, dynamic>> filteredList = _notifications.where((n) {
      if (_selectedFilterIndex == 0) return true;
      return n['category'] == _filters[_selectedFilterIndex];
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.comfortaa(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Tandai Dibaca',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryGreen,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        }
                      },
                      selectedColor: primaryGreen,
                      backgroundColor: const Color(0xFFF0F4F8),
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide.none,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Notification List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada notifikasi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final bool isUnread = item['isUnread'] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isUnread ? const Color(0xFFF0F7F2) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isUnread
                              ? Border.all(color: primaryGreen.withValues(alpha: 0.3), width: 1)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon Avatar
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item['iconBg'],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item['icon'],
                                color: item['iconColor'],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Title & Message Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['title'],
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isUnread)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(left: 6),
                                          decoration: const BoxDecoration(
                                            color: primaryGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['message'],
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['time'],
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
