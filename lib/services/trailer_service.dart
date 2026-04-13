import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trailerhustle_admin/models/trailer_data.dart';
import 'package:trailerhustle_admin/models/trailer_rating_data.dart';
import 'package:trailerhustle_admin/models/trailer_rating_summary.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';

class TrailerService {
  static const String trailersTable = 'Trailers';
  static const String brandsTable = 'Brands';
  static const String trailerTypesTable = 'TrailerTypes';
  // NOTE: This admin app manages "default trailer types" from the `TrailerTypes` table.
  // Older revisions of this project included a fallback that derived types from
  // `Brands` + `brandModel`. That path is intentionally removed so edits always
  // reflect `TrailerTypes`.
  static const String ratingsTable = 'ratings';
  static const String ratingTableLegacy = 'rating';
  static const String trailerImagesTable = 'trailerimages';

  /// Supabase Storage bucket used for trailer images.
  ///
  /// This should match the bucket name configured in Supabase Storage.
  /// The mobile app uploads to the 'images' bucket (not 'trailerimages' which
  /// is only the DB table name).
  static const String trailerImagesBucket = 'images';

  static String _contentTypeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  /// Best-effort: convert a trailer `image` field into a loadable URL.
  ///
  /// Supports:
  /// - Full URLs (https://...)
  /// - Supabase Storage paths stored in the DB (e.g. "trailers/abc.jpg")
  /// - Paths that accidentally include the bucket prefix ("trailerimages/...")
  static String resolveTrailerImageUrl(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;

    var path = v;
    path = path.replaceFirst(RegExp(r'^/+'), '');
    if (path.startsWith('$trailerImagesBucket/')) {
      path = path.substring(trailerImagesBucket.length + 1);
    }

    try {
      return SupabaseConfig.client.storage.from(trailerImagesBucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('TrailerService.resolveTrailerImageUrl failed for "$raw": $e');
      return raw;
    }
  }

  /// Upload an image to the [trailerImagesBucket] bucket and return a public URL.
  static Future<String> uploadTrailerImage({required Uint8List bytes, required String filename}) async {
    try {
      final safeFilename = filename.trim().isEmpty ? 'image.jpg' : filename.trim();
      final path = 'trailers/${DateTime.now().toUtc().millisecondsSinceEpoch}_$safeFilename';
      final storage = SupabaseConfig.client.storage.from(trailerImagesBucket);
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: _contentTypeFromFilename(safeFilename), upsert: true),
      );
      return storage.getPublicUrl(path);
    } catch (e) {
      debugPrint('TrailerService.uploadTrailerImage failed: $e');
      rethrow;
    }
  }

  /// Fetch all trailers.
  ///
  /// Soft-deleted rows (where `deletedAt` is non-null) are excluded.
  static Future<List<TrailerData>> fetchAllTrailers({int limit = 200}) async {
    try {
      final rows = await SupabaseService.from(trailersTable)
          .select('*')
          .isFilter('deletedAt', null)
          .order('updatedAt', ascending: false)
          .limit(limit);

      return (rows as List)
          .map((r) => TrailerData.fromJson((r as Map).cast<String, dynamic>()))
          .where((t) => t.id != 0)
          .toList(growable: false);
    } catch (e) {
      debugPrint('TrailerService.fetchAllTrailers failed: $e');
      rethrow;
    }
  }

  /// Fetch all trailers including soft-deleted ones.
  ///
  /// Used by admin views that need to display removed trailers with a status label.
  static Future<List<TrailerData>> fetchAllTrailersIncludingDeleted({int limit = 500}) async {
    try {
      final rows = await SupabaseService.from(trailersTable)
          .select('*')
          .order('updatedAt', ascending: false)
          .limit(limit);

      return (rows as List)
          .map((r) => TrailerData.fromJson((r as Map).cast<String, dynamic>()))
          .where((t) => t.id != 0)
          .toList(growable: false);
    } catch (e) {
      debugPrint('TrailerService.fetchAllTrailersIncludingDeleted failed: $e');
      rethrow;
    }
  }

  /// Fetch the newest (latest updated) image path/url for each trailer.
  ///
  /// Returns a map keyed by `trailerId`.
  static Future<Map<int, String>> fetchPrimaryTrailerImagesByTrailerIds({required List<int> trailerIds}) async {
    final ids = trailerIds.where((e) => e > 0).toSet().toList()..sort();
    if (ids.isEmpty) return const {};
    try {
      final rows = await SupabaseService.from(trailerImagesTable)
          .select('trailerId,image,updatedAt,deletedAt')
          .inFilter('trailerId', ids)
          .isFilter('deletedAt', null)
          .order('updatedAt', ascending: false);

      final out = <int, String>{};
      for (final r in (rows as List)) {
        final map = (r as Map).cast<String, dynamic>();
        final trailerIdRaw = map['trailerId'];
        final trailerId = trailerIdRaw is int
            ? trailerIdRaw
            : trailerIdRaw is num
                ? trailerIdRaw.toInt()
                : int.tryParse(trailerIdRaw?.toString() ?? '');
        if (trailerId == null || trailerId <= 0) continue;

        final image = (map['image'] ?? '').toString().trim();
        if (image.isEmpty) continue;

        // Because rows are ordered newest-first, first image wins.
        out.putIfAbsent(trailerId, () => image);
      }
      return out;
    } catch (e) {
      debugPrint('TrailerService.fetchPrimaryTrailerImagesByTrailerIds failed: $e');
      rethrow;
    }
  }

  /// Fetch trailer counts for many businesses in a single query.
  ///
  /// Returns a map keyed by `businessId` (the `Trailers.bussinessid` column).
  /// Soft-deleted rows (where `deletedAt` is non-null) are excluded.
  static Future<Map<int, int>> fetchTrailerCountsForBusinesses({required List<int> businessIds}) async {
    final ids = businessIds.toSet().toList()..sort();
    if (ids.isEmpty) return const {};
    try {
      final rows = await SupabaseService.from(trailersTable)
          .select('bussinessid,deletedAt')
          .inFilter('bussinessid', ids);

      final counts = <int, int>{};
      for (final r in (rows as List)) {
        final map = (r as Map).cast<String, dynamic>();
        final bidRaw = map['bussinessid'];
        final bid = bidRaw is int
            ? bidRaw
            : bidRaw is num
                ? bidRaw.toInt()
                : int.tryParse(bidRaw?.toString() ?? '');
        if (bid == null) continue;
        // Exclude soft-deleted trailers.
        if (map['deletedAt'] != null) continue;
        counts[bid] = (counts[bid] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugPrint('TrailerService.fetchTrailerCountsForBusinesses failed: $e');
      rethrow;
    }
  }

  static Future<List<TrailerData>> fetchTrailersForBusiness({required int businessId}) async {
    try {
      final rows = await SupabaseService.select(
        trailersTable,
        select: '*',
        filters: {'bussinessid': businessId},
        orderBy: 'updatedAt',
        ascending: false,
      );

      return rows
          .map((r) => TrailerData.fromJson(r))
          .where((t) => t.id != 0)
          .toList(growable: false);
    } catch (e) {
      debugPrint('TrailerService.fetchTrailersForBusiness failed: $e');
      rethrow;
    }
  }

  /// Fetch make (brand) titles for many brand IDs.
  ///
  /// This resolves `Trailers.brand` numeric IDs into readable names using the
  /// `Brands.title` column.
  static Future<Map<int, String>> fetchBrandTitlesByIds({required List<int> brandIds}) async {
    final ids = brandIds.where((e) => e > 0).toSet().toList()..sort();
    if (ids.isEmpty) return const {};
    try {
      // Note: `Brands.deletedAt` is camelCase in this project; keep this query
      // tolerant by not hard-filtering on it (it can require quoted identifiers).
      final rows = await SupabaseService.from(brandsTable).select('id,title').inFilter('id', ids);
      final out = <int, String>{};
      for (final r in (rows as List)) {
        final map = (r as Map).cast<String, dynamic>();
        final idRaw = map['id'];
        final id = idRaw is int ? idRaw : idRaw is num ? idRaw.toInt() : int.tryParse(idRaw?.toString() ?? '');
        if (id == null || id <= 0) continue;
        final title = (map['title'] ?? '').toString().trim();
        if (title.isEmpty) continue;
        out[id] = title;
      }
      return out;
    } catch (e) {
      debugPrint('TrailerService.fetchBrandTitlesByIds failed: $e');
      rethrow;
    }
  }

  /// Fetch all brands (make) options for dropdowns.
  static Future<Map<int, String>> fetchAllBrandTitles({int limit = 500}) async {
    try {
      final rows = await SupabaseService.from(brandsTable).select('id,title').order('title', ascending: true).limit(limit);
      final out = <int, String>{};
      for (final r in (rows as List)) {
        final map = (r as Map).cast<String, dynamic>();
        final idRaw = map['id'];
        final id = idRaw is int ? idRaw : idRaw is num ? idRaw.toInt() : int.tryParse(idRaw?.toString() ?? '');
        if (id == null || id <= 0) continue;
        final title = (map['title'] ?? '').toString().trim();
        if (title.isEmpty) continue;
        out[id] = title;
      }
      return out;
    } catch (e) {
      debugPrint('TrailerService.fetchAllBrandTitles failed: $e');
      rethrow;
    }
  }

  /// Fetch `Brands.is_published` values for a set of brand IDs.
  ///
  /// Returns a map keyed by brand id. If a brand is missing, it won't be
  /// present in the output.
  static Future<Map<int, bool>> fetchBrandPublishedByIds({required List<int> brandIds}) async {
    final ids = brandIds.where((e) => e > 0).toSet().toList()..sort();
    if (ids.isEmpty) return const {};
    try {
      final rows = await SupabaseService.from(brandsTable).select('id,is_published').inFilter('id', ids);
      final out = <int, bool>{};
      for (final r in (rows as List)) {
        final map = (r as Map).cast<String, dynamic>();
        final idRaw = map['id'];
        final id = idRaw is int ? idRaw : idRaw is num ? idRaw.toInt() : int.tryParse(idRaw?.toString() ?? '');
        if (id == null || id <= 0) continue;
        final v = map['is_published'];
        final published = v == null
            ? true
            : v is bool
                ? v
                : v is int
                    ? v == 1
                    : v is num
                        ? v.toInt() == 1
                        : (v.toString() == '1' || v.toString().toLowerCase() == 'true');
        out[id] = published;
      }
      return out;
    } catch (e) {
      debugPrint('TrailerService.fetchBrandPublishedByIds failed: $e');
      rethrow;
    }
  }

  /// Update an existing trailer.
  static Future<TrailerData> updateTrailer({required int trailerId, required Map<String, dynamic> data}) async {
    try {
      final payload = <String, dynamic>{...data, 'updatedAt': DateTime.now().toUtc().toIso8601String()};
      final rows = await SupabaseService.update(trailersTable, payload, filters: {'id': trailerId});
      if (rows.isEmpty) throw Exception('No trailer returned from update (id=$trailerId).');
      return TrailerData.fromJson(rows.first);
    } catch (e) {
      debugPrint('TrailerService.updateTrailer failed: $e');
      rethrow;
    }
  }

  /// Mark a brand (manufacturer/make) as published/unpublished.
  ///
  /// This is used by the admin review flow to approve trailers that are blocked
  /// because their make is not yet published.
  static Future<void> setBrandPublished({required int brandId, required bool published}) async {
    if (brandId <= 0) return;
    try {
      final payload = <String, dynamic>{
        'is_published': published,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      try {
        await SupabaseService.update(brandsTable, payload, filters: {'id': brandId});
      } catch (e) {
        // Some schemas may not have updatedAt; fall back to only the publish flag.
        debugPrint('TrailerService.setBrandPublished primary update failed; retrying without updatedAt: $e');
        await SupabaseService.update(brandsTable, {'is_published': published}, filters: {'id': brandId});
      }
    } catch (e) {
      debugPrint('TrailerService.setBrandPublished failed: $e');
      rethrow;
    }
  }

  /// Fetch all trailer types.
  ///
  /// Soft-deleted rows (where `deletedAt` is non-null) are excluded.
  static Future<List<Map<String, dynamic>>> fetchAllTrailerTypes({int limit = 500}) async {
    try {
      final rows = await SupabaseService.from(trailerTypesTable)
          .select('*')
          .isFilter('deletedAt', null)
          .order('title', ascending: true)
          .limit(limit);

      return (rows as List).map((e) => (e as Map).cast<String, dynamic>()).toList(growable: false);
    } catch (e) {
      debugPrint('TrailerService.fetchAllTrailerTypes failed: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createTrailerType({required String title, required bool isPublished}) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final payload = <String, dynamic>{
        'title': title.trim(),
        'is_published': isPublished ? 1 : 0,
        'createdAt': now,
        'updatedAt': now,
      };
      final rows = await SupabaseService.insert(trailerTypesTable, payload);
      if (rows.isEmpty) throw Exception('No trailer type returned from insert.');
      return rows.first;
    } catch (e) {
      debugPrint('TrailerService.createTrailerType failed: $e');
      rethrow;
    }
  }


  /// Legacy signature kept to avoid churn in older UI code.
  ///
  /// The current schema for `TrailerTypes` contains only `title` + `is_published`
  /// (plus audit columns). Manufacturer/model/rating are ignored.
  static Future<Map<String, dynamic>> createTrailerTypeV2({
    required String title,
    required bool isPublished,
    required String manufacturer,
    required String model,
    required double? rating,
  }) async => createTrailerType(title: title, isPublished: isPublished);

  static Future<Map<String, dynamic>> updateTrailerType({required int typeId, required Map<String, dynamic> data}) async {
    try {
      final payload = <String, dynamic>{...data, 'updatedAt': DateTime.now().toUtc().toIso8601String()};
      final rows = await SupabaseService.update(trailerTypesTable, payload, filters: {'id': typeId});
      if (rows.isEmpty) throw Exception('No trailer type returned from update (id=$typeId).');
      return rows.first;
    } catch (e) {
      debugPrint('TrailerService.updateTrailerType failed: $e');
      rethrow;
    }
  }

  static Future<void> softDeleteTrailerType({required int typeId}) async {
    try {
      await TrailerService.updateTrailerType(typeId: typeId, data: {'deletedAt': DateTime.now().toUtc().toIso8601String()});
    } catch (e) {
      debugPrint('TrailerService.softDeleteTrailerType failed: $e');
      rethrow;
    }
  }

  /// Fetch ratings for a trailer.
  ///
  /// This project contains both `ratings` and `rating` tables in the generated
  /// types. We query `ratings` first, then fall back to `rating`.
  static Future<List<TrailerRatingData>> fetchRatingsForTrailer({required int trailerId, int limit = 200}) async {
    Future<List<TrailerRatingData>> query(String table) async {
      const trailerIdColumns = ['trailerId', 'trailer_id', 'trailerid'];
      const createdAtColumns = ['createdAt', 'created_at'];

      // PostgREST requires quoting identifiers with uppercase letters
      // (camelCase columns). Without quotes, Postgres folds them to lowercase.
      String qCol(String col) => RegExp(r'[A-Z]').hasMatch(col) ? '"$col"' : col;

      dynamic lastError;
      for (final col in trailerIdColumns) {
        try {
          var q = SupabaseService.from(table).select('*').eq(qCol(col), trailerId).limit(limit);
          // Ordering by a missing column throws; try a couple common conventions.
          for (final orderCol in createdAtColumns) {
            try {
              q = q.order(qCol(orderCol), ascending: false);
              break;
            } catch (_) {
              // ignore and try next
            }
          }

          final rows = await q;
          final parsed = (rows as List)
              .map((r) => TrailerRatingData.fromJson((r as Map).cast<String, dynamic>()))
              .where((x) => x.id != 0)
              .toList(growable: false);

          // If the query executed successfully, the column exists.
          // Return immediately even if the result is empty, otherwise later
          // fallback attempts (e.g. `trailerid`) can throw and mask the valid
          // empty response.
          return parsed;
        } catch (e) {
          lastError = e;
        }
      }

      if (lastError != null) throw lastError;
      return const <TrailerRatingData>[];
    }

    try {
      return await query(ratingsTable);
    } catch (e) {
      debugPrint('TrailerService.fetchRatingsForTrailer primary table failed: $e');
      try {
        return await query(ratingTableLegacy);
      } catch (e2) {
        debugPrint('TrailerService.fetchRatingsForTrailer legacy table failed: $e2');
        rethrow;
      }
    }
  }

  /// Fetch rating summaries (count + average) for a set of trailers.
  ///
  /// This runs a single query (per table) and aggregates client-side to avoid
  /// per-row fetches.
  static Future<Map<int, TrailerRatingSummary>> fetchRatingSummariesForTrailers({required List<int> trailerIds}) async {
    final ids = trailerIds.where((e) => e > 0).toSet().toList()..sort();
    if (ids.isEmpty) return const {};

    Future<Map<int, TrailerRatingSummary>> query(String table) async {
      const trailerIdColumns = ['trailerId', 'trailer_id', 'trailerid'];
      const avgColumns = ['rating_average', 'ratingAverage', 'ratingAvg', 'avgRating'];
      const overallColumns = ['overall_quality', 'overallQuality', 'overall'];

      String qCol(String col) => RegExp(r'[A-Z]').hasMatch(col) ? '"$col"' : col;

      int? parseInt(dynamic v) {
        if (v == null) return null;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString());
      }

      double? parseDouble(dynamic v) {
        if (v == null) return null;
        if (v is double) return v;
        if (v is int) return v.toDouble();
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString());
      }

      dynamic lastError;
      for (final trailerIdCol in trailerIdColumns) {
        try {
          final rows = await SupabaseService.from(table).select('*').inFilter(qCol(trailerIdCol), ids).limit(5000);
          final sumByTrailer = <int, double>{};
          final countByTrailer = <int, int>{};
          for (final r in (rows as List)) {
            final map = (r as Map).cast<String, dynamic>();
            // When the DB column is camelCase, PostgREST returns JSON keys
            // without the surrounding quotes, so we still read from the raw
            // (unquoted) column name.
            final tid = parseInt(map[trailerIdCol]);
            if (tid == null || tid <= 0) continue;

            double? avg;
            for (final k in avgColumns) {
              if (!map.containsKey(k)) continue;
              avg = parseDouble(map[k]);
              if (avg != null) break;
            }
            if (avg == null || avg <= 0) {
              for (final k in overallColumns) {
                if (!map.containsKey(k)) continue;
                final o = parseDouble(map[k]);
                if (o != null && o > 0) {
                  avg = o;
                  break;
                }
              }
            }
            if (avg == null || avg <= 0) continue;
            sumByTrailer[tid] = (sumByTrailer[tid] ?? 0) + avg;
            countByTrailer[tid] = (countByTrailer[tid] ?? 0) + 1;
          }

          final out = <int, TrailerRatingSummary>{};
          for (final id in ids) {
            final c = countByTrailer[id] ?? 0;
            final s = sumByTrailer[id] ?? 0;
            out[id] = TrailerRatingSummary(trailerId: id, count: c, average: c == 0 ? 0 : (s / c));
          }

          // Once the query executes, the column is valid.
          // Return immediately to avoid later fallback column attempts throwing.
          return out;
        } catch (e) {
          lastError = e;
        }
      }

      if (lastError != null) throw lastError;
      return const {};
    }

    try {
      return await query(ratingsTable);
    } catch (e) {
      debugPrint('TrailerService.fetchRatingSummariesForTrailers primary table failed: $e');
      try {
        return await query(ratingTableLegacy);
      } catch (e2) {
        debugPrint('TrailerService.fetchRatingSummariesForTrailers legacy table failed: $e2');
        rethrow;
      }
    }
  }
}
