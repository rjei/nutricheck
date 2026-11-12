import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../data/models/product.dart';
import '../screens/product_detail_screen.dart';
import '../services/ocr_service.dart';

/// Modal / Dialog untuk memindai komposisi makanan atau tabel nilai gizi langsung
/// menggunakan kamera atau galeri dengan Optical Character Recognition (OCR).
class OcrScanDialog extends StatefulWidget {
  final String? initialBarcode;
  final Product? baseProduct;
  final String? promptMessage;

  const OcrScanDialog({
    super.key,
    this.initialBarcode,
    this.baseProduct,
    this.promptMessage,
  });

  /// Helper untuk membuka dialog secara praktis
  static Future<void> show(
    BuildContext context, {
    String? initialBarcode,
    Product? baseProduct,
    String? promptMessage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OcrScanDialog(
        initialBarcode: initialBarcode,
        baseProduct: baseProduct,
        promptMessage: promptMessage,
      ),
    );
  }

  @override
  State<OcrScanDialog> createState() => _OcrScanDialogState();
}

class _OcrScanDialogState extends State<OcrScanDialog> {
  bool _isProcessing = false;
  String? _statusText;

  Future<void> _handlePick(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _statusText = source == ImageSource.camera
          ? 'Membuka kamera...'
          : 'Memilih dari galeri...';
    });

    final file = await OcrService.instance.pickImage(source);
    if (file == null) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = null;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _statusText = 'Membaca teks komposisi & nilai gizi...';
    });

    try {
      final result = await OcrService.instance.processImage(
        file,
        existingBarcode: widget.initialBarcode,
        baseProduct: widget.baseProduct,
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog

      // Buka detail produk dengan data hasil analisis OCR
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            product: result.product,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusText = 'Gagal memproses gambar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.baseProduct != null
        ? 'Lengkapi Info "${widget.baseProduct!.name}"'
        : (widget.initialBarcode != null
            ? 'Scan Label Komposisi (Barcode: ${widget.initialBarcode})'
            : 'Scan Informasi Gizi & Komposisi (OCR)');

    final subtitle = widget.promptMessage ??
        (widget.baseProduct != null
            ? 'Data komposisi produk ini belum lengkap di Open Food Facts. Foto label bahan kemasan untuk mendeteksi zat aditifnya secara otomatis.'
            : 'Arahkan kamera ke bagian label komposisi (ingredients) atau tabel gizi kemasan.');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
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
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pendeteksi Zat Aditif Berbasis OCR',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _statusText ?? 'Sedang memproses...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handlePick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 20),
                      label: Text(
                        'Ambil Foto',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handlePick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 20),
                      label: Text(
                        'Pilih Galeri',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Tip: Pastikan tulisan komposisi terlihat jelas dan tidak buram.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
