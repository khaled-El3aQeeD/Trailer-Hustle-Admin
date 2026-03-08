import 'package:trailerhustle_admin/models/chart_data_point.dart';
import 'package:trailerhustle_admin/models/chart_data_set.dart';

/// Service for managing chart data and analytics operations.
///
/// Provides chart datasets for various time periods and metrics.
/// Currently uses sample data for demonstration purposes.
class ChartService {
  
  /// Generate chart datasets for different time periods
  static Map<String, ChartDataSet> generateChartDatasets() {
    final threeMonthsData = _generateSampleData();

    return {
      'Last 3 months': ChartDataSet(
        primaryData: _filterAndConvertData(threeMonthsData, 90, 'desktop'),
        secondaryData: _filterAndConvertData(threeMonthsData, 90, 'mobile'),
      ),
      'Last 30 days': ChartDataSet(
        primaryData: _filterAndConvertData(threeMonthsData, 30, 'desktop'),
        secondaryData: _filterAndConvertData(threeMonthsData, 30, 'mobile'),
      ),
      'Last 7 days': ChartDataSet(
        primaryData: _filterAndConvertData(threeMonthsData, 7, 'desktop'),
        secondaryData: _filterAndConvertData(threeMonthsData, 7, 'mobile'),
      ),
    };
  }

  /// Filter and convert raw data to chart data points
  static List<ChartDataPoint> _filterAndConvertData(
    List<Map<String, dynamic>> data,
    int days,
    String key,
  ) {
    final referenceDate = DateTime(2024, 6, 30);
    final startDate = referenceDate.subtract(Duration(days: days));

    final filtered = data.where((item) {
      final date = DateTime.parse(item['date'] as String);
      return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
    }).toList();

    return filtered.map((item) {
      final date = DateTime.parse(item['date'] as String);
      final label = '${_getMonthAbbr(date.month)} ${date.day}';
      return ChartDataPoint(
        label: label,
        value: (item[key] as int).toDouble(),
      );
    }).toList();
  }

  /// Get month abbreviation
  static String _getMonthAbbr(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }

