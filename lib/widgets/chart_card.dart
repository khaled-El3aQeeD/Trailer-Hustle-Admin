import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trailerhustle_admin/models/chart_data_set.dart';

/// Interactive line chart widget with time period switching.
class ChartCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> timePeriods;
  final Map<String, ChartDataSet> datasets;

  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timePeriods,
    required this.datasets,
  });

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  int _selectedIndex = 0;

  ChartDataSet get _currentDataSet {
    final periodKey = widget.timePeriods[_selectedIndex];
    return widget.datasets[periodKey] ?? widget.datasets.values.first;
  }

  double _getMaxValue() {
    final currentData = _currentDataSet;
    final primaryMax = currentData.primaryData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    final secondaryMax = currentData.secondaryData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    return primaryMax > secondaryMax ? primaryMax : secondaryMax;
  }

  @override
  Widget build(BuildContext context) {
    return FCard.raw(
      style: FCardStyle(
        decoration: BoxDecoration(
          color: context.theme.colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.theme.colors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.theme.colors.foreground.withValues(alpha: 0.12),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        contentStyle: FCardContentStyle(
          padding: const EdgeInsets.all(24),
          titleTextStyle: context.theme.typography.sm.copyWith(
            fontWeight: FontWeight.w500,
            color: context.theme.colors.mutedForeground,
          ),
          subtitleTextStyle: context.theme.typography.sm.copyWith(
            fontWeight: FontWeight.w500,
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ).call,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and time period tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: context.theme.typography.lg.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.theme.colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: context.theme.typography.sm.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                // Responsive time period selector
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isLargeScreen =
                        context.theme.breakpoints.lg <=
                        MediaQuery.of(context).size.width;

                    if (isLargeScreen) {
                      // Segmented toggle for large screens
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.theme.colors.muted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.timePeriods.asMap().entries.map((
                            entry,
                          ) {
                            final index = entry.key;
                            final period = entry.value;
                            final isSelected = index == _selectedIndex;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? context.theme.colors.background
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: context
                                                .theme
                                                .colors
                                                .foreground
                                                .withValues(alpha: 0.1),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  period,
                                  style: context.theme.typography.sm.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? context.theme.colors.foreground
                                        : context.theme.colors.mutedForeground,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    } else {
                      // FSelect dropdown for smaller screens
                      return SizedBox(
                        width: 160,
                        child: FSelect<String>(
                          format: (value) => value,
                          initialValue: widget.timePeriods[_selectedIndex],
                          onChange: (value) {
                            if (value != null) {
                              final index = widget.timePeriods.indexOf(value);
                              if (index != -1) {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              }
                            }
                          },
                          children: widget.timePeriods.map((period) {
                            return FSelectItem(period, period);
                          }).toList(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Chart area using fl_chart
            SizedBox(
              height: 200,
              child: LineChart(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                LineChartData(
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          context.theme.colors.background,
                      tooltipBorder: BorderSide(
                        color: context.theme.colors.border,
                        width: 1,
                      ),
                      tooltipRoundedRadius: 6,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      tooltipMargin: 8,
                      maxContentWidth: 120,
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.asMap().entries.map((entry) {
                          final index = entry.key;
                          final barSpot = entry.value;
                          final dataIndex = barSpot.x.toInt();
                          final currentData = _currentDataSet;

                          // Only show tooltip for the first line (primary data)
                          // to avoid duplicates, but return null for secondary
                          if (index == 0 &&
                              dataIndex >= 0 &&
                              dataIndex < currentData.primaryData.length) {
                            final date =
                                currentData.primaryData[dataIndex].label;
                            final mobileValue = currentData
                                .primaryData[dataIndex]
                                .value
                                .toInt();
                            final desktopValue = currentData
                                .secondaryData[dataIndex]
                                .value
                                .toInt();

                            return LineTooltipItem(
                              textAlign: TextAlign.left,
                              '$date\n\n',
                              context.theme.typography.xs.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.theme.colors.foreground,
                              ),
                              children: [
                                TextSpan(
                                  text: '■ ',
                                  style: context.theme.typography.xs.copyWith(
                                    color: context.theme.colors.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    height: 1.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Mobile      ',
                                  style: context.theme.typography.xs.copyWith(
                                    color: context.theme.colors.foreground,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                                TextSpan(
                                  text: '$mobileValue\n',
                                  style: context.theme.typography.xs.copyWith(
                                    color: context.theme.colors.foreground,
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                  ),
                                ),
                                TextSpan(
                                  text: '■ ',
                                  style: context.theme.typography.xs.copyWith(
                                    color: context.theme.colors.mutedForeground,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    height: 1.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Desktop   ',
                                  style: context.theme.typography.xs.copyWith(
                                    color: context.theme.colors.foreground,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                                TextSpan(
                                  text: '$desktopValue',
                                  style: context.theme.typography.xs.copyWith(
                                    color: context.theme.colors.foreground,
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            );
                          }
                          // Return null for other lines to hide their individual tooltips
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: context.theme.colors.border.withValues(
                          alpha: 0.3,
                        ),
                        strokeWidth: 1,
                      );
                    },
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (_currentDataSet.primaryData.length / 10)
                            .ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          final currentData = _currentDataSet;
                          final dataLength = currentData.primaryData.length;

                          // Skip first and last labels to prevent overflow
                          if (index <= 0 || index >= dataLength - 1) {
                            return const SizedBox.shrink();
                          }

                          if (index < dataLength) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                currentData.primaryData[index].label,
                                style: context.theme.typography.xs.copyWith(
                                  color: context.theme.colors.mutedForeground,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Secondary line (mobile - behind primary)
                    LineChartBarData(
                      spots: _currentDataSet.secondaryData
                          .asMap()
                          .entries
                          .map(
                            (entry) => FlSpot(
                              entry.key.toDouble(),
                              entry.value.value,
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: context.theme.colors.mutedForeground,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.theme.colors.mutedForeground.withValues(
                              alpha: 0.3,
                            ),
                            context.theme.colors.mutedForeground.withValues(
                              alpha: 0.1,
                            ),
                            context.theme.colors.mutedForeground.withValues(
                              alpha: 0.05,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Primary line (desktop - on top)
                    LineChartBarData(
                      spots: _currentDataSet.primaryData
                          .asMap()
                          .entries
                          .map(
                            (entry) => FlSpot(
                              entry.key.toDouble(),
                              entry.value.value,
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: context.theme.colors.primary,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.theme.colors.primary.withValues(alpha: 0.4),
                            context.theme.colors.primary.withValues(alpha: 0.2),
                            context.theme.colors.primary.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                  ],
                  minY: 50,
                  maxY: _getMaxValue(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
