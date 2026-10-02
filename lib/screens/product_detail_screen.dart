import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State {
  // Variabel diubah menjadi _isConsumed sesuai alur UX yang baru
  bool _isConsumed = false;

  static const String _productName = 'Pocari Sweat 500ml';
  static const String _scanInfo = '10:45 • Supermarket Menteng';
  static const String _verificationNumber = 'MD 123456789012';
  static const String _imageUrl =
      'https://images.unsplash.com/photo-1581636625402-29b2a704ef13?auto=format&fit=crop&w=900&q=80';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Kembali',
        ),
        title: Text(
          'Detail Produk',
          style: _titleStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Ikon bookmark dan profil AI dihapus, hanya menyisakan tombol Share
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.ios_share_rounded, color: AppColors.textSecondary),
            tooltip: 'Bagikan',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _HeroProductCard(
              productName: _productName,
              scanInfo: _scanInfo,
              imageUrl: _imageUrl,
              verificationNumber: _verificationNumber,
            ),
            const SizedBox(height: 16),
            const _SafetyScoreCard(),
            const SizedBox(height: 16),
            const _CompositionAnalysisCard(),
            const SizedBox(height: 16),
            const _HealthProfileCard(),
            const SizedBox(height: 16),
            const _NutritionInsightBanner(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                // Tombol diubah menjadi ElevatedButton.icon untuk Status Konsumsi
                child: ElevatedButton.icon(
                  onPressed: _toggleConsumed,
                  icon: Icon(
                    _isConsumed ? Icons.check_circle_rounded : Icons.restaurant_rounded,
                    size: 20,
                  ),
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      _isConsumed ? 'Sudah Dikonsumsi' : 'Tandai Dikonsumsi',
                      key: ValueKey(_isConsumed),
                      style: _titleStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.search_rounded, size: 20),
                  label: Text(
                    'Cari Alternatif Lebih Sehat',
                    style: _titleStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleConsumed() {
    setState(() {
      _isConsumed = !_isConsumed;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isConsumed
              ? 'Produk ditandai sebagai telah dikonsumsi.'
              : 'Status dikonsumsi dibatalkan.',
          style: _bodyStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _HeroProductCard extends StatelessWidget {
  const _HeroProductCard({
    required this.productName,
    required this.scanInfo,
    required this.imageUrl,
    required this.verificationNumber,
  });

  final String productName;
  final String scanInfo;
  final String imageUrl;
  final String verificationNumber;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: _titleStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(scanInfo, style: _bodyStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const _StatusChip(label: 'Aman'),
            ],
          ),
          const SizedBox(height: 18),
          _ProductVisual(imageUrl: imageUrl),
          const SizedBox(height: 18),

          // PERBAIKAN OVERFLOW: GridView diganti menjadi Row + Expanded
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Kalori',
                  value: '120',
                  suffix: 'kkal',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Gula',
                  value: '4g',
                  suffix: 'Rendah (8% AKG)',
                  accent: AppColors.primaryAccent,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Elektrolit',
                  value: '45mg',
                  suffix: 'Ion Natrium',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Terverifikasi BPOM RI • $verificationNumber',
                    style: _bodyStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyScoreCard extends StatelessWidget {
  const _SafetyScoreCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skor Keamanan',
                      style: _titleStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nutricheck Index',
                      style: _titleStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '92',
                      style: _titleStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: ' /100',
                      style: _titleStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _ProgressDetailRow(
            label: 'Batas Gula Harian (AKG)',
            percent: 0.08,
            valueText: '8% / 50g maks',
          ),
          const SizedBox(height: 12),
          const _ProgressDetailRow(
            label: 'Batas Natrium Harian (AKG)',
            percent: 0.03,
            valueText: '3% / 2000mg maks',
          ),
        ],
      ),
    );
  }
}

class _CompositionAnalysisCard extends StatelessWidget {
  const _CompositionAnalysisCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Analisis Komposisi',
            trailingLabel: '6 Bahan Utama',
          ),
          const SizedBox(height: 14),
          Text(
            'Air, gula, sitrus flavor, pengatur keasaman (asam sitrat), '
                'garam natrium klorida, kalium klorida, serta mineral elektrolit '
                'yang membantu menjaga hidrasi saat aktivitas.',
            style: _bodyStyle(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          const _AdditiveTile(
            title: 'Pengatur Keasaman (INS 330)',
            subtitle: 'Asam sitrat alami untuk menyeimbangkan rasa.',
            badge: 'Aman',
            badgeColor: AppColors.primarySurface,
            badgeTextColor: AppColors.primary,
            icon: Icons.science_rounded,
          ),
          const SizedBox(height: 10),
          const _AdditiveTile(
            title: 'Pengawet Kimia Sintetis',
            subtitle: 'Sterilitas didukung proses aseptik pabrik.',
            badge: 'Bebas Pengawet',
            badgeColor: Color(0xFFEAF7EF),
            badgeTextColor: AppColors.primaryAccent,
            icon: Icons.health_and_safety_rounded,
          ),
          const SizedBox(height: 10),
          const _AdditiveTile(
            title: 'Pemanis Buatan (Aspartam / Sukralosa)',
            subtitle: 'Menggunakan gula dan elektrolit sebagai sumber energi.',
            badge: 'Nol Buatan',
            badgeColor: Color(0xFFF1F5F9),
            badgeTextColor: AppColors.textSecondary,
            icon: Icons.no_food_rounded,
          ),
        ],
      ),
    );
  }
}

