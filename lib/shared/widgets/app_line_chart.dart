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
    final minDataY = ys.reduce((a, b) => a < b ? a : b);
    final maxDataY = ys.reduce((a, b) => a > b ? a : b);
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

    final minCandidate = forceNonNegativeMinY && minDataY >= 0 ? 0.0 : minDataY;
    final spanCandidate = (maxDataY - minCandidate).abs();
    final roughStep = spanCandidate <= 0 ? 5.0 : (spanCandidate / 4);
    final yInterval = _niceStep(roughStep < 5 ? 5 : roughStep);
    var minY = (minCandidate / yInterval).floorToDouble() * yInterval;
    var maxY = (maxDataY / yInterval).ceilToDouble() * yInterval;
    if (maxY <= minY) {
      maxY = minY + yInterval;
    }
    if (forceNonNegativeMinY && minDataY >= 0 && minY < 0) {
      minY = 0;
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
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
                interval: yInterval,
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

double _niceStep(double value) {
  if (value <= 0) return 5;
  final exponent = (value <= 1) ? 0 : value.logBase10Floor();
  final base = _pow10(exponent);
  final fraction = value / base;
  double niceFraction;
  if (fraction <= 1) {
    niceFraction = 1;
  } else if (fraction <= 2) {
    niceFraction = 2;
  } else if (fraction <= 5) {
    niceFraction = 5;
  } else {
    niceFraction = 10;
  }
  final step = niceFraction * base;
  return step < 5 ? 5 : step;
}

double _pow10(int exp) {
  var result = 1.0;
  if (exp >= 0) {
    for (var i = 0; i < exp; i++) {
      result *= 10;
    }
  } else {
    for (var i = 0; i < -exp; i++) {
      result /= 10;
    }
  }
  return result;
}

extension on double {
  int logBase10Floor() {
    var n = this;
    var exp = 0;
    if (n >= 1) {
      while (n >= 10) {
        n /= 10;
        exp++;
      }
      return exp;
    }
    while (n > 0 && n < 1) {
      n *= 10;
      exp--;
    }
    return exp;
  }
}
