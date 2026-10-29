import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/risk_level_style.dart';
import '../data/datasources/product_data_source.dart';
import '../data/models/health_condition.dart';
import '../data/models/product.dart';
import '../data/models/product_analysis.dart';
import '../data/models/risk_level.dart';
import '../data/repositories/product_repository.dart';
import '../services/auth_service.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    this.repository,
  });

  /// Produk yang ditampilkan. Boleh berupa ringkasan hasil pencarian;
  /// komposisi lengkap diambil otomatis.
  final Product product;

  /// Untuk pengujian; default memakai [ProductRepository.instance].
  final ProductRepository? repository;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // Variabel diubah menjadi _isConsumed sesuai alur UX yang baru
  bool _isConsumed = false;

  late Product _product = widget.product;
  ProductAnalysis? _analysis;
  String? _error;

  ProductRepository get _repository =>
      widget.repository ?? ProductRepository.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _analysis = null;
    });
    try {
      final full = await _repository.ensureComplete(widget.product);
      final analysis = await _repository.analyze(full);
      if (!mounted) return;
      setState(() {
        _product = full;
        _analysis = analysis;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ProductSourceException
            ? e.message
            : 'Gagal memuat analisis produk.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis;

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
            _HeroProductCard(product: _product, analysis: analysis),
            const SizedBox(height: 16),
            if (_error != null)
              _ErrorCard(message: _error!, onRetry: _load)
            else if (analysis == null)
              const _LoadingCard()
            else ...[
              _SafetySummaryCard(analysis: analysis),
              const SizedBox(height: 16),
              _CompositionAnalysisCard(analysis: analysis),
              const SizedBox(height: 16),
              _HealthProfileCard(
                analysis: analysis,
                conditionLabels:
                    AuthService().currentUser?.selectedConditions ?? const [],
              ),
            ],
            const SizedBox(height: 16),
            const _SourceBanner(),
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

/// Tingkat kandungan gizi per 100 g (ambang "lampu lalu lintas" FSA UK).
enum _NutrientLevel { rendah, sedang, tinggi }

extension on _NutrientLevel {
  String get label => switch (this) {
        _NutrientLevel.rendah => 'Rendah',
        _NutrientLevel.sedang => 'Sedang',
        _NutrientLevel.tinggi => 'Tinggi',
      };

  Color get color => switch (this) {
        _NutrientLevel.rendah => AppColors.primaryAccent,
        _NutrientLevel.sedang => const Color(0xFFD97706),
        _NutrientLevel.tinggi => const Color(0xFFB91C1C),
      };
}

_NutrientLevel _sugarLevel(double gPer100) => gPer100 <= 5
    ? _NutrientLevel.rendah
    : (gPer100 > 22.5 ? _NutrientLevel.tinggi : _NutrientLevel.sedang);

/// Berdasarkan kadar garam (natrium x 2,5): rendah <= 0,3 g, tinggi > 1,5 g.
_NutrientLevel _sodiumLevel(double mgPer100) {
  final saltG = mgPer100 * 2.5 / 1000;
  return saltG <= 0.3
      ? _NutrientLevel.rendah
      : (saltG > 1.5 ? _NutrientLevel.tinggi : _NutrientLevel.sedang);
}

String _number(double? value, {int digits = 0}) =>
    value == null ? '–' : value.toStringAsFixed(digits);

class _HeroProductCard extends StatelessWidget {
  const _HeroProductCard({required this.product, required this.analysis});

  final Product product;
  final ProductAnalysis? analysis;

  @override
  Widget build(BuildContext context) {
    final nutrition = product.nutrition;
    final subtitle = [product.brand, product.quantity]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' • ');

    final sugar = nutrition.sugarsG;
    final sodium = nutrition.sodiumMg;
    final sugarLevel = sugar == null ? null : _sugarLevel(sugar);
    final sodiumLevel = sodium == null ? null : _sodiumLevel(sodium);

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
                      product.name,
                      style: _titleStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.sell_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(subtitle, style: _bodyStyle(color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusChip(risk: analysis?.overallRisk, loading: analysis == null),
            ],
          ),
          const SizedBox(height: 18),
          _ProductVisual(imageUrl: product.imageUrl, isBeverage: product.hasCategory('en:beverages')),
          const SizedBox(height: 18),

          // PERBAIKAN OVERFLOW: GridView diganti menjadi Row + Expanded
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Kalori',
                  value: _number(nutrition.energyKcal),
                  suffix: 'kkal / 100 g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Gula',
                  value: sugar == null ? '–' : '${_number(sugar, digits: 1)}g',
                  suffix: sugarLevel == null ? 'Data tidak ada' : '${sugarLevel.label} / 100 g',
                  accent: sugarLevel?.color ?? AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Natrium',
                  value: sodium == null ? '–' : '${_number(sodium)}mg',
                  suffix: sodiumLevel == null ? 'Data tidak ada' : '${sodiumLevel.label} / 100 g',
                  accent: sodiumLevel?.color ?? AppColors.textMuted,
                ),
              ),
            ],
          ),

          if (product.barcode.isNotEmpty) ...[
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
                  const Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Barcode • ${product.barcode}',
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
        ],
      ),
    );
  }
}