class _HealthProfileCard extends StatelessWidget {
  const _HealthProfileCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Profil Kesehatan Anda',
            icon: Icons.verified_user_rounded,
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.9,
            children: const [
              _ProfileMatchTile(label: 'Bebas Gluten'),
              _ProfileMatchTile(label: 'Bebas Laktosa'),
              _ProfileMatchTile(label: 'Ramah Asma'),
              _ProfileMatchTile(label: 'Ramah Ginjal Ringan'),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionInsightBanner extends StatelessWidget {
  const _NutritionInsightBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -18,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'INSIGHT NUTRISI',
                  style: _titleStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Pilihan Hidrasi Optimal',
                style: _titleStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sangat cocok dikonsumsi setelah aktivitas atau berolahraga. Kandungan ion seimbang membantu cairan tubuh lebih cepat kembali stabil.',
                style: _bodyStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  'Lihat Panduan Elektrolit',
                  style: _titleStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailingLabel,
    this.icon,
  });

  final String title;
  final String? trailingLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: _titleStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailingLabel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trailingLabel!,
              style: _titleStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: _titleStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryAccent,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.suffix,
    this.accent = AppColors.primary,
  });

  final String label;
  final String value;
  final String suffix;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding dikurangi sedikit agar teks panjang muat
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: _titleStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: _titleStyle(
              fontSize: 20, // Ukuran teks value sedikit disesuaikan
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            suffix,
            textAlign: TextAlign.center,
            maxLines: 2, // Mencegah overflow dengan membatasi baris
            overflow: TextOverflow.ellipsis,
            style: _titleStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDetailRow extends StatelessWidget {
  const _ProgressDetailRow({
    required this.label,
    required this.percent,
    required this.valueText,
  });

  final String label;
  final double percent;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: _titleStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              valueText,
              style: _titleStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryAccent),
          ),
        ),
      ],
    );
  }
}

class _AdditiveTile extends StatelessWidget {
  const _AdditiveTile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _titleStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: _bodyStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: _titleStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMatchTile extends StatelessWidget {
  const _ProfileMatchTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: _titleStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.searchBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            imageUrl,
            width: 120,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                width: 120,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.local_drink_rounded,
                  size: 54,
                  color: AppColors.primaryAccent,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

TextStyle _titleStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w600,
  Color color = AppColors.textPrimary,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle _bodyStyle({
  Color color = AppColors.textSecondary,
  double fontSize = 13,
  FontWeight fontWeight = FontWeight.w500,
  double? height,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}