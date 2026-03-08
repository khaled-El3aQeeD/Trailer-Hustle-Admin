import 'package:flutter/foundation.dart';
import 'package:trailerhustle_admin/models/sponsor_data.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';

class SponsorService {
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
}
