import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/home_dashboard_data.dart';
import '../services/home_data_service.dart';

/// Painter khusus untuk Circular Progress Bar dengan gradasi warna hijau modern
/// dan ujung melengkung (StrokeCap.round) sesuai desain target Gambar 1.
class GradientCircularProgressPainter extends CustomPainter {
  final double progress; // 0.0 - 1.0
  final double strokeWidth;
  final Color trackColor;
  final List<Color> gradientColors;

  const GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Gambar cincin background (track)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // 2. Gambar arc progress dengan gradasi warna dan rounded caps
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * progress.clamp(0.01, 1.0);
    const startAngle = -math.pi / 2; // Mulai dari jam 12 (-90 derajat)

    final gradientPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: gradientColors,
        tileMode: TileMode.clamp,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, startAngle, sweepAngle, false, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }
}

/// Unified Card untuk Analisis Kumulatif Batas Harian (ADI) dan Tren Toleransi
/// persis sesuai dengan tampilan Gambar 1.
class AdiCardWidget extends StatelessWidget {
  final DailyAdiSummary? summary;
  final List<WeeklyTrendPoint>? weeklyPoints;

  const AdiCardWidget({
    super.key,
    this.summary,
    this.weeklyPoints,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSummary =
        summary ?? HomeDataService.instance.dailyAdiSummary;
    final effectivePoints =
        weeklyPoints ?? HomeDataService.instance.weeklyTrendPoints;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF9FDFB),
            Color(0xFFEFF8F3),
          ],
          stops: [0.0, 0.65, 1.0],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Card (ANALISIS KUMULATIF & Status Terjaga)
          _buildHeader(effectiveSummary),

          const SizedBox(height: 24),

          // 2. Circular Progress Bar ADI (Ukuran lapang, tanpa teks bertumpuk)
          _buildCircularProgressSection(effectiveSummary),

          const SizedBox(height: 20),

          // 3. Zona Aman ADI Badge
          _buildZoneBadge(effectiveSummary),

          const SizedBox(height: 28),

          // 4. Header Tren Toleransi & Dropdown "Minggu ini"
          _buildTrendHeader(),

          const SizedBox(height: 12),

          // 5. Line Chart Spline fl_chart (7 hari Senin-Minggu)
          _buildSmoothLineChart(effectivePoints),
        ],
      ),
    );
  }

  Widget _buildHeader(DailyAdiSummary summary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ANALISIS KUMULATIF',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F5132),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Batas Harian (ADI)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFD1E7DD),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 3,
                backgroundColor: Color(0xFF0F5132),
              ),
              const SizedBox(width: 5),
              Text(
                summary.statusLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF0F5132),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularProgressSection(DailyAdiSummary summary) {
    final progress = summary.percentage / 100.0;

    return Center(
      child: SizedBox(
        width: 175,
        height: 175,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cincin Progres Kustom dengan Gradasi Halus & Rounded Cap
            CustomPaint(
              size: const Size(175, 175),
              painter: GradientCircularProgressPainter(
                progress: progress,
                strokeWidth: 14,
                trackColor: const Color(0xFFE8EEF5),
                gradientColors: const [
                  Color(0xFF00B775), // Mint Green Cerah
                  Color(0xFF0F5132), // Emerald Brand Green Nutricheck
                ],
              ),
            ),

            // Teks Persentase, Status, dan Subtitle (Terstruktur rapi tanpa tabrakan)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${summary.percentage.toInt()}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 35,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F5132),
                      letterSpacing: -0.5,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    summary.statusDescription,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F5132),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneBadge(DailyAdiSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.5, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4EA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 15,
            color: Color(0xFF0F5132),
          ),
          const SizedBox(width: 6),
          Text(
            summary.zoneTag,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: const Color(0xFF0F5132),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Tren Toleransi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Minggu ini',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmoothLineChart(List<WeeklyTrendPoint> points) {
    if (points.isEmpty) {
      return const SizedBox(height: 100);
    }

    final spots = points
        .map((p) => FlSpot(p.dayIndex.toDouble(), p.value))
        .toList();

    return SizedBox(
      height: 110,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 90,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt().clamp(0, points.length - 1);
                  final point = points[index];
                  return LineTooltipItem(
                    '${point.dayLabel}: ${spot.y.toInt()}%',
                    GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final point = points[index];
                  final bool isToday = point.isToday || index == 6;

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      point.dayLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday
                            ? const Color(0xFF0F5132)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Garis horizontal putus-putus batas referensi di atas kurva
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 72,
                color: const Color(0xFFD1E7DD),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              preventCurveOverShooting: true,
              color: const Color(0xFF0F5132),
              barWidth: 2.2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) {
                  // Titik hanya pada hari terakhir (Min) sesuai Gambar 1
                  return spot.x == 6;
                },
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3.5,
                    color: const Color(0xFF0F5132),
                    strokeWidth: 0,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F5132).withValues(alpha: 0.16),
                    const Color(0xFF0F5132).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
