import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trailerhustle_admin/models/admin_notification_data.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';

/// Service for fetching, streaming, and managing admin_notifications.
class AdminNotificationService {
  static const String _table = 'admin_notifications';

  /// Fetch a paginated slice of tracked notifications.
  /// Returns the page items AND the total matching count (for pagination controls).
  static Future<({List<AdminNotificationData> items, int total})>
      fetchPaginated({
    int? typeFilter,
    int page = 0,
    int pageSize = 25,
  }) async {
    try {
      var filterQuery = SupabaseConfig.client
          .from(_table)
          .select()
          .isFilter('deletedAt', null)
          .inFilter('type', AdminNotificationData.trackedTypes);

      if (typeFilter != null) {
        filterQuery = filterQuery.eq('type', typeFilter);
      }

      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await filterQuery
          .order('createdAt', ascending: false)
          .range(from, to)
          .count(CountOption.exact);

      final items = (response.data as List)
          .map((r) => AdminNotificationData.fromJson(
              (r as Map).cast<String, dynamic>()))
          .toList();

      return (items: items, total: response.count);
    } catch (e) {
      debugPrint('AdminNotificationService.fetchPaginated error: $e');
      return (items: <AdminNotificationData>[], total: 0);
    }
  }

  /// Lightweight summary: unread count and per-type totals across all pages.
  static Future<({int unread, Map<int, int> typeCounts})>
      fetchSummaryCounts() async {
    try {
      final rows = await SupabaseConfig.client
          .from(_table)
          .select('id, type, is_read')
          .isFilter('deletedAt', null)
          .inFilter('type', AdminNotificationData.trackedTypes);

      int unread = 0;
      final counts = <int, int>{};
      for (final r in rows as List) {
        final type = r['type'] as int;
        counts[type] = (counts[type] ?? 0) + 1;
        if ((r['is_read'] as int) == 0) unread++;
      }
      return (unread: unread, typeCounts: counts);
    } catch (e) {
      debugPrint('AdminNotificationService.fetchSummaryCounts error: $e');
      return (unread: 0, typeCounts: <int, int>{});
    }
  }

  /// Mark a single notification as read.
  static Future<void> markAsRead(int notificationId) async {
    try {
      await SupabaseConfig.client
          .from(_table)
          .update({
            'is_read': 1,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('AdminNotificationService.markAsRead error: $e');
    }
  }

  /// Mark all tracked notifications as read.
  static Future<void> markAllAsRead() async {
    try {
      await SupabaseConfig.client
          .from(_table)
          .update({
            'is_read': 1,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          })
          .inFilter('type', AdminNotificationData.trackedTypes)
          .eq('is_read', 0);
    } catch (e) {
      debugPrint('AdminNotificationService.markAllAsRead error: $e');
    }
  }

  /// Soft-delete a notification.
  static Future<void> softDelete(int notificationId) async {
    try {
      await SupabaseConfig.client
          .from(_table)
          .update({
            'deletedAt': DateTime.now().toUtc().toIso8601String(),
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('AdminNotificationService.softDelete error: $e');
    }
  }

  /// Subscribe to real-time Postgres changes on admin_notifications.
  /// Calls [onChanged] whenever an INSERT, UPDATE, or DELETE occurs.
  static RealtimeChannel subscribeToChanges({
    required VoidCallback onChanged,
  }) {
    return SupabaseConfig.client
        .channel('admin_notifications_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _table,
          callback: (_) => onChanged(),
        )
        .subscribe();
  }
}