  /// Generate sample chart data
  static List<Map<String, dynamic>> _generateSampleData() {
    return [
      {'date': '2024-04-01', 'desktop': 150, 'mobile': 222},
      {'date': '2024-04-02', 'desktop': 140, 'mobile': 197},
      {'date': '2024-04-03', 'desktop': 120, 'mobile': 167},
      {'date': '2024-04-04', 'desktop': 160, 'mobile': 242},
      {'date': '2024-04-05', 'desktop': 190, 'mobile': 273},
      {'date': '2024-04-06', 'desktop': 180, 'mobile': 240},
      {'date': '2024-04-07', 'desktop': 125, 'mobile': 180},
      {'date': '2024-04-08', 'desktop': 170, 'mobile': 220},
      {'date': '2024-04-09', 'desktop': 140, 'mobile': 210},
      {'date': '2024-04-10', 'desktop': 170, 'mobile': 261},
      {'date': '2024-04-11', 'desktop': 180, 'mobile': 250},
      {'date': '2024-04-12', 'desktop': 160, 'mobile': 210},
      {'date': '2024-04-13', 'desktop': 200, 'mobile': 280},
      {'date': '2024-04-14', 'desktop': 150, 'mobile': 220},
      {'date': '2024-04-15', 'desktop': 140, 'mobile': 200},
      {'date': '2024-04-16', 'desktop': 160, 'mobile': 238},
      {'date': '2024-04-17', 'desktop': 220, 'mobile': 346},
      {'date': '2024-04-18', 'desktop': 210, 'mobile': 310},
      {'date': '2024-04-19', 'desktop': 130, 'mobile': 180},
      {'date': '2024-04-20', 'desktop': 120, 'mobile': 189},
      {'date': '2024-04-21', 'desktop': 170, 'mobile': 237},
      {'date': '2024-04-22', 'desktop': 140, 'mobile': 224},
      {'date': '2024-04-23', 'desktop': 180, 'mobile': 238},
      {'date': '2024-04-24', 'desktop': 220, 'mobile': 290},
      {'date': '2024-04-25', 'desktop': 190, 'mobile': 250},
      {'date': '2024-04-26', 'desktop': 110, 'mobile': 175},
      {'date': '2024-04-27', 'desktop': 230, 'mobile': 320},
      {'date': '2024-04-28', 'desktop': 150, 'mobile': 222},
      {'date': '2024-04-29', 'desktop': 180, 'mobile': 240},
      {'date': '2024-04-30', 'desktop': 210, 'mobile': 280},
      {'date': '2024-05-01', 'desktop': 190, 'mobile': 265},
      {'date': '2024-05-02', 'desktop': 160, 'mobile': 210},
      {'date': '2024-05-03', 'desktop': 170, 'mobile': 247},
      {'date': '2024-05-04', 'desktop': 220, 'mobile': 320},
      {'date': '2024-05-05', 'desktop': 210, 'mobile': 290},
      {'date': '2024-05-06', 'desktop': 280, 'mobile': 420},
      {'date': '2024-05-07', 'desktop': 150, 'mobile': 200},
      {'date': '2024-05-08', 'desktop': 170, 'mobile': 249},
      {'date': '2024-05-09', 'desktop': 140, 'mobile': 227},
      {'date': '2024-05-10', 'desktop': 200, 'mobile': 293},
      {'date': '2024-05-11', 'desktop': 190, 'mobile': 270},
      {'date': '2024-05-12', 'desktop': 200, 'mobile': 297},
      {'date': '2024-05-13', 'desktop': 140, 'mobile': 197},
      {'date': '2024-05-14', 'desktop': 280, 'mobile': 390},
      {'date': '2024-05-15', 'desktop': 210, 'mobile': 280},
      {'date': '2024-05-16', 'desktop': 200, 'mobile': 300},
      {'date': '2024-05-17', 'desktop': 230, 'mobile': 320},
      {'date': '2024-05-18', 'desktop': 180, 'mobile': 250},
      {'date': '2024-05-19', 'desktop': 150, 'mobile': 235},
      {'date': '2024-05-20', 'desktop': 190, 'mobile': 277},
      {'date': '2024-05-21', 'desktop': 120, 'mobile': 182},
      {'date': '2024-05-22', 'desktop': 180, 'mobile': 281},
      {'date': '2024-05-23', 'desktop': 210, 'mobile': 290},
      {'date': '2024-05-24', 'desktop': 200, 'mobile': 294},
      {'date': '2024-05-25', 'desktop': 220, 'mobile': 301},
      {'date': '2024-05-26', 'desktop': 150, 'mobile': 213},
      {'date': '2024-05-27', 'desktop': 260, 'mobile': 360},
      {'date': '2024-05-28', 'desktop': 160, 'mobile': 233},
      {'date': '2024-05-29', 'desktop': 200, 'mobile': 278},
      {'date': '2024-05-30', 'desktop': 240, 'mobile': 340},
      {'date': '2024-05-31', 'desktop': 200, 'mobile': 278},
      {'date': '2024-06-01', 'desktop': 180, 'mobile': 278},
      {'date': '2024-06-02', 'desktop': 270, 'mobile': 370},
      {'date': '2024-06-03', 'desktop': 220, 'mobile': 303},
      {'date': '2024-06-04', 'desktop': 240, 'mobile': 339},
      {'date': '2024-06-05', 'desktop': 200, 'mobile': 288},
      {'date': '2024-06-06', 'desktop': 210, 'mobile': 294},
      {'date': '2024-06-07', 'desktop': 230, 'mobile': 323},
      {'date': '2024-06-08', 'desktop': 190, 'mobile': 285},
      {'date': '2024-06-09', 'desktop': 280, 'mobile': 380},
      {'date': '2024-06-10', 'desktop': 250, 'mobile': 355},
      {'date': '2024-06-11', 'desktop': 210, 'mobile': 292},
      {'date': '2024-06-12', 'desktop': 280, 'mobile': 392},
      {'date': '2024-06-13', 'desktop': 200, 'mobile': 281},
      {'date': '2024-06-14', 'desktop': 230, 'mobile': 326},
      {'date': '2024-06-15', 'desktop': 220, 'mobile': 307},
      {'date': '2024-06-16', 'desktop': 180, 'mobile': 271},
      {'date': '2024-06-17', 'desktop': 300, 'mobile': 420},
      {'date': '2024-06-18', 'desktop': 220, 'mobile': 307},
      {'date': '2024-06-19', 'desktop': 240, 'mobile': 341},
      {'date': '2024-06-20', 'desktop': 260, 'mobile': 350},
      {'date': '2024-06-21', 'desktop': 250, 'mobile': 369},
      {'date': '2024-06-22', 'desktop': 220, 'mobile': 317},
      {'date': '2024-06-23', 'desktop': 300, 'mobile': 430},
      {'date': '2024-06-24', 'desktop': 230, 'mobile': 332},
      {'date': '2024-06-25', 'desktop': 240, 'mobile': 341},
      {'date': '2024-06-26', 'desktop': 230, 'mobile': 334},
      {'date': '2024-06-27', 'desktop': 280, 'mobile': 390},
      {'date': '2024-06-28', 'desktop': 250, 'mobile': 349},
      {'date': '2024-06-29', 'desktop': 210, 'mobile': 303},
      {'date': '2024-06-30', 'desktop': 240, 'mobile': 346},
    ];
  }
}