class _SafetySummaryCard extends StatelessWidget {
  const _SafetySummaryCard({required this.analysis});

  final ProductAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final nutrition = analysis.product.nutrition;
    final sugar = nutrition.sugarsG;
    final sodium = nutrition.sodiumMg;

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
                      'Ringkasan Keamanan',
                      style: _titleStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analisis Aditif',
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
                      text: analysis.hasIngredientData ? '${analysis.additives.length}' : '–',
                      style: _titleStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: analysis.overallRisk?.color ?? AppColors.textMuted,
                      ),
                    ),
                    TextSpan(
                      text: ' aditif',
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
          if (analysis.hasIngredientData) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (final level in RiskLevel.values) ...[
                  _RiskCount(level: level, count: analysis.countOf(level)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ],
          const SizedBox(height: 18),
          _ProgressDetailRow(
            label: 'Gula per 100 g (batas harian 50 g)',
            percent: sugar == null ? 0 : (sugar / 50).clamp(0.0, 1.0),
            valueText: sugar == null
                ? 'Data tidak tersedia'
                : '${(sugar / 50 * 100).round()}% / 50g maks',
            color: sugar == null ? AppColors.textMuted : _sugarLevel(sugar).color,
          ),
          const SizedBox(height: 12),
          _ProgressDetailRow(
            label: 'Natrium per 100 g (batas harian 2000 mg)',
            percent: sodium == null ? 0 : (sodium / 2000).clamp(0.0, 1.0),
            valueText: sodium == null
                ? 'Data tidak tersedia'
                : '${(sodium / 2000 * 100).round()}% / 2000mg maks',
            color: sodium == null ? AppColors.textMuted : _sodiumLevel(sodium).color,
          ),
        ],
      ),
    );
  }
}

class _RiskCount extends StatelessWidget {
  const _RiskCount({required this.level, required this.count});

  final RiskLevel level;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: level.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count ${level.label}',
        style: _titleStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: level.color,
        ),
      ),
    );
  }
}

class _CompositionAnalysisCard extends StatelessWidget {
  const _CompositionAnalysisCard({required this.analysis});

