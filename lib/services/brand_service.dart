import 'package:flutter/foundation.dart';
import 'package:trailerhustle_admin/models/brand_data.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';

class BrandService {
  static const String brandsTable = 'Brands';

  /// Fetch all manufacturers (brands).
  ///
  /// Soft-deleted rows (where `deletedAt` is non-null) are best-effort filtered
  /// out when the column exists.
  static Future<List<BrandData>> fetchAllBrands({int limit = 2000}) async {
    try {
      dynamic query = SupabaseService.from(brandsTable).select('*').order('title', ascending: true).limit(limit);
      // Best-effort filter for soft delete if the column exists.
      // If it doesn't exist, Supabase will throw; we recover by retrying.
      try {
        query = query.isFilter('deletedAt', null);
      } catch (_) {}

      final rows = await query;
      return (rows as List)
          .map((r) => BrandData.fromJson((r as Map).cast<String, dynamic>()))
          .where((b) => b.id > 0)
          .toList(growable: false);
    } catch (e) {
      debugPrint('BrandService.fetchAllBrands failed: $e');
      // Retry without filters if the schema differs.
      try {
        final rows = await SupabaseService.from(brandsTable).select('*').order('title', ascending: true).limit(limit);
        return (rows as List)
            .map((r) => BrandData.fromJson((r as Map).cast<String, dynamic>()))
            .where((b) => b.id > 0)
            .toList(growable: false);
      } catch (e2) {
        debugPrint('BrandService.fetchAllBrands retry failed: $e2');
        rethrow;
      }
    }
  }

  /// Update a manufacturer's published/unpublished status.
  ///
  /// This is resilient to differing schemas (snake_case vs camelCase columns).
  static Future<void> setBrandPublished({required int brandId, required bool isPublished}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await SupabaseService.from(brandsTable)
          .update({'is_published': isPublished ? 1 : 0, 'updated_at': now})
          .eq('id', brandId);
    } catch (e) {
      debugPrint('BrandService.setBrandPublished primary update failed: $e');
      // Retry with camelCase schema.
      try {
        await SupabaseService.from(brandsTable)
            .update({'isPublished': isPublished, 'updatedAt': now})
            .eq('id', brandId);
      } catch (e2) {
        debugPrint('BrandService.setBrandPublished retry failed: $e2');
        rethrow;
      }
    }
  }
}
