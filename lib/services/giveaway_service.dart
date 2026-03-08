import 'package:flutter/foundation.dart';
import 'package:trailerhustle_admin/models/giveaway.dart';
import 'package:trailerhustle_admin/models/giveaway_participant.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class GiveawayService {
  static final ValueNotifier<List<Giveaway>> giveaways = ValueNotifier(const []);
  static final ValueNotifier<bool> isLoading = ValueNotifier(false);
  static final ValueNotifier<String?> lastError = ValueNotifier(null);

  static const String _giveawaysTable = 'Giveaways';
  static const String _participantsTable = 'giveawayparticipants';
  static const String _usersTable = 'users';
  static const String _declareWinnersTable = 'declarewinners';

  /// Supabase Storage bucket used for giveaway cover images.
  ///
  /// If uploads fail with a “Bucket not found” error, create this bucket in the
  /// Supabase dashboard (Storage → New bucket) and ensure the current role has
  /// permission to upload.
  static const String giveawayImagesBucket = 'giveaway-images';
  // Some projects use different naming/casing for this table. We'll attempt several.
  // Note: user mentioned “Businesse” specifically, so we include that too.
  static const List<String> _businessesTableCandidates = [
    'businesses',
    'Businesses',
    'Business',
    'Businesse',
    'BUSINESSES',
  ];

  static String _contentTypeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  /// Upload an image to Supabase Storage and return a public URL.
  ///
  /// This is used by the admin UI so users can pick an image instead of manually
  /// pasting a URL.
  static Future<String> uploadGiveawayImage({required Uint8List bytes, required String filename}) async {
    try {
      final safeFilename = filename.trim().isEmpty ? 'image.jpg' : filename.trim();
      final path = 'giveaways/${DateTime.now().toUtc().millisecondsSinceEpoch}_$safeFilename';
      final storage = SupabaseConfig.client.storage.from(giveawayImagesBucket);
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: _contentTypeFromFilename(safeFilename), upsert: true),
      );
      return storage.getPublicUrl(path);
    } catch (e) {
      debugPrint('GiveawayService.uploadGiveawayImage failed: $e');
      rethrow;
    }
  }

  /// Fetch all giveaways + participants from Supabase and update [giveaways].
  static Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;
    lastError.value = null;
    try {
      String? _optString(dynamic v) {
        final s = (v ?? '').toString().trim();
        return s.isEmpty ? null : s;
      }

      int? _optInt(dynamic v) {
        if (v == null) return null;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString());
      }

      DateTime? _optDateTime(dynamic v) {
        if (v == null) return null;
        if (v is DateTime) return v;
        if (v is int) {
          // Best-effort: assume epoch seconds if it looks small, otherwise ms.
          final ms = v < 1000000000000 ? v * 1000 : v;
          return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
        }
        if (v is num) {
          final i = v.toInt();
          final ms = i < 1000000000000 ? i * 1000 : i;
          return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
        }
        final s = v.toString().trim();
        if (s.isEmpty) return null;
        return DateTime.tryParse(s);
      }

      String? _extractBusinessName(Map<String, dynamic> normalized) {
        // Prefer explicit business/company name fields, then a generic name.
        return _optString(
          normalized['business_name'] ??
              normalized['businessname'] ??
              normalized['company_name'] ??
              normalized['companyname'] ??
              normalized['business'] ??
              normalized['company'] ??
              normalized['display_name'] ??
              normalized['displayname'] ??
              normalized['name'] ??
              normalized['title'],
        );
      }

      Map<String, dynamic> _normalizeKeys(Map<String, dynamic> row) {
        final out = <String, dynamic>{};
        for (final e in row.entries) {
          out[e.key.toString()] = e.value;
          out[e.key.toString().toLowerCase()] = e.value;
        }
        return out;
      }

      String? _extractImageUrl(Map<String, dynamic> normalized) {
        // Accepts either a full URL or a best-effort string.
        // NOTE: If your schema stores a Storage *path* (e.g. "logos/123.png"),
        // we cannot reliably convert it to a public URL without knowing the bucket.
        return _optString(
          normalized['avatar_url'] ??
              normalized['avatar'] ??
              normalized['profile_photo'] ??
              normalized['profilephoto'] ??
              normalized['profile_image'] ??
              normalized['profileimage'] ??
              normalized['photo_url'] ??
              normalized['photourl'] ??
              normalized['image_url'] ??
              normalized['imageurl'] ??
              normalized['image'] ??
              normalized['cover_image'] ??
              normalized['coverimage'] ??
              normalized['logo_url'] ??
              normalized['logourl'] ??
              normalized['logo'] ??
              // Common camelCase variants (we still include them even though we add lowercase keys).
              normalized['logoUrl'] ??
              normalized['logoURL'] ??
              normalized['imageUrl'] ??
              normalized['imageURL'] ??
              normalized['photoUrl'] ??
              normalized['photoURL'] ??
              normalized['logo_path'] ??
              normalized['logopath'] ??
              normalized['logo_key'] ??
              normalized['logokey'],
        );
      }

      void _debugImageFieldsIfMissing({required String participantId, required Map<String, dynamic> business}) {
        try {
          final interesting = <String, String>{};
          for (final e in business.entries) {
            final k = e.key.toString();
            if (k != k.toLowerCase()) continue; // only the normalized lowercase view
            if (!(k.contains('logo') || k.contains('avatar') || k.contains('image') || k.contains('photo'))) continue;
            final v = _optString(e.value);
            if (v == null) continue;
            interesting[k] = v;
          }
          if (interesting.isNotEmpty) {
            debugPrint('GiveawayService.refresh: participant=$participantId business image fields found: $interesting');
          } else {
            debugPrint('GiveawayService.refresh: participant=$participantId business has no non-empty image fields (logo/avatar/image/photo).');
          }
        } catch (e) {
          debugPrint('GiveawayService.refresh: failed while debugging business image fields: $e');
        }
      }

      final rows = await SupabaseService.select(
        _giveawaysTable,
        select: '*',
        orderBy: 'createdAt',
        ascending: false,
      );

      debugPrint('GiveawayService.refresh: fetched ${rows.length} giveaways');

      final ids = rows.map((r) => r['id']).where((v) => v != null).toList(growable: false);
      final participantsByGiveawayId = <String, List<GiveawayParticipant>>{};

      // declarewinners (giveawayId -> businessId). We prefer this as the winner source of truth.
      final declaredWinnerBusinessIdByGiveawayId = <String, String>{};

      // Tracks a business reference found on participant rows (if present).
      final participantBusinessIdByUserId = <String, String>{};

      // Best-effort user profile enrichment: id -> row from `public.users`.
      final userProfileById = <String, Map<String, dynamic>>{};
      // Best-effort business enrichment: by business id and by user id.
      final businessById = <String, Map<String, dynamic>>{};
      final businessByUserId = <String, Map<String, dynamic>>{};

      if (ids.isNotEmpty) {
        // Best-effort: fetch winners from `declarewinners`.
        // This allows the Archive tab to display winners even if Giveaways.winnerUserId
        // is null/out-of-sync.
        try {
          final declareRows = await SupabaseConfig.client
              .from(_declareWinnersTable)
              .select('*')
              .inFilter('giveawayId', ids)
              .order('updatedAt', ascending: false);

          for (final dr in (declareRows as List).whereType<Map>()) {
            final map = _normalizeKeys(dr.map((k, v) => MapEntry(k.toString(), v)));
            final giveawayId = _optString(map['giveawayid'] ?? map['giveaway_id'] ?? map['giveawayId']);
            final businessId = _optString(map['businessid'] ?? map['business_id'] ?? map['businessId']);
            if (giveawayId == null || businessId == null) continue;

            // Keep the most recently updated row (query is ordered desc).
            declaredWinnerBusinessIdByGiveawayId.putIfAbsent(giveawayId, () => businessId);
          }

          if (declaredWinnerBusinessIdByGiveawayId.isNotEmpty) {
            debugPrint(
              'GiveawayService.refresh: declarewinners found for ${declaredWinnerBusinessIdByGiveawayId.length} giveaways',
            );
          }
        } catch (e) {
          debugPrint('GiveawayService.refresh: failed to fetch declarewinners: $e');
        }

        final participantsRows = await SupabaseConfig.client
            .from(_participantsTable)
            .select('*')
            .inFilter('giveAwayId', ids);

        debugPrint('GiveawayService.refresh: fetched ${(participantsRows as List).length} participants');

        final participantUserIds = <String>{};
        // Some schemas store business IDs as ints (as in your generated types).
        final participantBusinessIdsInt = <int>{};

        var loggedParticipantShape = false;
        for (final pr in (participantsRows as List).whereType<Map>()) {
          final map = _normalizeKeys(pr.map((k, v) => MapEntry(k.toString(), v)));
          if (!loggedParticipantShape) {
            loggedParticipantShape = true;
            debugPrint(
              'GiveawayService.refresh: participant row keys sample: ${map.keys.where((k) => k == k.toLowerCase()).take(30).toList()}…',
            );
          }
          final giveawayId = (map['giveAwayId'] ?? map['giveawayid'] ?? map['giveaway_id'] ?? '').toString();
          final userId = (map['userId'] ?? map['userid'] ?? map['user_id'] ?? '').toString();
          if (giveawayId.isEmpty || userId.isEmpty) continue;
          participantUserIds.add(userId);

          // In this project’s generated Supabase types, giveawayparticipants.userId is a number.
          // That often means it actually references Businesses.id (also a number) rather than auth.users.
          // We treat it as a potential business id as a fallback.
          final participantUserIdInt = _optInt(map['userId'] ?? map['userid'] ?? map['user_id']);
          if (participantUserIdInt != null) participantBusinessIdsInt.add(participantUserIdInt);

          // Some schemas store a business reference on the participant record.
          final businessId = _optString(
            map['businessId'] ??
                map['business_id'] ??
                map['businessID'] ??
                map['business'] ??
                map['businessesId'] ??
                map['businesses_id'],
          );
          if (businessId != null) {
            final businessIdInt = _optInt(businessId);
            if (businessIdInt != null) participantBusinessIdsInt.add(businessIdInt);
            participantBusinessIdByUserId[userId] = businessId;
          }

          // Prefer business/company name stored on the participant record (if present).
          // Different Supabase schemas name this differently; we support common variants.
          final rowCompany = _optString(
            map['companyName'] ??
                map['company_name'] ??
                map['businessName'] ??
                map['business_name'] ??
                map['company'] ??
                map['business'],
          );

          // Some schemas store contact info on the participant record itself.
          final rowEmail = _optString(map['email']);
          final rowPhone = _optString(map['phone'] ?? map['phone_number'] ?? map['mobile']);

          // Date/time participant entered the giveaway.
          final enteredAt =
              _optDateTime(map['entered_at'] ?? map['enteredat'] ?? map['created_at'] ?? map['createdat'] ?? map['createdAt'] ?? map['createdat'] ?? map['inserted_at'] ?? map['insertedat']);
          final rowAvatar = _optString(
            map['avatar_url'] ??
                map['avatar'] ??
                map['photo_url'] ??
                map['profile_photo'] ??
                map['profilephoto'] ??
                map['profile_image'] ??
                map['profileimage'] ??
                map['image_url'] ??
                map['imageurl'] ??
                map['image'] ??
                map['logo_url'] ??
                map['logourl'] ??
                map['logo'] ??
                map['logoUrl'] ??
                map['imageUrl'],
          );

          // Temporarily fill with participant value or a placeholder; we may overwrite after profile fetch.
          final p = GiveawayParticipant(
            userId: userId,
            companyName: rowCompany ?? 'User #$userId',
            avatarUrl: rowAvatar,
            email: rowEmail,
            phone: rowPhone,
            enteredAt: enteredAt,
          );
          (participantsByGiveawayId[giveawayId] ??= <GiveawayParticipant>[]).add(p);
        }

        // Batch fetch related businesses (best-effort).
        // We try:
        // 1) id IN (business ids from participant rows)
        // 2) user_id/owner_id IN (participant user ids)
        if (participantUserIds.isNotEmpty || participantBusinessIdsInt.isNotEmpty) {
          Future<List<Map<String, dynamic>>> _tryFetchBusinesses(String table) async {
            try {
              if (participantBusinessIdsInt.isNotEmpty) {
                final br = await SupabaseConfig.client.from(table).select('*').inFilter('id', participantBusinessIdsInt.toList(growable: false));
                return (br as List).whereType<Map>().map((e) => e.map((k, v) => MapEntry(k.toString(), v))).toList(growable: false);
              }
              // Fallback: infer via user reference.
              // We try common FK column names one by one, because PostgREST `or()`
              // becomes tricky with UUID quoting.
              final userIds = participantUserIds.toList(growable: false);

              Future<List<Map<String, dynamic>>> _tryByColumn(String col) async {
                try {
                  final br = await SupabaseConfig.client.from(table).select('*').inFilter(col, userIds);
                  return (br as List).whereType<Map>().map((e) => e.map((k, v) => MapEntry(k.toString(), v))).toList(growable: false);
                } catch (e) {
                  debugPrint('GiveawayService.refresh: businesses lookup failed ($table.$col): $e');
                  return const [];
                }
              }

              final candidates = <String>[
                'user_id',
                'owner_id',
                'userId',
                'ownerId',
                'user',
                'owner',
                'user_uuid',
                'owner_uuid',
              ];
              for (final col in candidates) {
                final r = await _tryByColumn(col);
                if (r.isNotEmpty) return r;
              }

              return const [];
            } catch (e) {
              debugPrint('GiveawayService.refresh: failed to fetch businesses from $table: $e');
              return const [];
            }
          }

          // Try multiple table names/casing variants until we get results.
          List<Map<String, dynamic>> businessRows = const [];
          String? businessesTableUsed;
          for (final table in _businessesTableCandidates) {
            final r = await _tryFetchBusinesses(table);
            if (r.isNotEmpty) {
              businessRows = r;
              businessesTableUsed = table;
              break;
            }
          }

          if (businessRows.isEmpty) {
            debugPrint(
              'GiveawayService.refresh: no business rows fetched. Possible causes: (1) wrong table name, (2) RLS blocks select, (3) business rows not linked by user_id/owner_id, (4) no matching records.',
            );
          } else {
            debugPrint('GiveawayService.refresh: using businesses table: $businessesTableUsed');
            final sample = _normalizeKeys(businessRows.first);
            debugPrint(
              'GiveawayService.refresh: businesses row keys sample: ${sample.keys.where((k) => k == k.toLowerCase()).take(30).toList()}…',
            );
          }

          for (final row in businessRows) {
            final normalized = _normalizeKeys(row);
            final id = _optString(normalized['id']);
            if (id != null) businessById[id] = normalized;

            final uid = _optString(
              normalized['user_id'] ??
                  normalized['userid'] ??
                  normalized['owner_id'] ??
                  normalized['ownerid'] ??
                  normalized['userId'] ??
                  normalized['ownerId'],
            );
            if (uid != null) businessByUserId[uid] = normalized;
          }

          debugPrint(
            'GiveawayService.refresh: fetched ${businessById.length} businesses (by id), ${businessByUserId.length} businesses (by user)',
          );
        }

        // Batch fetch profiles for all participants.
        if (participantUserIds.isNotEmpty) {
          try {
            final userRows = await SupabaseConfig.client
                .from(_usersTable)
                .select('*')
                .inFilter('id', participantUserIds.toList(growable: false));

            for (final ur in (userRows as List).whereType<Map>()) {
              final m = ur.map((k, v) => MapEntry(k.toString(), v));
              final id = (m['id'] ?? '').toString();
              if (id.isEmpty) continue;
              userProfileById[id] = m;
            }

            debugPrint('GiveawayService.refresh: fetched ${userProfileById.length} user profiles');
          } catch (e) {
            // Not fatal. If `users` is locked down by RLS or missing, we still show ids.
            debugPrint('GiveawayService.refresh: failed to fetch user profiles: $e');
          }
        }
      }

      // Enrich participants with business + user profile fields (best-effort).
      // Priority for Company name:
      // 1) participant row (already in p.companyName unless placeholder)
      // 2) businesses table (by user id or business id)
      // 3) users table
      for (final entry in participantsByGiveawayId.entries) {
        final updated = <GiveawayParticipant>[];
        for (final p in entry.value) {
          final isPlaceholder = p.companyName.startsWith('User #');

          String? businessName;
          Map<String, dynamic>? b;
          if (businessByUserId.isNotEmpty) b = businessByUserId[p.userId];
          // In many schemas (including the generated types in this repo), giveawayparticipants.userId
          // references Businesses.id (numeric). So try direct id match as well.
          b ??= businessById[p.userId];
          b ??= businessById[participantBusinessIdByUserId[p.userId]];
          if (b != null) businessName = _extractBusinessName(b);

          // Businesses often store contact fields (email/phone) even when `public.users` does not.
          // We try several common column names (case-insensitive due to _normalizeKeys).
          final businessEmail = b == null
              ? null
              : _optString(
                  b['email'] ??
                      b['contact_email'] ??
                      b['contactemail'] ??
                      b['owner_email'] ??
                      b['owneremail'],
                );
          final businessPhone = b == null
              ? null
              : _optString(
                  b['phone'] ??
                      b['phone_number'] ??
                      b['phonenumber'] ??
                      b['mobile'] ??
                      b['mobile_number'] ??
                      b['mobilenumber'],
                );

          final businessAvatar = b == null
              ? null
              : _extractImageUrl(b);

          final profile = userProfileById[p.userId];
          final name = profile == null ? null : _optString(profile['name']);
          final profileAvatar = profile == null
              ? null
              : _extractImageUrl(_normalizeKeys(profile));
          final email = _optString(
            p.email ?? (profile == null ? null : profile['email']) ?? businessEmail,
          );
          final phone = _optString(
            p.phone ??
                (profile == null
                    ? null
                    : (profile['phone'] ?? profile['phone_number'] ?? profile['mobile'])) ??
                businessPhone,
          );
          final avatarUrl = _optString(p.avatarUrl ?? profileAvatar ?? businessAvatar);

          if (avatarUrl == null && b != null) {
            // Helps us quickly see which column contains the logo in your schema.
            _debugImageFieldsIfMissing(participantId: p.userId, business: b);
          }

          final userCompany = profile == null
              ? null
              : _optString(
                  profile['company_name'] ??
                      profile['companyName'] ??
                      profile['business_name'] ??
                      profile['businessName'] ??
                      profile['company'],
                );

          final companyName = (!isPlaceholder ? p.companyName : (businessName ?? userCompany ?? p.companyName));

          updated.add(
            GiveawayParticipant(
              userId: p.userId,
              companyName: companyName,
              avatarUrl: avatarUrl,
              name: name,
              email: email,
              phone: phone,
              enteredAt: p.enteredAt,
            ),
          );
        }
        participantsByGiveawayId[entry.key] = updated;
      }

      final t = DateTime.now();
      final parsed = <Giveaway>[];
      for (final r in rows) {
        try {
          final giveawayId = (r['id'] ?? '').toString();

          // If declarewinners has an entry, prefer it and force declared semantics.
          final declaredBusinessId = declaredWinnerBusinessIdByGiveawayId[giveawayId];
          final row = declaredBusinessId == null ? r : <String, dynamic>{...r, 'winnerUserId': declaredBusinessId, 'isDeclared': 1};
          parsed.add(
            Giveaway.fromSupabaseRow(
              row: row,
              participants: participantsByGiveawayId[giveawayId] ?? const [],
              now: t,
            ),
          );
        } catch (e) {
          // Skip malformed rows so one bad record doesn't blank the whole list.
          debugPrint('GiveawayService.refresh: failed to parse row id=${r['id']}: $e');
        }
      }
      giveaways.value = parsed;
    } catch (e) {
      // Do not rethrow: refresh is often called from initState without await.
      // Expose the error to the UI and logs instead.
      debugPrint('GiveawayService.refresh failed: $e');
      lastError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new giveaway.
  static Future<Giveaway> createGiveaway({
    required String title,
    required String description,
    required String image,
    required String termsAndConditions,
    required int sponsorId,
    String? howToParticipate,
    required DateTime winnerAnnouncementDate,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final insert = {
      'title': title.trim().isEmpty ? 'Untitled Giveaway' : title.trim(),
      'description': description,
      'image': image,
      'termsAndConditions': termsAndConditions,
      'sponsorId': sponsorId,
      'howToParticipate': howToParticipate,
      'winnerAnnouncementDate': winnerAnnouncementDate.toUtc().toIso8601String(),
      'isDeclared': 0,
      'createdAt': now,
      'updatedAt': now,
    };

    final inserted = await SupabaseService.insert(_giveawaysTable, insert);
    final row = inserted.first;
    final g = Giveaway.fromSupabaseRow(row: row, participants: const [], now: DateTime.now());
    await refresh();
    return g;
  }

  /// Kept for UI compatibility. With the current Supabase schema, we infer
  /// archived status from `isDeclared` and `winnerAnnouncementDate`, so there is
  /// no separate archive job.
  static void archiveDueGiveaways({DateTime? now}) {}

  static Future<void> updateSchedule({required String giveawayId, required DateTime scheduledArchiveAt}) async {
    try {
      await SupabaseService.update(
        _giveawaysTable,
        {
          'winnerAnnouncementDate': scheduledArchiveAt.toUtc().toIso8601String(),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
        filters: {'id': int.parse(giveawayId)},
      );
      await refresh();
    } catch (e) {
      debugPrint('GiveawayService.updateSchedule failed: $e');
      rethrow;
    }
  }

  static Future<void> updateGiveawayDetails({
    required String giveawayId,
    required String title,
    required String description,
    required String image,
    required String termsAndConditions,
    required int sponsorId,
    String? howToParticipate,
    DateTime? winnerAnnouncementDate,
  }) async {
    try {
      final update = <String, dynamic>{
        'title': title.trim().isEmpty ? 'Untitled Giveaway' : title.trim(),
        'description': description,
        'image': image,
        'termsAndConditions': termsAndConditions,
        'sponsorId': sponsorId,
        'howToParticipate': (howToParticipate ?? '').trim().isEmpty ? null : howToParticipate!.trim(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      if (winnerAnnouncementDate != null) {
        update['winnerAnnouncementDate'] = winnerAnnouncementDate.toUtc().toIso8601String();
      }
      await SupabaseService.update(
        _giveawaysTable,
        update,
        filters: {'id': int.parse(giveawayId)},
      );
      await refresh();
    } catch (e) {
      debugPrint('GiveawayService.updateGiveawayDetails failed: $e');
      rethrow;
    }
  }

  /// Declare a winner and immediately archive (action-based archiving).
  static Future<void> declareWinner({required String giveawayId, required String winnerUserId}) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      // Also write into `declarewinners` (if present) so the Archive tab can read
      // the winner from the canonical table.
      // In this project schema, declarewinners.businessId is an int.
      try {
        final gId = int.parse(giveawayId);
        final bId = int.parse(winnerUserId);

        // If there's already a row for this giveaway, update the latest one.
        final existing = await SupabaseConfig.client
            .from(_declareWinnersTable)
            .select('*')
            .eq('giveawayId', gId)
            .order('updatedAt', ascending: false)
            .limit(1);

        if ((existing as List).isNotEmpty) {
          final first = (existing.first as Map);
          final id = int.tryParse(first['id']?.toString() ?? '');
          if (id != null) {
            await SupabaseConfig.client.from(_declareWinnersTable).update({'businessId': bId, 'status': 1, 'updatedAt': now}).eq('id', id);
          } else {
            await SupabaseConfig.client.from(_declareWinnersTable).insert({'giveawayId': gId, 'businessId': bId, 'status': 1, 'createdAt': now, 'updatedAt': now});
          }
        } else {
          await SupabaseConfig.client.from(_declareWinnersTable).insert({'giveawayId': gId, 'businessId': bId, 'status': 1, 'createdAt': now, 'updatedAt': now});
        }
      } catch (e) {
        // Non-fatal: we still update Giveaways below.
        debugPrint('GiveawayService.declareWinner: failed to upsert declarewinners: $e');
      }

      // Different projects name this column differently. We prefer camelCase
      // (consistent with the rest of this repo), but fall back to snake_case.
      try {
        await SupabaseService.update(
          _giveawaysTable,
          {
            'isDeclared': 1,
            'winnerUserId': winnerUserId,
            'updatedAt': now,
          },
          filters: {'id': int.parse(giveawayId)},
        );
      } catch (e) {
        debugPrint('GiveawayService.declareWinner: camelCase update failed, retrying snake_case: $e');
        await SupabaseService.update(
          _giveawaysTable,
          {
            'isDeclared': 1,
            'winner_user_id': winnerUserId,
            'updatedAt': now,
          },
          filters: {'id': int.parse(giveawayId)},
        );
      }
      await refresh();
    } catch (e) {
      debugPrint('GiveawayService.declareWinner failed: $e');
      rethrow;
    }
  }

  static List<Giveaway> getDraftGiveaways() {
    // Current Supabase schema doesn't have a draft flag.
    // We treat future announcements as "draft" for the admin UI.
    final now = DateTime.now();
    final list = giveaways.value.where((g) => now.isBefore(g.scheduledArchiveAt)).toList(growable: false);
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  static List<Giveaway> getActiveGiveaways({DateTime? now}) {
    final t = now ?? DateTime.now();
    final list = giveaways.value.where((g) => !g.isDueForArchive(t)).toList(growable: false);
    list.sort((a, b) => a.scheduledArchiveAt.compareTo(b.scheduledArchiveAt));
    return list;
  }

  static List<Giveaway> getPastGiveaways({DateTime? now}) {
    final t = now ?? DateTime.now();
    final list = giveaways.value.where((g) => g.isDueForArchive(t)).toList(growable: false);
    list.sort((a, b) => (b.archivedAt ?? b.scheduledArchiveAt).compareTo(a.archivedAt ?? a.scheduledArchiveAt));
    return list;
  }

  static String buildEntrantsCsv(Giveaway giveaway) {
    final rows = <List<String>>[
      ['Unique ID', 'Company Name', 'Entered At (UTC)'],
      ...giveaway.participants.map((p) => [p.userId, p.companyName, (p.enteredAt?.toUtc().toIso8601String() ?? '')]),
    ];

    String esc(String v) {
      final needsQuotes = v.contains(',') || v.contains('"') || v.contains('\n');
      final safe = v.replaceAll('"', '""');
      return needsQuotes ? '"$safe"' : safe;
    }

    return rows.map((r) => r.map(esc).join(',')).join('\n');
  }

  static void debugLogState() {
    debugPrint('Giveaways count: ${giveaways.value.length}');
  }
}
