import 'package:flutter/foundation.dart';
import 'package:trailerhustle_admin/models/service_item_data.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';

class ServiceItemService {
  // Supabase table names are case-sensitive when quoted.
  // Many projects use lowercase `services`, but some legacy schemas used `Services`.
  static const List<String> servicesTables = ['services', 'Services'];

  static Future<List<ServiceItemData>> fetchServicesForBusiness({required int businessId}) async {
    try {
      // Some schemas use the misspelling `bussinessid` (as in Trailers),
      // others use `businessid`/`business_id`. We try the most likely options.
      final rows = await _selectByAnyBusinessId(
        businessId,
        orderByCandidates: const ['updatedAt', 'updated_at', 'createdAt', 'created_at'],
      );

      return rows.map((r) => ServiceItemData.fromJson(r)).where((s) => s.id != 0).toList(growable: false);
    } catch (e) {
      debugPrint('ServiceItemService.fetchServicesForBusiness failed: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> _selectByAnyBusinessId(
    int businessId, {
    required List<String> orderByCandidates,
  }) async {
    const idKeys = <String>['bussinessid', 'businessid', 'business_id', 'businessId'];

    Object? lastError;
    for (final table in servicesTables) {
      for (final key in idKeys) {
        for (final orderBy in orderByCandidates) {
          try {
            return await SupabaseService.select(
              table,
              select: '*',
              filters: {key: businessId},
              orderBy: orderBy,
              ascending: false,
            );
          } catch (e) {
            lastError = e;
            // Try next table/key/order candidate.
          }
        }
      }
    }

    if (lastError != null) {
      throw lastError!;
    }
    return const <Map<String, dynamic>>[];
  }
}
