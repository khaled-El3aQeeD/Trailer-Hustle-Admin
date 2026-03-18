import 'package:flutter/foundation.dart';
import 'package:trailerhustle_admin/models/sponsor_data.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';

class SponsorService {
  static const String _table = 'Businesses';

  static const List<String> _businessesTableCandidates = [
    'Businesses',
    'businesses',
    'Business',
    'Businesse',
    'BUSINESSES',
  ];

  static final Map<int, SponsorData?> _cache = <int, SponsorData?>{};

  static void clearCache() => _cache.clear();

  static Future<SponsorData?> fetchSponsorById(int sponsorId) async {
    if (sponsorId <= 0) return null;
    if (_cache.containsKey(sponsorId)) return _cache[sponsorId];

    for (final table in _businessesTableCandidates) {
      try {
        final row = await SupabaseService.selectSingle(table, filters: {'id': sponsorId});
        if (row == null) {
          continue;
        }
        final sponsor = SponsorData.fromBusinessesRow(row);
        _cache[sponsorId] = sponsor;
        return sponsor;
      } catch (e) {
        // Try next candidate; log for visibility.
        debugPrint('SponsorService.fetchSponsorById: table=$table sponsorId=$sponsorId error=$e');
      }
    }

    _cache[sponsorId] = null;
    return null;
  }

  /// Search businesses by display_name with server-side pagination.
  /// Returns a list of [SponsorData] matching [query] (or all if empty),
  /// ordered alphabetically by display_name.
  static Future<List<SponsorData>> searchSponsors({
    String query = '',
    int offset = 0,
    int limit = 40,
  }) async {
    try {
      dynamic q = SupabaseConfig.client
          .from(_table)
          .select('*')
          .not('display_name', 'is', null)
          .neq('display_name', '');

      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        q = q.ilike('display_name', '%$trimmed%');
      }

      q = q.order('display_name', ascending: true);
      final rows = await q.range(offset, offset + limit - 1) as List;

      return rows
          .whereType<Map<String, dynamic>>()
          .map((r) => SponsorData.fromBusinessesRow(r))
          .toList(growable: false);
    } catch (e) {
      debugPrint('SponsorService.searchSponsors failed: $e');
      rethrow;
    }
  }
}
