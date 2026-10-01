import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'notification_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _primaryGreen = Color(0xFF0F5132);
  static const Color _scanGreen = Color(0xFF80ED99);

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
    setState(() {
      _isStarting = true;
      _permissionDenied = false;
    });

    // Tampilkan MobileScanner dulu agar controller terpasang.
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
    if (_isHandlingScan || _permissionDenied) return;

    final code = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    if (code.isEmpty || code == _lastScannedCode) return;

    _isHandlingScan = true;
    _lastScannedCode = code;
    unawaited(_scannerController.stop());

    if (!mounted) return;
    _showScanResult(code);
  }

  void _showScanResult(String code) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1E7DD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: _primaryGreen,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Barcode terdeteksi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          code,
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Pindai Lagi',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() async {
      _isHandlingScan = false;
      _lastScannedCode = null;
      if (!mounted || _permissionDenied) return;
      try {
        await _scannerController.start();
      } catch (_) {}
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_permissionDenied) {
          unawaited(_startCamera());
        } else if (!_isStarting) {
          unawaited(_scannerController.start());
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_scannerController.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanAnimationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        'nutricheck',
        style: GoogleFonts.comfortaa(
          color: _primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded, color: Colors.grey),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.grey),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPermissionDenied() {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 56, color: Colors.white70),
          const SizedBox(height: 16),
          Text(
            'Akses kamera diperlukan',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Izinkan kamera saat diminta, atau buka Pengaturan > Aplikasi > nutricheck > Izin > Kamera.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 13,
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

  Widget _buildScannerArea() {
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
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _scanGreen, width: 3),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 240 * _scanAnimation.value,
                            left: 16,
                            right: 16,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: _scanGreen,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _scanGreen.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 1,
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
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xCC191C1E),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Pusatkan Barcode',
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFD1E7DD),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF6D7A77),
                    height: 1.35,
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
    return Expanded(
      flex: 6,
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
                'Cara Memindai',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 16),
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
                            'Tips Pencahayaan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hindari bayangan atau pantulan cahaya langsung pada barcode. Pindai di tempat yang terang untuk hasil yang lebih cepat dan akurat.',
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
      appBar: _buildHeader(),
      body: Column(
        children: [
          _buildScannerArea(),
          _buildGuidePanel(),
        ],
      ),
    );
  }
}
