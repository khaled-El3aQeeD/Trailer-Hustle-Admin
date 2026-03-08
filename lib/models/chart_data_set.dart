import 'package:trailerhustle_admin/models/chart_data_point.dart';

class ChartDataSet {
  final List<ChartDataPoint> primaryData;
  final List<ChartDataPoint> secondaryData;

  const ChartDataSet({
    required this.primaryData,
    required this.secondaryData,
  });
}