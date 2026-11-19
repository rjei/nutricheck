import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../data/models/product.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../services/profile_avatar_service.dart';
import '../widgets/app_header.dart';
import 'login_screen.dart';
import 'notification_screen.dart';
import 'product_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUpdatingAvatar = false;
  String? _localAvatarOverride;

  static const String _defaultAvatarUrl =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80';

  Future<void> _onEditAvatarTap() async {
    if (_isUpdatingAvatar) return;

    final user = AuthService().currentUser;
    final userId = user?.id ?? 'default_user';

    setState(() => _isUpdatingAvatar = true);

    try {
      final newPath = await ProfileAvatarService.pickAndSaveGalleryAvatar(
        userId: userId,
      );

      if (newPath == null || !mounted) return;

      _localAvatarOverride = newPath;

      if (user != null) {
        AuthService().updateProfile(
          fullName: user.fullName,
          email: user.email,
        );
      }

      if (!mounted) return;
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Foto profil berhasil diperbarui.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil atau menyimpan foto dari galeri.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAvatar = false);
      }
    }
  }

  void _openAllFavorites(BuildContext context, List<Product> favorites) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AllFavoritesScreen(favorites: favorites),
      ),
    );
  }

  void _openProductDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    final userName = user?.fullName ?? 'Pengguna NutriCheck';
    final userMembership = user?.membershipStatus ?? 'Member since 2026';
    final userLevel = user?.level ?? 1;
    final userScore = user?.nutritionScore ?? 85;
    final selectedConditions = (user?.selectedConditions ?? const <String>[])
        .where((c) => c.trim().isNotEmpty)
        .toList();

    final effectiveAvatarPath = _localAvatarOverride ?? user?.avatarUrl;
    final avatarProvider = ProfileAvatarService.resolveAvatarProvider(
      effectiveAvatarPath,
      fallbackUrl: _defaultAvatarUrl,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppHeader(
        onNotificationTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationScreen(),
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _onEditAvatarTap,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primarySurface,
                            backgroundImage: avatarProvider,
                            child: _isUpdatingAvatar
                                ? const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            )
                                : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 13,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userMembership,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
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
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Level $userLevel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Healthy Eater',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.primary,
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
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (selectedConditions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Tidak ada referensi diet dan alergi',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedConditions.map((cond) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          cond,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
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
                final previewItems = favorites.take(3).toList();

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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        InkWell(
                          onTap: () => _openAllFavorites(context, favorites),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Text(
                              'Lihat Semua',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (previewItems.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Belum ada produk favorit. Tekan ikon hati pada halaman detail produk untuk menyimpan.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: List.generate(previewItems.length, (index) {
                          final product = previewItems[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == previewItems.length - 1 ? 0 : 10,
                            ),
                            child: _FavoriteProductCard(
                              product: product,
                              onTap: () => _openProductDetail(context, product),
                            ),
                          );
                        }),
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
                color: AppColors.textPrimary,
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
                    titleColor: AppColors.textPrimary,
                    isLast: false,
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: 'Keamanan',
                    titleColor: AppColors.textPrimary,
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
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                            (route) => false,
                      );
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
            color: AppColors.textMuted,
            size: 20,
          ),
          onTap: onTap,
        ),
        if (!isLast)
          const Divider(
            height: 1,
            color: AppColors.border,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

class _FavoriteProductCard extends StatelessWidget {
  const _FavoriteProductCard({
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (product.brand != null && product.brand!.isNotEmpty) product.brand!,
      if (product.quantity != null && product.quantity!.isNotEmpty)
        product.quantity!,
    ].join(' • ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                product.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _FallbackBox(),
              )
                  : const _FallbackBox(),
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFDC2626),
              size: 20,
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackBox extends StatelessWidget {
  const _FallbackBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.fastfood_rounded,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }
}

class _AllFavoritesScreen extends StatelessWidget {
  const _AllFavoritesScreen({required this.favorites});

  final List<Product> favorites;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: const AppHeader(
        title: 'Semua Favorit',
        showBackButton: true,
        backgroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: FavoriteService.instance,
        builder: (context, _) {
          final items = FavoriteService.instance.favorites.isNotEmpty
              ? FavoriteService.instance.favorites
              : favorites;

          if (items.isEmpty) {
            return Center(
              child: Text(
                'Belum ada produk favorit.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = items[index];
              return _FavoriteProductCard(
                product: product,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}