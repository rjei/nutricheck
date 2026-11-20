import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/risk_level_style.dart';
import '../data/datasources/product_data_source.dart';
import '../data/models/product.dart';
import '../data/models/product_analysis.dart';
import '../data/repositories/product_repository.dart';
import '../screens/product_detail_screen.dart';
import 'ocr_scan_dialog.dart';

enum _ScanStatus { loading, found, notFound, invalid, error }

/// Bottom sheet hasil pemindaian barcode: mencari produk di Open Food Facts
/// (hanya produk yang beredar di Indonesia) lalu menampilkan ringkasannya.
class ScanResultSheet extends StatefulWidget {
  const ScanResultSheet({super.key, required this.code, this.repository});

  /// Nilai mentah hasil pemindaian.
  final String code;

  /// Untuk pengujian; default memakai [ProductRepository.instance].
  final ProductRepository? repository;

  @override
  State<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<ScanResultSheet> {
  _ScanStatus _status = _ScanStatus.loading;
  ProductAnalysis? _analysis;
  String _errorMessage = '';

  ProductRepository get _repository =>
      widget.repository ?? ProductRepository.instance;

  Product? get _product => _analysis?.product;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    setState(() => _status = _ScanStatus.loading);

    final barcode = ProductRepository.normalizeBarcode(widget.code);
    if (barcode == null) {
      setState(() => _status = _ScanStatus.invalid);
      return;
    }

    try {
      final product = await _repository.getByBarcode(barcode);
      if (product == null) {
        if (!mounted) return;
        setState(() => _status = _ScanStatus.notFound);
        return;
      }
      final analysis = await _repository.analyze(product);
      if (!mounted) return;
      setState(() {
        _analysis = analysis;
        _status = _ScanStatus.found;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is ProductSourceException
            ? e.message
            : 'Terjadi kesalahan saat mencari produk.';
        _status = _ScanStatus.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildBody(),
            const SizedBox(height: 20),
            ..._buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _ScanStatus.loading:
        return _StatusRow(
          leading: const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
          ),
          caption: 'Barcode terdeteksi',
          title: widget.code,
          message: 'Mencari produk di database Indonesia...',
        );
      case _ScanStatus.found:
        return _buildFound(_analysis!);
      case _ScanStatus.notFound:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusRow(
              icon: Icons.search_off_rounded,
              caption: 'Produk tidak ditemukan di database',
              title: widget.code,
              message: 'Barcode ini belum terdaftar di Open Food Facts Indonesia. Anda dapat memindai langsung tabel nutrisi & komposisi kemasan dengan OCR.',
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.document_scanner_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Info Nutrisi & Bahan (OCR)?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Arahkan kamera ke label komposisi untuk deteksi zat aditif otomatis.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case _ScanStatus.invalid:
        return _StatusRow(
          icon: Icons.qr_code_2_rounded,
          caption: 'Bukan barcode produk',
          title: widget.code,
          message: 'Kode yang dipindai bukan barcode makanan/minuman kemasan (EAN/UPC).',
        );
      case _ScanStatus.error:
        return _StatusRow(
          icon: Icons.cloud_off_rounded,
          caption: 'Gagal memuat produk',
          title: widget.code,
          message: _errorMessage,
        );
    }
  }

  Widget _buildFound(ProductAnalysis analysis) {
    final product = analysis.product;
    final risk = analysis.overallRisk;
    final subtitle = [product.brand, product.quantity]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' • ');

    final summary = !analysis.hasIngredientData
        ? 'Data komposisi belum tersedia, tingkat keamanan belum bisa dinilai.'
        : analysis.additives.isEmpty
            ? 'Tidak ada aditif yang dikenali dalam basis data NutriCheck.'
            : '${analysis.additives.length} aditif terdeteksi: '
                '${analysis.additives.take(3).map((a) => a.displayName).join(', ')}'
                '${analysis.additives.length > 3 ? ', ...' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(imageUrl: product.imageUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6D7A77),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: risk?.backgroundColor ?? AppColors.badgeBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                risk?.label ?? 'Data Terbatas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: risk?.color ?? AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          summary,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.45,
            color: const Color(0xFF3D4947),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    final isFound = _status == _ScanStatus.found;
    final isNotFound = _status == _ScanStatus.notFound;
    final primaryLabel = switch (_status) {
      _ScanStatus.found => 'Lihat Detail Analisis',
      _ScanStatus.notFound => 'Scan Info Nutrisi (OCR)',
      _ScanStatus.error => 'Coba Lagi',
      _ => null,
    };

    final hasIncompleteIngredients = isFound && _product != null && !_product!.hasIngredientData;

    return [
      if (hasIncompleteIngredients) ...[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              OcrScanDialog.show(
                context,
                initialBarcode: widget.code,
                baseProduct: _product,
                promptMessage: 'Data komposisi produk ini belum lengkap. Foto label bahan pada kemasan untuk mendeteksi zat aditifnya.',
              );
            },
            icon: const Icon(Icons.document_scanner_rounded, size: 18),
            label: Text(
              'Lengkapi Komposisi via OCR',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
      if (primaryLabel != null)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isFound
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(
                          product: _product!,
                          repository: widget.repository,
                        ),
                      ),
                    )
                : (isNotFound
                    ? () {
                        Navigator.pop(context);
                        OcrScanDialog.show(
                          context,
                          initialBarcode: widget.code,
                          promptMessage: 'Produk belum ada di database. Foto label komposisi/informasi gizi untuk analisis aditif.',
                        );
                      }
                    : _lookup),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: Text(
              primaryLabel,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      if (primaryLabel != null) const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: _status == _ScanStatus.found || _status == _ScanStatus.error
            ? TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Pindai Lagi',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Pindai Lagi',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
      ),
    ];
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    this.icon,
    this.leading,
    required this.caption,
    required this.title,
    required this.message,
  });

  final IconData? icon;
  final Widget? leading;
  final String caption;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD1E7DD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: leading ?? Icon(icon ?? Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caption,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.45,
            color: const Color(0xFF3D4947),
          ),
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => const Icon(Icons.fastfood_rounded, color: AppColors.primary);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? placeholder()
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder(),
            ),
    );
  }
}
