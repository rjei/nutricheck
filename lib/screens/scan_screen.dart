import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../constants/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/ocr_scan_dialog.dart';
import '../widgets/scan_result_sheet.dart';

enum ScanMode { barcode, ocrNutrition }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _primaryGreen = Color(0xFF0F5132);
  static const Color _scanGreen = Color(0xFF80ED99);

  ScanMode _currentMode = ScanMode.barcode;

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isStarting = true;
  bool _permissionDenied = false;
  bool _isHandlingScan = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.12, end: 0.88).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    unawaited(_startCamera());
  }

  Future<void> _startCamera() async {
    if (_currentMode != ScanMode.barcode) return;

    setState(() {
      _isStarting = true;
      _permissionDenied = false;
    });

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    try {
      await _scannerController.start();
      if (!mounted) return;
      setState(() {
        _isStarting = false;
        _permissionDenied = false;
      });
    } on MobileScannerException catch (e) {
      if (!mounted) return;
      setState(() {
        _isStarting = false;
        _permissionDenied =
            e.errorCode == MobileScannerErrorCode.permissionDenied;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isStarting = false;
        _permissionDenied = true;
      });
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isHandlingScan || _permissionDenied || _currentMode != ScanMode.barcode) {
      return;
    }

    final code = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    if (code.isEmpty || code == _lastScannedCode) return;

    _isHandlingScan = true;
    _lastScannedCode = code;
    unawaited(_scannerController.stop());

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScanResultSheet(code: code),
    ).whenComplete(() async {
      _isHandlingScan = false;
      _lastScannedCode = null;
      if (mounted && _currentMode == ScanMode.barcode) {
        await _startCamera();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentMode != ScanMode.barcode) return;
    if (!_scannerController.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isHandlingScan) {
          unawaited(_scannerController.start());
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_scannerController.stop());
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanAnimationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _switchMode(ScanMode mode) {
    if (_currentMode == mode) return;
    setState(() {
      _currentMode = mode;
    });

    if (mode == ScanMode.barcode) {
      _startCamera();
    } else {
      _scannerController.stop();
    }
  }

  Widget _buildModeSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeSwitchButton(
              label: 'Pindai Barcode',
              icon: Icons.qr_code_scanner_rounded,
              isSelected: _currentMode == ScanMode.barcode,
              onTap: () => _switchMode(ScanMode.barcode),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModeSwitchButton(
              label: 'Scan Nutrisi (OCR)',
              icon: Icons.document_scanner_rounded,
              isSelected: _currentMode == ScanMode.ocrNutrition,
              onTap: () => _switchMode(ScanMode.ocrNutrition),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.videocam_off_outlined,
            size: 48,
            color: Color(0xFF9E9E9E),
          ),
          const SizedBox(height: 16),
          Text(
            'Izin Kamera Ditolak',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nutricheck membutuhkan akses kamera untuk memindai barcode makanan kemasan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFBDBDBD),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _startCamera,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: Text(
              'Coba Lagi',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrDirectView() {
    return Expanded(
      flex: 5,
      child: Container(
        color: const Color(0xFF0F172A),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryAccent, width: 2),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    size: 32,
                    color: AppColors.primaryAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pindai Label Nutrisi & Bahan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Foto label komposisi atau tabel informasi gizi pada kemasan untuk mendeteksi zat aditif dan alergen secara otomatis dengan AI OCR.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    OcrScanDialog.show(
                      context,
                      promptMessage: 'Foto label komposisi kemasan dengan jelas.',
                    );
                  },
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: Text(
                    'Buka Kamera OCR',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerArea() {
    if (_currentMode == ScanMode.ocrNutrition) {
      return _buildOcrDirectView();
    }

    final showCamera = !_permissionDenied;

    return Expanded(
      flex: 5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_permissionDenied)
            _buildPermissionDenied()
          else
            MobileScanner(
              controller: _scannerController,
              fit: BoxFit.cover,
              onDetect: _onBarcodeDetected,
              errorBuilder: (context, error) {
                if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _permissionDenied) return;
                    setState(() {
                      _permissionDenied = true;
                      _isStarting = false;
                    });
                  });
                }
                return Container(
                  color: const Color(0xFF1E1E1E),
                  child: const Center(
                    child: CircularProgressIndicator(color: _scanGreen),
                  ),
                );
              },
            ),

          if (_isStarting && showCamera)
            Container(
              color: const Color(0xFF1E1E1E),
              child: const Center(
                child: CircularProgressIndicator(color: _scanGreen),
              ),
            ),

          if (showCamera && !_isStarting) ...[
            IgnorePointer(
              child: Container(color: Colors.black.withValues(alpha: 0.15)),
            ),
            IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _CornerBorder(
                          color: _scanGreen,
                          alignment: Alignment.topLeft,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _CornerBorder(
                          color: _scanGreen,
                          alignment: Alignment.topRight,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _CornerBorder(
                          color: _scanGreen,
                          alignment: Alignment.bottomLeft,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _CornerBorder(
                          color: _scanGreen,
                          alignment: Alignment.bottomRight,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 240 * _scanAnimation.value,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: _scanGreen,
                                boxShadow: [
                                  BoxShadow(
                                    color: _scanGreen.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Sejajarkan barcode di dalam bingkai',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Senter',
                  onPressed: () => _scannerController.toggleTorch(),
                  icon: ValueListenableBuilder(
                    valueListenable: _scannerController,
                    builder: (context, state, child) {
                      final isOn = state.torchState == TorchState.on;
                      return Icon(
                        isOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFD1E7DD),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _primaryGreen,
                ),
              ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF6D7A77),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidePanel() {
    final isBarcode = _currentMode == ScanMode.barcode;

    return Expanded(
      flex: 5,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBarcode ? 'Panduan Pindai Barcode' : 'Panduan Pindai OCR Label',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 16),
              if (isBarcode) ...[
                _buildStepCard(
                  number: '1',
                  title: 'Cari Barcode',
                  description:
                      'Temukan kode batang di sisi atau belakang kemasan produk.',
                ),
                const SizedBox(height: 12),
                _buildStepCard(
                  number: '2',
                  title: 'Sejajarkan',
                  description:
                      'Pastikan kode berada di tengah bingkai dan tidak goyang.',
                ),
                const SizedBox(height: 12),
                _buildStepCard(
                  number: '3',
                  title: 'Fallback OCR',
                  description:
                      'Jika barcode belum terdaftar, Anda bisa langsung scan label nutrisi via OCR.',
                ),
              ] else ...[
                _buildStepCard(
                  number: '1',
                  title: 'Fokuskan Teks Komposisi',
                  description:
                      'Pastikan tulisan "Komposisi / Ingredients" berada dalam area foto yang jelas.',
                ),
                const SizedBox(height: 12),
                _buildStepCard(
                  number: '2',
                  title: 'Pencahayaan Terang',
                  description:
                      'Hindari pantulan cahaya plastik atau bayangan agar teks terbaca akurat.',
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      color: _primaryGreen,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tips Akurasi Deteksi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isBarcode
                                ? 'Hindari bayangan atau pantulan cahaya langsung pada barcode.'
                                : 'Pegang kemasan secara rata dan pastikan tulisan tidak terlipat atau buram.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF334155),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeader(
        showDefaultActions: true,
      ),
      body: Column(
        children: [
          _buildModeSwitcher(),
          _buildScannerArea(),
          _buildGuidePanel(),
        ],
      ),
    );
  }
}

class _ModeSwitchButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSwitchButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerBorder extends StatelessWidget {
  final Color color;
  final Alignment alignment;

  const _CornerBorder({
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    const size = 32.0;
    const thickness = 4.0;
    const radius = Radius.circular(8);

    BorderRadius borderRadius;
    Border border;

    if (alignment == Alignment.topLeft) {
      borderRadius = const BorderRadius.only(topLeft: radius);
      border = Border(
        top: BorderSide(color: color, width: thickness),
        left: BorderSide(color: color, width: thickness),
      );
    } else if (alignment == Alignment.topRight) {
      borderRadius = const BorderRadius.only(topRight: radius);
      border = Border(
        top: BorderSide(color: color, width: thickness),
        right: BorderSide(color: color, width: thickness),
      );
    } else if (alignment == Alignment.bottomLeft) {
      borderRadius = const BorderRadius.only(bottomLeft: radius);
      border = Border(
        bottom: BorderSide(color: color, width: thickness),
        left: BorderSide(color: color, width: thickness),
      );
    } else {
      borderRadius = const BorderRadius.only(bottomRight: radius);
      border = Border(
        bottom: BorderSide(color: color, width: thickness),
        right: BorderSide(color: color, width: thickness),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: border,
        borderRadius: borderRadius,
      ),
    );
  }
}
