import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/home_dashboard_data.dart';
import '../services/home_data_service.dart';

/// Standalone Trend Chart Widget jika ingin dipakai terpisah dari card utama
class TrendChartWidget extends StatelessWidget {
  final List<WeeklyTrendPoint>? points;
  final String period;
  final ValueChanged<String>? onPeriodChanged;

  const TrendChartWidget({
    super.key,
    this.points,
    this.period = 'Minggu ini',
    this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePoints =
        points ?? HomeDataService.instance.weeklyTrendPoints;

    return Column(
      children: [
        Row(
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
                    period,
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
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SizedBox(
            height: 110,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 90,
                lineTouchData: const LineTouchData(enabled: true),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= effectivePoints.length) {
                          return const SizedBox.shrink();
                        }
                        final point = effectivePoints[index];
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
                    spots: effectivePoints
                        .map((p) => FlSpot(p.dayIndex.toDouble(), p.value))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF0F5132),
                    barWidth: 2.2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => spot.x == 6,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: const Color(0xFF0F5132),
                        strokeWidth: 0,
                      ),
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
          ),
        ),
      ],
    );
  }
}
