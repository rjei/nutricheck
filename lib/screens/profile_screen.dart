import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/routes.dart';
import '../data/models/product.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../widgets/app_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _defaultAvatar =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80';

  final ImagePicker _imagePicker = ImagePicker();
  bool _showAllFavorites = false;

  @override
  void initState() {
    super.initState();
    FavoriteService.instance.initialize();
  }

  ImageProvider<Object>? _avatarImageProvider(String source) {
    final clean = source.trim();
    if (clean.isEmpty) return null;
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return NetworkImage(clean);
    }
    final file = File(clean);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

  Future<void> _pickProfileImageFromGallery() async {
    const primaryGreen = Color(0xFF0F5132);

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (picked == null || !mounted) return;

      final activeUser = AuthService().currentUser;
      if (activeUser != null) {
        AuthService().updateProfile(
          fullName: activeUser.fullName,
          email: activeUser.email,
          avatarUrl: picked.path,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Foto profil berhasil diperbarui.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12),
          ),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak dapat membuka galeri perangkat.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12),
          ),
          backgroundColor: const Color(0xFFD9383A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F5132);

    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final user = AuthService().currentUser;

        final userName = user?.fullName ?? 'Pengguna';
        final userMembership = user?.email ?? '';
        const userLevel = 1;
        const userScore = 85;
        final userAvatar = user?.avatarUrl ?? _defaultAvatar;
        final avatarProvider = _avatarImageProvider(userAvatar);
        final selectedConditions = user?.selectedConditions ??
            ['Bebas Gluten', 'Intoleransi Sulfite'];

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FB),
          appBar: AppHeader(
            onNotificationTap: () => AppRoutes.pushNotifications(context),
          ),
          body: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                      GestureDetector(
                        onTap: _pickProfileImageFromGallery,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: primaryGreen,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: const Color(0xFFE8F4EA),
                                backgroundImage: avatarProvider,
                                onBackgroundImageError: (_, __) {},
                                child: avatarProvider == null
                                    ? const Icon(
                                  Icons.person_rounded,
                                  color: primaryGreen,
                                  size: 34,
                                )
                                    : null,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: primaryGreen,
                                shape: BoxShape.circle,
                                border:
                                Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        userName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userMembership,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4EA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Level $userLevel',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                                Text(
                                  'Healthy Eater',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3D6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$userScore% Nutrition',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF9A6B00),
                                  ),
                                ),
                                Text(
                                  'Score',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF9A6B00),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Preferensi Diet & Alergi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedConditions.map((cond) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4EA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryGreen, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: primaryGreen, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            cond,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                ListenableBuilder(
                  listenable: FavoriteService.instance,
                  builder: (context, _) {
                    final favorites = FavoriteService.instance.favorites;
                    final hasMoreThanThree = favorites.length > 3;
                    final displayedFavorites = _showAllFavorites
                        ? favorites
                        : favorites.take(3).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Riwayat Favorit',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (hasMoreThanThree)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showAllFavorites = !_showAllFavorites;
                                  });
                                },
                                child: Text(
                                  _showAllFavorites
                                      ? 'Tampilkan Sedikit'
                                      : 'Lihat Semua',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryGreen,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: displayedFavorites.isEmpty
                              ? Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'Belum ada produk favorit. Tekan ikon hati di halaman detail produk untuk menyimpannya.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          )
                              : Column(
                            children: List.generate(
                              displayedFavorites.length,
                                  (index) {
                                final product = displayedFavorites[index];
                                return _buildFavoriteItem(
                                  product: product,
                                  isLast: index ==
                                      displayedFavorites.length - 1,
                                  onTap: () => AppRoutes.pushProductDetail(
                                    context,
                                    product: product,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Pengaturan Akun',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifikasi',
                        titleColor: Colors.black87,
                        isLast: false,
                        onTap: () => AppRoutes.pushNotifications(context),
                      ),
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.shield_outlined,
                        title: 'Keamanan',
                        titleColor: Colors.black87,
                        isLast: false,
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.logout_rounded,
                        title: 'Keluar',
                        titleColor: const Color(0xFFD9383A),
                        isLast: true,
                        onTap: () {
                          AuthService().logout();
                          AppRoutes.pushLogin(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoriteItem({
    required Product product,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    const primaryGreen = Color(0xFF0F5132);
    final infoParts = [
      if (product.brand != null && product.brand!.trim().isNotEmpty)
        product.brand!.trim(),
      if (product.nutrition.energyKcal != null)
        '${product.nutrition.energyKcal!.toStringAsFixed(0)} kkal',
      if (product.barcode.trim().isNotEmpty) product.barcode.trim(),
    ];
    final subtitle =
    infoParts.isEmpty ? 'Produk tersimpan' : infoParts.join(' • ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: product.imageUrl != null &&
                      product.imageUrl!.trim().isNotEmpty
                      ? Image.network(
                    product.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 48,
                        height: 48,
                        color: const Color(0xFFE8F4EA),
                        child: const Icon(Icons.restaurant,
                            color: primaryGreen, size: 24),
                      );
                    },
                  )
                      : Container(
                    width: 48,
                    height: 48,
                    color: const Color(0xFFE8F4EA),
                    child: const Icon(Icons.restaurant,
                        color: primaryGreen, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.favorite_rounded,
                  color: primaryGreen,
                  size: 20,
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              color: Colors.grey[100],
              indent: 12,
              endIndent: 12,
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color titleColor,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(icon, color: titleColor, size: 22),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          trailing: titleColor == const Color(0xFFD9383A)
              ? null
              : const Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey,
            size: 20,
          ),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: Colors.grey[100],
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}