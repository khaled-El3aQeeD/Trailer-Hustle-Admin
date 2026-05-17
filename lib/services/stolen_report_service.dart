import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trailerhustle_admin/models/stolen_report_data.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';

/// Status filter values for the stolen-trailers admin page.
enum StolenStatusFilter { pending, approved, retrieved, rejected, cancelled, all }

/// One admin-drawn alert circle (center + radius in miles).
typedef ZoneArg = ({double centerLat, double centerLng, double radiusMiles});

/// Service for fetching and moderating stolen trailer reports.
class StolenReportService {
  static const String _table = 'stolen_trailer_reports';
  static const String _trailersTable = 'Trailers';
  static const String _notifyEdgeFunction = 'notify-stolen-trailer-nearby';
  static const String _userNotificationsTable = 'notifications';
  static const String _appConfigTable = 'app_config';
  static const String _radiusConfigKey = 'stolen_alert_radius_miles';
  static const int _defaultAlertRadiusFallback = 800;
  static const int _userNotificationTypeStolen = 14;

  /// Read the geofence radius the edge function will use when an admin
  /// triggers a radius-mode send without an explicit override. Mirrors the
  /// edge function's `app_config` lookup so the admin UI can preview the
  /// value and warn before firing.
  static Future<int> getDefaultAlertRadiusMiles() async {
    try {
      final rows = await SupabaseConfig.client
          .from(_appConfigTable)
          .select('value')
          .eq('key', _radiusConfigKey)
          .eq('is_enabled', true)
          .limit(1);
      if ((rows as List).isEmpty) return _defaultAlertRadiusFallback;
      final v = int.tryParse(rows.first['value'].toString());
      if (v == null || v <= 0) return _defaultAlertRadiusFallback;
      return v;
    } catch (e) {
      debugPrint('StolenReportService.getDefaultAlertRadiusMiles error: $e');
      return _defaultAlertRadiusFallback;
    }
  }

  /// Fetch a paginated slice of reports.
  static Future<({List<StolenReportData> items, int total})> fetchPaginated({
    StolenStatusFilter status = StolenStatusFilter.pending,
    int page = 0,
    int pageSize = 25,
    String search = '',
  }) async {
    try {
      var q = SupabaseConfig.client.from(_table).select();

      switch (status) {
        case StolenStatusFilter.pending:
          q = q.eq('status', 'pending');
          break;
        case StolenStatusFilter.approved:
          q = q.eq('status', 'approved');
          break;
        case StolenStatusFilter.retrieved:
          q = q.eq('status', 'retrieved');
          break;
        case StolenStatusFilter.rejected:
          q = q.eq('status', 'rejected');
          break;
        case StolenStatusFilter.cancelled:
          q = q.eq('status', 'cancelled');
          break;
        case StolenStatusFilter.all:
          break;
      }

      final query = search.trim().isEmpty
          ? q
          : q.or(
              'trailer_name.ilike.%$search%,vin.ilike.%$search%,plate.ilike.%$search%,contact_name.ilike.%$search%',
            );

      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await query
          .order('created_at', ascending: false)
          .range(from, to)
          .count(CountOption.exact);

      final items = (response.data as List)
          .map((r) =>
              StolenReportData.fromJson((r as Map).cast<String, dynamic>()))
          .toList();
      return (items: items, total: response.count);
    } catch (e) {
      debugPrint('StolenReportService.fetchPaginated error: $e');
      return (items: <StolenReportData>[], total: 0);
    }
  }

  /// Counts per status — used for the summary tiles.
  static Future<Map<String, int>> fetchStatusCounts() async {
    try {
      final rows = await SupabaseConfig.client.from(_table).select('status');
      final counts = <String, int>{};
      for (final r in rows as List) {
        final s = (r['status'] as String?) ?? '';
        counts[s] = (counts[s] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugPrint('StolenReportService.fetchStatusCounts error: $e');
      return <String, int>{};
    }
  }

  /// Approve a pending report. The DB trigger will flip Trailers.is_stolen=1.
  /// Returns the approved report on success, null on failure.
  static Future<StolenReportData?> approve({
    required int reportId,
    required int adminUserId,
    String? adminNote,
  }) async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final updated = await SupabaseConfig.client
          .from(_table)
          .update({
            'status': 'approved',
            'reviewed_by': adminUserId,
            'reviewed_at': nowIso,
            'approved_at': nowIso,
            if (adminNote != null && adminNote.trim().isNotEmpty)
              'admin_note': adminNote.trim(),
          })
          .eq('id', reportId)
          .eq('status', 'pending')
          .select()
          .maybeSingle();
      if (updated == null) return null;
      final report = StolenReportData.fromJson(
          Map<String, dynamic>.from(updated as Map));
      // Notify the reporter that their report was approved.
      await _notifyReporter(
        reporterId: report.reporterId,
        trailerId: report.trailerId,
        title: 'Stolen trailer report approved',
        body:
            'Your report for ${report.displayName} has been approved. Nearby users will be alerted.',
      );
      return report;
    } catch (e) {
      debugPrint('StolenReportService.approve error: $e');
      return null;
    }
  }

