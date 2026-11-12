import 'package:flutter/material.dart';

/// Status evaluasi komponen dominan
enum ComponentStatusType {
  aman,
  stabil,
  sangatRendah,
  waspada;

  String get label {
    switch (this) {
      case ComponentStatusType.aman:
        return 'Aman';
      case ComponentStatusType.stabil:
        return 'Stabil';
      case ComponentStatusType.sangatRendah:
        return 'Sangat Rendah';
      case ComponentStatusType.waspada:
        return 'Waspada';
    }
  }

  Color get color {
    switch (this) {
      case ComponentStatusType.aman:
        return const Color(0xFF16A34A); // Hijau
      case ComponentStatusType.stabil:
        return const Color(0xFFD97706); // Oranye/Amber
      case ComponentStatusType.sangatRendah:
        return const Color(0xFF0D9488); // Hijau Muda / Teal
      case ComponentStatusType.waspada:
        return const Color(0xFFDC2626); // Merah
    }
  }

  Color get dotColor {
    switch (this) {
      case ComponentStatusType.aman:
        return const Color(0xFF16A34A);
      case ComponentStatusType.stabil:
        return const Color(0xFFB45309);
      case ComponentStatusType.sangatRendah:
        return const Color(0xFF0D9488);
      case ComponentStatusType.waspada:
        return const Color(0xFFDC2626);
    }
  }
}

/// Model untuk item Komponen Dominan
class DominantComponentItem {
  final String id;
  final String name;
  final String description;
  final double percentage;
  final ComponentStatusType status;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;

  const DominantComponentItem({
    required this.id,
    required this.name,
    required this.description,
    required this.percentage,
    required this.status,
    required this.icon,
    this.iconBackgroundColor = const Color(0xFFF1F5F9),
    this.iconColor = const Color(0xFF0F5132),
  });
}

/// Model untuk titik data koordinat tren konsumsi mingguan
class WeeklyTrendPoint {
  final int dayIndex; // 0 = Sen, 6 = Min
  final String dayLabel;
  final double value; // Nilai persentase beban toleransi (0 - 100)
  final bool isToday;
  final DateTime date;

  const WeeklyTrendPoint({
    required this.dayIndex,
    required this.dayLabel,
    required this.value,
    this.isToday = false,
    required this.date,
  });
}

/// Model log konsumsi harian pengguna
class DailyConsumptionLog {
  final String id;
  final String productName;
  final String? brand;
  final DateTime timestamp;
  final double adiContributionPercentage; // Kontribusi terhadap total % ADI harian
  final double sodiumMg;
  final double sugarGram;
  final int additiveRiskScore;

  const DailyConsumptionLog({
    required this.id,
    required this.productName,
    this.brand,
    required this.timestamp,
    required this.adiContributionPercentage,
    this.sodiumMg = 0.0,
    this.sugarGram = 0.0,
    this.additiveRiskScore = 0,
  });
}

/// Model ringkasan ADI harian yang dihitung secara dinamis
class DailyAdiSummary {
  final double percentage; // Persentase total akumulasi hari ini
  final String statusLabel; // Misal: "Status Terjaga"
  final String statusDescription; // Misal: "Batas Harian Terjaga"
  final String subtitle; // Misal: "Beban toksin & aditif rendah"
  final String zoneTag; // Misal: "Zona Aman ADI (< 60% Toleransi)"

  const DailyAdiSummary({
    required this.percentage,
    required this.statusLabel,
    required this.statusDescription,
    required this.subtitle,
    required this.zoneTag,
  });

  /// Factory untuk menghitung status otomatis dari total persentase
  factory DailyAdiSummary.fromPercentage(double calculatedPercent) {
    final double clamped = calculatedPercent.clamp(0.0, 100.0);

    if (clamped <= 60.0) {
      return DailyAdiSummary(
        percentage: clamped,
        statusLabel: 'Status Terjaga',
        statusDescription: 'Batas Harian Terjaga',
        subtitle: 'Beban toksin & aditif rendah',
        zoneTag: 'Zona Aman ADI (< 60% Toleransi)',
      );
    } else if (clamped <= 85.0) {
      return DailyAdiSummary(
        percentage: clamped,
        statusLabel: 'Status Waspada',
        statusDescription: 'Mendekati Batas ADI',
        subtitle: 'Kurangi konsumsi aditif buatan',
        zoneTag: 'Zona Waspada ADI (60% - 85%)',
      );
    } else {
      return DailyAdiSummary(
        percentage: clamped,
        statusLabel: 'Melebihi Batas',
        statusDescription: 'Batas Harian Terlampaui',
        subtitle: 'Segera perbanyak air putih & detox',
        zoneTag: 'Zona Bahaya ADI (> 85%)',
      );
    }
  }
}

/// Model untuk Riwayat Pindai Terbaru
class RecentScanItem {
  final String id;
  final String productName;
  final String? brand;
  final String? imageUrl;
  final String formattedTime;
  final String description;
  final String grade; // Misal: "A+", "A", "B", dll
  final DateTime scannedAt;

  const RecentScanItem({
    required this.id,
    required this.productName,
    this.brand,
    this.imageUrl,
    required this.formattedTime,
    required this.description,
    required this.grade,
    required this.scannedAt,
  });
}
