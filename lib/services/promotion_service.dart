import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trailerhustle_admin/models/promotion.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';

class PromotionService {
  static const _table = 'promotions';
  static const _eventsTable = 'promotion_events';
  static const _bucket = 'images';

  static final ValueNotifier<List<Promotion>> promotions =
      ValueNotifier(const []);
  static final ValueNotifier<bool> isLoading = ValueNotifier(false);
  static final ValueNotifier<String?> lastError = ValueNotifier(null);

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  static Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;
    lastError.value = null;
    try {
      final rows = await SupabaseConfig.client
          .from(_table)
          .select('*')
          .order('created_at', ascending: false);

      // Collect sponsor business ids and do a single batch lookup
      final ids = (rows as List)
          .map((r) => r['sponsor_business_id'])
          .whereType<int>()
          .toSet()
          .toList();

      Map<int, String> names = {};
      if (ids.isNotEmpty) {
        try {
          final bizRows = await SupabaseConfig.client
              .from('Businesses')
              .select('id, display_name, businessName, name')
              .inFilter('id', ids);
          for (final b in (bizRows as List)) {
            final id = b['id'] as int;
            final name = (b['display_name'] ?? b['businessName'] ?? b['name'] ?? '').toString().trim();
            names[id] = name;
          }
        } catch (_) {}
      }

      promotions.value = (rows).map((r) {
        final m = Map<String, dynamic>.from(r as Map);
        // Resolve image_path → public URL when image_url not set
        if ((m['image_url'] == null || (m['image_url'] as String).isEmpty) &&
            m['image_path'] != null &&
            (m['image_path'] as String).isNotEmpty) {
          m['image_url'] = SupabaseConfig.client.storage
              .from(_bucket)
              .getPublicUrl(m['image_path'] as String);
        }
        final bizId = m['sponsor_business_id'] as int?;
        return Promotion.fromRow(m,
            sponsorName: bizId != null ? names[bizId] : null);
      }).toList();
    } catch (e) {
      lastError.value = e.toString();
      debugPrint('PromotionService.refresh failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------------

  static Future<Promotion> createPromotion({
    required String title,
    required int sponsorBusinessId,
    required Uint8List imageBytes,
    required String imageFilename,
    String? externalUrl,
    required DateTime startAt,
    required DateTime endAt,
    int weight = 1,
    bool isActive = true,
  }) async {
    // 1) Upload to a temp path first (we don't know the id yet)
    final tmpPath = _tmpPath(imageFilename);
    final storage = SupabaseConfig.client.storage.from(_bucket);
    await storage.uploadBinary(
      tmpPath,
      imageBytes,
      fileOptions: FileOptions(
        contentType: _contentType(imageFilename),
        upsert: true,
      ),
    );

    // 2) Insert row with temp path
    final inserted = await SupabaseConfig.client
        .from(_table)
        .insert({
          'title': title,
          'sponsor_business_id': sponsorBusinessId,
          'image_path': tmpPath,
          'image_url': storage.getPublicUrl(tmpPath),
          'external_url': externalUrl?.trim().isEmpty == true ? null : externalUrl?.trim(),
          'start_at': startAt.toUtc().toIso8601String(),
          'end_at': endAt.toUtc().toIso8601String(),
          'is_active': isActive,
          'weight': weight,
          'created_by': SupabaseConfig.auth.currentUser?.id,
        })
        .select()
        .single();

    final newId = inserted['id'].toString();
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final ext = _ext(imageFilename);
    final finalPath = 'promotions/$newId/cover_$ts.$ext';

    // 3) Move to final path (copy + delete tmp)
    String finalUrl;
    try {
      await storage.copy(tmpPath, finalPath);
      await storage.remove([tmpPath]);
      finalUrl = storage.getPublicUrl(finalPath);
    } catch (_) {
      // If copy fails, keep using temp path
      finalPath == tmpPath;
      finalUrl = storage.getPublicUrl(tmpPath);
    }

    // 4) Update row with final path
    await SupabaseConfig.client.from(_table).update({
      'image_path': finalPath,
      'image_url': finalUrl,
    }).eq('id', int.parse(newId));

    await refresh();
    return promotions.value.firstWhere((p) => p.id == newId,
        orElse: () => Promotion.fromRow({
              ...inserted,
              'image_path': finalPath,
              'image_url': finalUrl,
            }));
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  static Future<void> updatePromotion(
    String id, {
    String? title,
    String? externalUrl,
    DateTime? startAt,
    DateTime? endAt,
    bool? isActive,
    int? weight,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (externalUrl != null) {
      updates['external_url'] =
          externalUrl.trim().isEmpty ? null : externalUrl.trim();
    }
    if (startAt != null) updates['start_at'] = startAt.toUtc().toIso8601String();
    if (endAt != null) updates['end_at'] = endAt.toUtc().toIso8601String();
    if (isActive != null) updates['is_active'] = isActive;
    if (weight != null) updates['weight'] = weight;

    if (imageBytes != null && imageFilename != null) {
      final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
      final ext = _ext(imageFilename);
      final path = 'promotions/$id/cover_$ts.$ext';
      final storage = SupabaseConfig.client.storage.from(_bucket);
      await storage.uploadBinary(
        path,
        imageBytes,
        fileOptions: FileOptions(contentType: _contentType(imageFilename), upsert: true),
      );
      updates['image_path'] = path;
      updates['image_url'] = storage.getPublicUrl(path);
    }

    if (updates.isNotEmpty) {
      await SupabaseConfig.client
          .from(_table)
          .update(updates)
          .eq('id', int.parse(id));
    }
    await refresh();
  }

  // ---------------------------------------------------------------------------
  // Archive / Delete
  // ---------------------------------------------------------------------------

  static Future<void> archivePromotion(String id) async {
    await SupabaseConfig.client
        .from(_table)
        .update({'is_active': false})
        .eq('id', int.parse(id));
    await refresh();
  }

  static Future<void> deletePromotion(String id) async {
    await SupabaseConfig.client
        .from(_table)
        .delete()
        .eq('id', int.parse(id));
    await refresh();
  }

  // ---------------------------------------------------------------------------
  // Stats
  // ---------------------------------------------------------------------------

  static Future<PromotionStats> getStats(String promotionId) async {
    try {
      final pid = int.parse(promotionId);

      Future<int> count(String type) async {
        final res = await SupabaseConfig.client
            .from(_eventsTable)
            .select('id')
            .eq('promotion_id', pid)
            .eq('event_type', type);
        return (res as List).length;
      }

      final results = await Future.wait([
        count('impression'),
        count('skip'),
        count('close'),
        count('image_click'),
        count('profile_click'),
      ]);

      // Avg dwell
      final dwellRows = await SupabaseConfig.client
          .from(_eventsTable)
          .select('dwell_ms')
          .eq('promotion_id', pid)
          .not('dwell_ms', 'is', null);

      double avgDwell = 0;
      if ((dwellRows as List).isNotEmpty) {
        final total = dwellRows.fold<int>(
            0, (s, r) => s + ((r['dwell_ms'] as int?) ?? 0));
        avgDwell = total / dwellRows.length / 1000.0;
      }

      return PromotionStats(
        impressions: results[0],
        skips: results[1],
        closes: results[2],
        imageClicks: results[3],
        profileClicks: results[4],
        avgDwellSeconds: avgDwell,
      );
    } catch (e) {
      debugPrint('PromotionService.getStats failed: $e');
      return PromotionStats.empty;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static List<Promotion> getActive() =>
      promotions.value.where((p) => p.isLive).toList();

  static List<Promotion> getScheduled() =>
      promotions.value.where((p) => p.isScheduled).toList();

  static List<Promotion> getArchived() =>
      promotions.value.where((p) => p.isArchived).toList();

  static String _tmpPath(String filename) {
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    return 'promotions/_tmp/${ts}_${filename.replaceAll(' ', '_')}';
  }

  static String _ext(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length - 1) return 'jpg';
    return filename.substring(dot + 1).toLowerCase();
  }

  static String _contentType(String filename) {
    switch (_ext(filename)) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
