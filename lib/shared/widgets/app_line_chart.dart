import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AppLinePoint {
  const AppLinePoint({
    required this.x,
    required this.y,
    required this.label,
    required this.tooltip,
  });

  final double x;
  final double y;
  final String label;
  final String tooltip;
}

class AppLineChart extends StatelessWidget {
  const AppLineChart({
    super.key,
    required this.points,
    required this.color,
    this.height = 220,
    this.showDots = true,
    this.showArea = true,
    this.forceNonNegativeMinY = true,
    required this.showBottomLabelAt,
  });

  final List<AppLinePoint> points;
  final Color color;
  final double height;
  final bool showDots;
  final bool showArea;
  final bool forceNonNegativeMinY;
  final bool Function(int index, int length) showBottomLabelAt;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('暂无可绘制的数据')),
      );
    }

    final ys = points.map((p) => p.y).toList();
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final hasSingleValue = minY == maxY;
    var maxAdjacentChangeRatio = 0.0;
    for (var i = 1; i < ys.length; i++) {
      final prev = ys[i - 1].abs();
      final curr = ys[i].abs();
      final base = (prev > curr ? prev : curr);
      if (base <= 0) continue;
      final ratio = (ys[i] - ys[i - 1]).abs() / base;
      if (ratio > maxAdjacentChangeRatio) {
        maxAdjacentChangeRatio = ratio;
      }
    }
    final useCurvedLine = maxAdjacentChangeRatio < 0.72;
    final rawMin = hasSingleValue ? (minY - 1) : (minY * 0.96);
    final safeMin = forceNonNegativeMinY && minY >= 0
        ? (rawMin < 0 ? 0.0 : rawMin)
        : rawMin;
    final ySpan = (hasSingleValue ? 2.0 : ((maxY * 1.04) - safeMin)).abs();
    final yInterval = ySpan <= 0 ? 1.0 : (ySpan / 4);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: safeMin,
          maxY: hasSingleValue ? maxY + 1 : maxY * 1.04,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: hasSingleValue ? 1 : yInterval,
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipMargin: 50,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final i = spot.x.toInt();
                  if (i < 0 || i >= points.length) return null;
                  return LineTooltipItem(
                    points[i].tooltip,
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                interval: hasSingleValue ? 1 : yInterval,
                getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  if (!showBottomLabelAt(i, points.length)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(points[i].label),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: useCurvedLine,
              preventCurveOverShooting: true,
              preventCurveOvershootingThreshold: 1.0,
              color: color,
              barWidth: 3,
              dotData: FlDotData(show: showDots),
              belowBarData: BarAreaData(
                show: showArea,
                color: color.withOpacity(0.12),
              ),
              spots: points.map((p) => FlSpot(p.x, p.y)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
