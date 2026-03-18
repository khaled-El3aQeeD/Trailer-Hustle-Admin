import 'package:flutter/foundation.dart';
import 'package:trailerhustle_admin/models/service_item_data.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';
import 'package:trailerhustle_admin/services/giveaway_service.dart';

/// Service for fetching actual products from the `Products` table.
///
/// The admin panel previously only queried the `services` table and tried
/// to split by `type`. Real products live in the separate `Products` table.
class ProductService {
  static const String _productsTable = 'Products';
  static const String _productImagesTable = 'product_images';

  /// Fetch all products for a given business from the `Products` table.
  static Future<List<ServiceItemData>> fetchProductsForBusiness({
    required int businessId,
  }) async {
    try {
      final rows = await SupabaseConfig.client
          .from(_productsTable)
          .select('*')
          .eq('bussinessid', businessId)
          .isFilter('deletedAt', null)
          .order('updatedAt', ascending: false);

      if (rows.isEmpty) return const <ServiceItemData>[];

      // Fetch product images
      final productIds = rows.map((r) => r['id'] as int).toList();
      final imageRows = await _fetchProductImages(productIds);

      return rows.map((r) => _mapProductToServiceItem(r, imageRows)).toList();
    } catch (e) {
      debugPrint('ProductService.fetchProductsForBusiness failed: $e');
      rethrow;
    }
  }

  /// Fetch product count for a given business.
  static Future<int> fetchProductCountForBusiness({
    required int businessId,
  }) async {
    try {
      final rows = await SupabaseConfig.client
          .from(_productsTable)
          .select('id')
          .eq('bussinessid', businessId)
          .isFilter('deletedAt', null);
      return rows.length;
    } catch (e) {
      debugPrint('ProductService.fetchProductCountForBusiness failed: $e');
      return 0;
    }
  }

  /// Fetch product counts for multiple businesses at once.
  static Future<Map<int, int>> fetchProductCountsForBusinesses(
    List<int> businessIds,
  ) async {
    if (businessIds.isEmpty) return const <int, int>{};
    try {
      final rows = await SupabaseConfig.client
          .from(_productsTable)
          .select('id, bussinessid')
          .inFilter('bussinessid', businessIds)
          .isFilter('deletedAt', null);

      final counts = <int, int>{};
      for (final r in rows) {
        final bId = r['bussinessid'] as int;
        counts[bId] = (counts[bId] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugPrint('ProductService.fetchProductCountsForBusinesses failed: $e');
      return const <int, int>{};
    }
  }

  static Future<Map<int, List<Map<String, dynamic>>>> _fetchProductImages(
    List<int> productIds,
  ) async {
    if (productIds.isEmpty) return const {};
    try {
      final rows = await SupabaseConfig.client
          .from(_productImagesTable)
          .select('id, product_id, image')
          .inFilter('product_id', productIds)
          .isFilter('deletedAt', null);

      final map = <int, List<Map<String, dynamic>>>{};
      for (final r in rows) {
        final pId = r['product_id'] as int;
        map.putIfAbsent(pId, () => []);
        map[pId]!.add(r);
      }
      return map;
    } catch (e) {
      debugPrint('ProductService._fetchProductImages failed: $e');
      return const {};
    }
  }

  /// Map a `Products` row to `ServiceItemData` so the UI can render it uniformly.
  static ServiceItemData _mapProductToServiceItem(
    Map<String, dynamic> r,
    Map<int, List<Map<String, dynamic>>> imagesByProduct,
  ) {
    final id = r['id'] as int;
    final images = imagesByProduct[id] ?? [];

    // Resolve the first product image to a full URL
    String imageUrl = '';
    if (images.isNotEmpty) {
      final raw = (images.first['image'] ?? '').toString().trim();
      if (raw.isNotEmpty) {
        imageUrl = GiveawayService.resolveStorageUrl(raw) ?? raw;
      }
    }

    return ServiceItemData(
      id: id,
      businessId: (r['bussinessid'] as int?) ?? 0,
      title: (r['productName'] ?? 'Untitled product').toString().trim(),
      description: (r['description'] ?? '').toString().trim(),
      image: imageUrl,
      price: 0,
      currency: 'USD',
      type: 'product',
      isActive: r['deletedAt'] == null,
      createdAt: ServiceItemData.parseDate(r['createdAt']),
      updatedAt: ServiceItemData.parseDate(r['updatedAt']),
    );
  }
}