  final ProductAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final ingredients = analysis.product.ingredientsText?.trim() ?? '';

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Analisis Komposisi',
            trailingLabel: '${analysis.additives.length} Aditif',
          ),
          const SizedBox(height: 14),
          Text(
            ingredients.isNotEmpty
                ? ingredients
                : 'Data komposisi produk ini belum tersedia di Open Food Facts, '
                    'sehingga tingkat keamanannya belum dapat dinilai.',
            style: _bodyStyle(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          if (analysis.additives.isEmpty && analysis.hasIngredientData) ...[
            const SizedBox(height: 14),
            Text(
              'Tidak ada aditif yang dikenali dalam basis data NutriCheck. '
              'Basis data ini masih terbatas, jadi tetap periksa label kemasan.',
              style: _bodyStyle(color: AppColors.primary, fontWeight: FontWeight.w700, height: 1.45),
            ),
          ],
          for (final additive in analysis.additives) ...[
            const SizedBox(height: 10),
            _AdditiveTile(
              title: additive.displayName,
              subtitle: additive.adiMgPerKgBw == null
                  ? additive.summary
                  : '${additive.summary}\nADI: ${_trimNumber(additive.adiMgPerKgBw!)} mg/kg berat badan',
              badge: additive.bpomPermitted ? additive.riskLevel.label : 'Dilarang',
              badgeColor: additive.riskLevel.backgroundColor,
              badgeTextColor: additive.riskLevel.color,
              icon: additive.riskLevel.icon,
              iconColor: additive.riskLevel.color,
            ),
          ],
          if (analysis.unknownAdditiveCodes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Belum ada di basis data: ${analysis.unknownAdditiveCodes.join(', ')}',
              style: _bodyStyle(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  static String _trimNumber(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}

class _HealthProfileCard extends StatelessWidget {
  const _HealthProfileCard({
    required this.analysis,
    required this.conditionLabels,
  });

  final ProductAnalysis analysis;
  final List<String> conditionLabels;

  @override
  Widget build(BuildContext context) {
    final String? notice;
    if (conditionLabels.isEmpty) {
      notice = 'Lengkapi profil kesehatan Anda untuk mendapat peringatan alergi dan kondisi khusus.';
    } else if (!analysis.hasIngredientData) {
      notice = 'Kecocokan dengan profil Anda belum bisa diperiksa karena data komposisi tidak tersedia.';
    } else {
      notice = null;
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Profil Kesehatan Anda',
            icon: Icons.verified_user_rounded,
          ),
          const SizedBox(height: 14),
          if (notice != null)
            Text(notice, style: _bodyStyle(color: AppColors.textSecondary, height: 1.5))
          else
            for (final label in conditionLabels) ...[
              _buildTile(label),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _buildTile(String label) {
    final id = HealthCondition.byLabel(label)?.id;
    final warnings = id == null ? const <ConditionWarning>[] : analysis.warningsFor([id]);

    if (warnings.isEmpty) {
      return _ProfileMatchTile(label: label, detail: 'Tidak ada aditif pemicu terdeteksi');
    }
    return _ProfileMatchTile(
      label: label,
      detail: 'Mengandung ${warnings.first.additives.map((a) => a.displayName).join(', ')}',
      warning: true,
    );
  }
}

class _SourceBanner extends StatelessWidget {
  const _SourceBanner();

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
                  'SUMBER DATA',
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
                'Open Food Facts',
                style: _titleStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Data produk berasal dari Open Food Facts (lisensi ODbL), database terbuka '
                'hasil kontribusi komunitas, sehingga bisa belum lengkap atau belum terbarui. '
                'Basis data aditif NutriCheck masih terbatas. Informasi bersifat edukatif dan '
                'tidak menggantikan saran medis profesional.',
                style: _bodyStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text('Menganalisis komposisi...', style: _bodyStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: _bodyStyle(color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Coba Lagi',
              style: _titleStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
            ),
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
      width: double.infinity,
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
  const _StatusChip({required this.risk, required this.loading});

  final RiskLevel? risk;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final label = loading ? 'Memuat...' : (risk?.label ?? 'Data Terbatas');
    final background = risk?.backgroundColor ?? AppColors.badgeBackground;
    final color = risk?.color ?? AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: _titleStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: _titleStyle(
                fontSize: 20, // Ukuran teks value sedikit disesuaikan
                fontWeight: FontWeight.w800,
                color: accent,
              ),
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
    this.color = AppColors.primaryAccent,
  });

  final String label;
  final double percent;
  final String valueText;
  final Color color;

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
            valueColor: AlwaysStoppedAnimation(color),
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
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;
  final IconData icon;
  final Color iconColor;

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
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
  const _ProfileMatchTile({
    required this.label,
    required this.detail,
    this.warning = false,
  });

  final String label;
  final String detail;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final accent = warning ? const Color(0xFFB91C1C) : AppColors.primary;
    final surface = warning ? const Color(0xFFFEE2E2) : AppColors.primarySurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFF5F5) : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warning ? const Color(0xFFFECACA) : AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              warning ? Icons.priority_high_rounded : Icons.check_rounded,
              size: 14,
              color: accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: _titleStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: _bodyStyle(color: warning ? accent : AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({required this.imageUrl, required this.isBeverage});

  final String? imageUrl;
  final bool isBeverage;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Container(
          width: 120,
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            isBeverage ? Icons.local_drink_rounded : Icons.fastfood_rounded,
            size: 54,
            color: AppColors.primaryAccent,
          ),
        );

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
          child: imageUrl == null
              ? placeholder()
              : Image.network(
                  imageUrl!,
                  width: 120,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => placeholder(),
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