  /// Reject a pending report.
  static Future<bool> reject({
    required int reportId,
    required int adminUserId,
    String? adminNote,
  }) async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final updated = await SupabaseConfig.client
          .from(_table)
          .update({
            'status': 'rejected',
            'reviewed_by': adminUserId,
            'reviewed_at': nowIso,
            if (adminNote != null && adminNote.trim().isNotEmpty)
              'admin_note': adminNote.trim(),
          })
          .eq('id', reportId)
          .eq('status', 'pending')
          .select()
          .maybeSingle();
      if (updated == null) return false;
      final report = StolenReportData.fromJson(
          Map<String, dynamic>.from(updated as Map));
      await _notifyReporter(
        reporterId: report.reporterId,
        trailerId: report.trailerId,
        title: 'Stolen trailer report rejected',
        body: adminNote == null || adminNote.trim().isEmpty
            ? 'Your report for ${report.displayName} was rejected.'
            : 'Your report for ${report.displayName} was rejected: ${adminNote.trim()}',
      );
      return true;
    } catch (e) {
      debugPrint('StolenReportService.reject error: $e');
      return false;
    }
  }

  /// Mark an approved report as retrieved. Trigger flips Trailers.is_stolen=0.
  static Future<bool> markRetrieved({
    required int reportId,
    required int adminUserId,
  }) async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final updated = await SupabaseConfig.client
          .from(_table)
          .update({
            'status': 'retrieved',
            'retrieved_at': nowIso,
            'reviewed_by': adminUserId,
          })
          .eq('id', reportId)
          .eq('status', 'approved')
          .select()
          .maybeSingle();
      if (updated == null) return false;
      final report = StolenReportData.fromJson(
          Map<String, dynamic>.from(updated as Map));
      await _notifyReporter(
        reporterId: report.reporterId,
        trailerId: report.trailerId,
        title: 'Trailer marked as retrieved',
        body:
            '${report.displayName} has been marked as retrieved. Public stolen flag cleared.',
      );
      return true;
    } catch (e) {
      debugPrint('StolenReportService.markRetrieved error: $e');
      return false;
    }
  }

  /// Trigger the alert push fan-out for an approved report.
  /// Returns the edge-function summary or null on failure.
  ///
  /// [zones]: optional admin-drawn circles. If non-empty, the edge function
  /// notifies any user inside ANY zone (union). If null/empty, the function
  /// falls back to radius mode around the report's stolen location.
  /// [includeReporter]: test-only flag. When true, the reporter's own device
  /// is also included in the fan-out so the admin can verify push delivery
  /// using the same account that filed the report.
  /// [dryRun]: test-only flag. When true, the function counts targets but
  /// does NOT insert any notification rows.
  static Future<({int totalTargets, int totalSent, int totalFailed})?>
      notifyNearby({
    required int reportId,
    int? radiusMilesOverride,
    bool includeReporter = false,
    bool dryRun = false,
    List<ZoneArg>? zones,
  }) async {
    try {
      final body = <String, dynamic>{
        'report_id': reportId,
        if (radiusMilesOverride != null) 'radius_miles': radiusMilesOverride,
        if (includeReporter) 'bypass_reporter_exclusion': true,
        if (dryRun) 'dry_run': true,
        if (zones != null && zones.isNotEmpty)
          'zones': zones
              .map((z) => {
                    'center_lat': z.centerLat,
                    'center_lng': z.centerLng,
                    'radius_miles': z.radiusMiles,
                  })
              .toList(),
      };
      final response = await SupabaseConfig.client.functions.invoke(
        _notifyEdgeFunction,
        body: body,
      );
      if (response.status != 200) {
        debugPrint(
            'notify-stolen-trailer-nearby returned ${response.status}: ${response.data}');
        return null;
      }
      final data = response.data as Map<String, dynamic>;
      return (
        totalTargets: (data['total_targets'] as int?) ?? 0,
        totalSent: (data['total_sent'] as int?) ?? 0,
        totalFailed: (data['total_failed'] as int?) ?? 0,
      );
    } catch (e) {
      debugPrint('StolenReportService.notifyNearby error: $e');
      return null;
    }
  }

  /// Insert a notification row for the reporter. The existing
  /// notify-business-fcm webhook handles FCM delivery on insert.
  static Future<void> _notifyReporter({
    required int reporterId,
    required int trailerId,
    required String title,
    required String body,
  }) async {
    try {
      final now =
          DateTime.now().toIso8601String().replaceFirst('T', ' ').replaceAll('Z', '');
      await SupabaseConfig.client.from(_userNotificationsTable).insert({
        'user_id': 0,
        'receiver_id': reporterId,
        'trailerId': trailerId,
        'notification_type': _userNotificationTypeStolen,
        'title': title,
        'description': body,
        'is_read': 0,
        'createdAt': now,
        'updatedAt': now,
      });
    } catch (e) {
      debugPrint('StolenReportService._notifyReporter failed silently: $e');
    }
  }

  /// Subscribe to real-time changes (insert/update) on the table.
  static RealtimeChannel subscribeToChanges({
    required VoidCallback onChanged,
  }) {
    return SupabaseConfig.client
        .channel('stolen_trailer_reports_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _table,
          callback: (_) => onChanged(),
        )
        .subscribe();
  }

  /// Direct check used by the page to confirm Trailers.is_stolen actually flipped
  /// (helps surface a clear error if the DB trigger isn't installed for any reason).
  static Future<int?> trailerIsStolenFlag(int trailerId) async {
    try {
      final row = await SupabaseConfig.client
          .from(_trailersTable)
          .select('is_stolen')
          .eq('id', trailerId)
          .maybeSingle();
      if (row == null) return null;
      final v = row['is_stolen'];
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '');
    } catch (e) {
      return null;
    }
  }
}
