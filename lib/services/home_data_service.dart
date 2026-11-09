import 'dart:async';
import 'package:flutter/material.dart';
import '../models/home_dashboard_data.dart';

/// Service penyedia data dinamis untuk Home Screen Dashboard
class HomeDataService extends ChangeNotifier {
  // Singleton pattern
  static final HomeDataService _instance = HomeDataService._internal();
  factory HomeDataService() => _instance;
  static HomeDataService get instance => _instance;

  HomeDataService._internal() {
    _initializeDefaultData();
  }

  // State log konsumsi hari ini
  final List<DailyConsumptionLog> _todayLogs = [];

  // State data mingguan untuk tren toleransi
  final List<WeeklyTrendPoint> _weeklyTrendPoints = [];

  // State komponen dominan
  final List<DominantComponentItem> _dominantComponents = [];

  // State riwayat pindai terbaru (null bila empty state)
  RecentScanItem? _latestScanItem;

  // Stream controllers untuk integrasi reaktif bila dibutuhkan
  final _weeklyTrendStreamController =
      StreamController<List<WeeklyTrendPoint>>.broadcast();

  // Getters
  List<DailyConsumptionLog> get todayLogs => List.unmodifiable(_todayLogs);
  List<WeeklyTrendPoint> get weeklyTrendPoints =>
      List.unmodifiable(_weeklyTrendPoints);
  Stream<List<WeeklyTrendPoint>> get weeklyTrendStream =>
      _weeklyTrendStreamController.stream;
  List<DominantComponentItem> get dominantComponents =>
      List.unmodifiable(_dominantComponents);
  RecentScanItem? get latestScanItem => _latestScanItem;

  /// Menghitung akumulasi persentase ADI dinamis dari data log konsumsi hari ini
  DailyAdiSummary get dailyAdiSummary {
    if (_todayLogs.isEmpty) {
      return DailyAdiSummary.fromPercentage(0.0);
    }
    // Akumulasi persentase kontribusi ADI dari tiap log makanan yang dikonsumsi hari ini
    final double totalPercent = _todayLogs.fold(
      0.0,
      (sum, item) => sum + item.adiContributionPercentage,
    );
    return DailyAdiSummary.fromPercentage(totalPercent);
  }

  void _initializeDefaultData() {
    final now = DateTime.now();

    // 1. Data log konsumsi hari ini (menghasilkan total 42% seperti target Gambar 1)
    _todayLogs.clear();
    _todayLogs.addAll([
      DailyConsumptionLog(
        id: 'log-1',
        productName: 'Yogurt Rendah Lemak',
        brand: 'Greenfields',
        timestamp: now.subtract(const Duration(hours: 4)),
        adiContributionPercentage: 14.0,
        sodiumMg: 65,
        sugarGram: 6.0,
      ),
      DailyConsumptionLog(
        id: 'log-2',
        productName: 'Roti Gandum Pilihan',
        brand: 'Sari Roti',
        timestamp: now.subtract(const Duration(hours: 2)),
        adiContributionPercentage: 18.0,
        sodiumMg: 120,
        sugarGram: 3.5,
      ),
      DailyConsumptionLog(
        id: 'log-3',
        productName: 'Susu Almond Unsweetened',
        brand: 'Sanitarium',
        timestamp: now.subtract(const Duration(minutes: 30)),
        adiContributionPercentage: 10.0,
        sodiumMg: 45,
        sugarGram: 0.8,
      ),
    ]);

    // 2. Data tren toleransi 7 hari terakhir (Senin–Minggu)
    // Titik koordinat kurva spline fl_chart
    _weeklyTrendPoints.clear();
    _weeklyTrendPoints.addAll([
      WeeklyTrendPoint(
        dayIndex: 0,
        dayLabel: 'Sen',
        value: 28.0,
        date: now.subtract(const Duration(days: 6)),
      ),
      WeeklyTrendPoint(
        dayIndex: 1,
        dayLabel: 'Sel',
        value: 36.0,
        date: now.subtract(const Duration(days: 5)),
      ),
      WeeklyTrendPoint(
        dayIndex: 2,
        dayLabel: 'Rab',
        value: 32.0,
        date: now.subtract(const Duration(days: 4)),
      ),
      WeeklyTrendPoint(
        dayIndex: 3,
        dayLabel: 'Kam',
        value: 46.0,
        date: now.subtract(const Duration(days: 3)),
      ),
      WeeklyTrendPoint(
        dayIndex: 4,
        dayLabel: 'Jum',
        value: 40.0,
        date: now.subtract(const Duration(days: 2)),
      ),
      WeeklyTrendPoint(
        dayIndex: 5,
        dayLabel: 'Sab',
        value: 45.0,
        date: now.subtract(const Duration(days: 1)),
      ),
      WeeklyTrendPoint(
        dayIndex: 6,
        dayLabel: 'Min',
        value: 52.0,
        isToday: true,
        date: now,
      ),
    ]);
    _weeklyTrendStreamController.add(_weeklyTrendPoints);

    // 3. Komponen Dominan dinamis
    _dominantComponents.clear();
    _dominantComponents.addAll([
      const DominantComponentItem(
        id: 'natrium',
        name: 'Natrium',
        description: 'Garam meja & bumbu kemasan',
        percentage: 35.0,
        status: ComponentStatusType.aman,
        icon: Icons.grain_rounded,
        iconBackgroundColor: Color(0xFFF0FDF4),
        iconColor: Color(0xFF15803D),
      ),
      const DominantComponentItem(
        id: 'gula',
        name: 'Gula Bebas',
        description: 'Minuman siap saji & saus',
        percentage: 28.0,
        status: ComponentStatusType.stabil,
        icon: Icons.cookie_outlined,
        iconBackgroundColor: Color(0xFFFFFBEB),
        iconColor: Color(0xFFB45309),
      ),
      const DominantComponentItem(
        id: 'benzoat',
        name: 'Pengawet Benzoat',
        description: 'Sodium Benzoate (E211)',
        percentage: 18.0,
        status: ComponentStatusType.sangatRendah,
        icon: Icons.science_outlined,
        iconBackgroundColor: Color(0xFFF0FDFA),
        iconColor: Color(0xFF0F766E),
      ),
    ]);

    // 4. Riwayat Pindai Terbaru default
    _latestScanItem = RecentScanItem(
      id: 'scan-latest',
      productName: 'Susu Almond Unsweetened',
      brand: 'Sanitarium',
      imageUrl: null,
      formattedTime: '10:45',
      description: 'Bebas aditif berisiko',
      grade: 'A+',
      scannedAt: now.subtract(const Duration(minutes: 30)),
    );
  }

  /// Tambah log konsumsi baru (otomatis mengubah persentase ADI dinamis)
  void addConsumptionLog(DailyConsumptionLog log) {
    _todayLogs.add(log);
    notifyListeners();
  }

  /// Catat hasil scan terbaru
  void setLatestScan(RecentScanItem item) {
    _latestScanItem = item;
    notifyListeners();
  }

  /// Reset / Hapus riwayat pindai untuk menguji Empty State
  void clearLatestScan() {
    _latestScanItem = null;
    notifyListeners();
  }

  /// Update data mingguan dari data eksternal
  void updateWeeklyTrend(List<WeeklyTrendPoint> newPoints) {
    _weeklyTrendPoints.clear();
    _weeklyTrendPoints.addAll(newPoints);
    _weeklyTrendStreamController.add(_weeklyTrendPoints);
    notifyListeners();
  }

  @override
  void dispose() {
    _weeklyTrendStreamController.close();
    super.dispose();
  }
}
