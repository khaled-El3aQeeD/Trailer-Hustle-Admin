import 'package:flutter/foundation.dart';
import 'package:trailerhustle_admin/models/user_data.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';
import 'package:trailerhustle_admin/services/giveaway_service.dart';

/// Service used by the admin dashboard to read/update Businesses.
///
/// Historical note: the app started with a `users` table. Your Supabase project
/// stores this data in a Businesses table instead, so this service now targets
/// `Businesses`/`businesses` with best-effort column mapping.
class UserService {
  /// Exact table name (case-sensitive) confirmed by user.
  static const String businessesTable = 'Businesses';

  /// Kept as a list for minimal code changes, but we now only target the exact
  /// table name.
  static const List<String> _businessesTableCandidates = [businessesTable];

  static String _firstNonEmpty(Iterable<Object?> values, {required String fallback}) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  /// Get current signed-in user (Auth) metadata.
  ///
  /// This is not a Businesses row; it only uses Supabase Auth session.
  static UserData getCurrentUser() {
    final auth = SupabaseConfig.client.auth;
    final user = auth.currentSession?.user ?? auth.currentUser;
    final meta = user?.userMetadata ?? const <String, dynamic>{};

    final email = _firstNonEmpty([user?.email, meta['email'], meta['contact_email'], meta['user_email']], fallback: '');
    final phone = _firstNonEmpty(
      [user?.phone, meta['phone'], meta['phone_number'], meta['phoneNumber'], meta['mobile'], meta['mobile_number']],
      fallback: '',
    );

    final id = user?.id ?? 'anonymous';
    final customerNumber = _generateCustomerNumber(id);
    final now = DateTime.now().toUtc();

    return UserData(
      id: id,
      customerNumber: customerNumber,
      name: _firstNonEmpty([meta['name'], meta['full_name'], meta['display_name'], meta['displayName'], email.isEmpty ? null : email.split('@').first], fallback: 'Guest'),
      email: email,
      phone: phone,
      avatar: (meta['avatar_url'] ?? '').toString(),
      regularCityState: '',
      website: '',
      categoryType: '',
      isSubscribed: false,
      isActive: true,
      hasHustleProPlan: false,
      subscriptionTier: 'free',
      createdAt: now,
      updatedAt: now,
    );
  }

  static String _generateCustomerNumber(String uuid) {
    var hash = 0;
    for (final c in uuid.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    final n = hash % 1000000000;
    return 'TH-${n.toString().padLeft(9, '0')}';
  }

  static String _generateBusinessNumberFromSerialId(String id) {
    final n = int.tryParse(id.trim());
    if (n == null) return '';
    return 'TH-${n.toString().padLeft(9, '0')}';
  }

  static bool _isMissingTableError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('could not find the table') ||
        (s.contains('relation') && s.contains('does not exist')) ||
        s.contains('schema cache');
  }

  static Future<Map<int, String>> _fetchCategoryNameMap(Set<int> categoryIds) async {
    if (categoryIds.isEmpty) return const <int, String>{};
    try {
      final rows = await SupabaseService.from('Categories')
          .select('id,name')
          .inFilter('id', categoryIds.toList(growable: false));

      final map = <int, String>{};
      for (final r in (rows as List)) {
        if (r is! Map) continue;
        final idRaw = r['id'];
        final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
        if (id == null) continue;
        final name = (r['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        map[id] = name;
      }
      return map;
    } catch (e) {
      debugPrint('UserService: failed to load Categories for dashboard: $e');
      return const <int, String>{};
    }
  }

  static Never _throwMissingBusinessesTable(Object e) {
    debugPrint('Supabase businesses table missing/unavailable: $e');
    throw StateError(
      "Your Supabase database doesn't expose a Businesses table to this app.\n\n"
      "Expected a table named exactly: ${_businessesTableCandidates.join(', ')}.\n\n"
      "Fix: confirm the table name and ensure Row Level Security (RLS) allows SELECT/UPDATE for your admin user.",
    );
  }

  static Future<String> _pickFirstWorkingTable({String select = 'id', int limit = 1}) async {
    Object? lastErr;
    for (final t in _businessesTableCandidates) {
      try {
        await SupabaseService.select(t, select: select, limit: limit);
        return t;
      } catch (e) {
        lastErr = e;
      }
    }
    if (lastErr != null && _isMissingTableError(lastErr)) {
      _throwMissingBusinessesTable(lastErr);
    }
    throw StateError('Could not query any Businesses table candidate. Last error: $lastErr');
  }

  static Future<List<Map<String, dynamic>>> _selectBusinessesRows({
    required String select,
    String? orderBy,
    bool ascending = true,
  }) async {
    Object? lastErr;
    for (final t in _businessesTableCandidates) {
      try {
        // PostgREST returns at most ~1000 rows per request.
        // Paginate to get all businesses.
        final all = <Map<String, dynamic>>[];
        const pageSize = 1000;
        int offset = 0;
        while (true) {
          dynamic query = SupabaseConfig.client.from(t).select(select);
          if (orderBy != null) {
            query = query.order(orderBy, ascending: ascending);
          }
          final batch = await query.range(offset, offset + pageSize - 1);
          final batchList = (batch as List)
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .toList(growable: false);
          all.addAll(batchList);
          if (batchList.length < pageSize) break;
          offset += pageSize;
        }
        return all;
      } catch (e) {
        lastErr = e;
      }
    }
    if (lastErr != null && _isMissingTableError(lastErr)) {
      _throwMissingBusinessesTable(lastErr);
    }
    throw StateError('Failed to query Businesses. Last error: $lastErr');
  }

  /// Update a business record.
  ///
  /// We update the first Businesses table that is queryable.
  static Future<void> updateUser(UserData userData) async {
    final table = await _pickFirstWorkingTable(select: 'id');
    try {
      await SupabaseService.update(
        table,
        {
          'display_name': userData.name,
          'email': userData.email,
          'mobile_number': userData.phone,
          'website': userData.website,
          'profile_image': userData.avatar,
          'status': userData.isActive ? 1 : 0,
          'subscriptionStatus': userData.subscriptionTier == 'free' ? 'inactive' : 'active',
          'subscriptionType': userData.subscriptionTier == 'pro' ? 2 : (userData.subscriptionTier == 'lite' ? 1 : 0),
          // Extended profile fields
          'contact_email': userData.contactEmail,
          'description': userData.description,
          'location': userData.location,
          'latitude': userData.latitude,
          'longitude': userData.longitude,
          'instagram': userData.instagram,
          'facebook': userData.facebook,
          'youtube': userData.youtube,
          'twitter': userData.twitter,
          'tiktok': userData.tiktok,
          'image': userData.coverImage,
          'is_featured': userData.isFeatured ? 1 : 0,
          'is_verify': userData.isVerify ? 1 : 0,
          'color': userData.color,
          'business_contact_number': userData.businessContactNumber,
          'business_country_code': userData.businessCountryCode,
          'country_code': userData.countryCode,
          'zip_code': userData.zipCode,
          'regularCityState': userData.regularCityState,
          'complete_profile': userData.completeProfile,
          if (userData.categoryId != null) 'category_id': userData.categoryId,
          if (userData.subscriptionEndDate != null)
            'subscriptionEndDate': userData.subscriptionEndDate!.toUtc().toIso8601String(),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
        filters: {'id': userData.id},
      );
    } catch (e) {
      debugPrint('UserService.updateUser failed: $e');
      rethrow;
    }
  }

  /// Fetch gallery images for a business from the businesssimages table.
  static Future<List<Map<String, dynamic>>> fetchBusinessImages(String businessId) async {
    try {
      final rows = await SupabaseConfig.client
          .from('businesssimages')
          .select('*')
          .eq('businessId', businessId)
          .isFilter('deletedAt', null)
          .order('createdAt', ascending: true);
      return (rows as List).whereType<Map>().map((e) => e.map((k, v) => MapEntry(k.toString(), v))).toList();
    } catch (e) {
      debugPrint('UserService.fetchBusinessImages failed: $e');
      return const [];
    }
  }

  /// Soft-delete a business image by setting deletedAt.
  static Future<void> deleteBusinessImage(String imageId) async {
    try {
      await SupabaseConfig.client
          .from('businesssimages')
          .update({'deletedAt': DateTime.now().toUtc().toIso8601String()})
          .eq('id', imageId);
    } catch (e) {
      debugPrint('UserService.deleteBusinessImage failed: $e');
      rethrow;
    }
  }

  /// Add a gallery image entry for a business.
  static Future<void> addBusinessImage({required String businessId, required String imageUrl}) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final nextId = await _getNextBusinessImageId();
      await SupabaseConfig.client.from('businesssimages').insert({
        'id': nextId,
        'businessId': businessId,
        'image': imageUrl,
        'createdAt': now,
        'updatedAt': now,
      });
    } catch (e) {
      debugPrint('UserService.addBusinessImage failed: $e');
      rethrow;
    }
  }

  /// Get the next available ID for businesssimages (no auto-increment in Supabase).
  static Future<int> _getNextBusinessImageId() async {
    try {
      final result = await SupabaseConfig.client
          .from('businesssimages')
          .select('id')
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();
      if (result != null && result['id'] != null) {
        return (result['id'] as int) + 1;
      }
      return 1;
    } catch (e) {
      debugPrint('⚠️ Error getting next image ID, using timestamp: $e');
      return DateTime.now().millisecondsSinceEpoch % 2147483647;
    }
  }

  /// Fetch all categories for dropdown selection.
  static Future<List<Map<String, dynamic>>> fetchAllCategories() async {
    try {
      final rows = await SupabaseConfig.client
          .from('Categories')
          .select('id,name')
          .order('name', ascending: true);
      return (rows as List).whereType<Map>().map((e) => e.map((k, v) => MapEntry(k.toString(), v))).toList();
    } catch (e) {
      debugPrint('UserService.fetchAllCategories failed: $e');
      return const [];
    }
  }

  /// Fetch auth identity providers for a single user from `auth.identities`
  /// via the `get_auth_providers` RPC function.
  ///
  /// Returns provider strings like `['email', 'phone', 'google']`.
  static Future<List<String>> fetchAuthProviders(String socialId) async {
    if (socialId.trim().isEmpty) return const [];
    try {
      final result = await SupabaseConfig.client.rpc(
        'get_auth_providers',
        params: {'user_auth_id': socialId},
      );
      if (result is List) {
        return result.map((e) => e.toString()).toList();
      }
      return const [];
    } catch (e) {
      debugPrint('UserService.fetchAuthProviders failed for $socialId: $e');
      return const [];
    }
  }

  /// Batch-fetch auth identity providers for multiple users.
  ///
  /// Returns a map of `{socialId: [provider1, provider2, ...]}`.
  static Future<Map<String, List<String>>> fetchBatchAuthProviders(List<String> socialIds) async {
    final ids = socialIds.where((s) => s.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const {};
    try {
      final result = await SupabaseConfig.client.rpc(
        'get_batch_auth_providers',
        params: {'user_auth_ids': ids},
      );
      final map = <String, List<String>>{};
      if (result is List) {
        for (final row in result) {
          if (row is! Map) continue;
          final authId = (row['auth_id'] ?? '').toString();
          final providers = row['providers'];
          if (authId.isEmpty) continue;
          if (providers is List) {
            map[authId] = providers.map((e) => e.toString()).toList();
          }
        }
      }
      return map;
    } catch (e) {
      debugPrint('UserService.fetchBatchAuthProviders failed: $e');
      return const {};
    }
  }

  /// Fetch all businesses for the admin dashboard.
  static Future<List<UserData>> fetchCustomers() async {
    try {
      // Use '*' to tolerate unknown schemas.
      // Your schema uses `createdAt` (not `created_at`).
      // If ordering by createdAt fails (nulls/column mismatch), we fall back to id.
      List<Map<String, dynamic>> rows;
      try {
        rows = await _selectBusinessesRows(select: '*', orderBy: 'createdAt', ascending: false);
      } catch (e) {
        debugPrint('Businesses orderBy createdAt failed, falling back to id: $e');
        rows = await _selectBusinessesRows(select: '*', orderBy: 'id', ascending: false);
      }

      // Best-effort: map `Businesses.category_id` -> `Categories.name`.
      final categoryIds = <int>{};
      for (final r in rows) {
        final v = r['category_id'] ?? r['categoryId'];
        if (v is int) {
          categoryIds.add(v);
        } else if (v is num) {
          categoryIds.add(v.toInt());
        } else {
          final parsed = int.tryParse(v?.toString() ?? '');
          if (parsed != null) categoryIds.add(parsed);
        }
      }
      final categoryNameById = await _fetchCategoryNameMap(categoryIds);

      final users = rows
          .map((r) {
            final u = UserData.fromJson(r);
            final id = u.id.trim();

            // Resolve bare‐filename avatars to full Storage URLs.
            final resolvedAvatar = GiveawayService.resolveStorageUrl(u.avatar) ?? u.avatar;
            var working = resolvedAvatar != u.avatar ? u.copyWith(avatar: resolvedAvatar) : u;

            // Attach the category label (if missing in the raw row).
            String? categoryType;
            if (working.categoryType.trim().isEmpty) {
              final categoryIdRaw = r['category_id'] ?? r['categoryId'];
              final categoryId = categoryIdRaw is int
                  ? categoryIdRaw
                  : int.tryParse(categoryIdRaw?.toString() ?? '');
              final name = categoryId == null ? null : categoryNameById[categoryId];
              if ((name ?? '').trim().isNotEmpty) categoryType = name;
            }

            // If the Businesses table doesn't have a business_number column,
            // we still show a stable generated one in the UI.
            if (working.customerNumber.trim().isEmpty && id.isNotEmpty) {
              final fromSerial = _generateBusinessNumberFromSerialId(id);
              final base = fromSerial.isNotEmpty ? working.copyWith(customerNumber: fromSerial) : working.copyWith(customerNumber: _generateCustomerNumber(id));
              return categoryType == null ? base : base.copyWith(categoryType: categoryType);
            }
            // If id is empty (odd schema), keep as-is.
            return categoryType == null ? working : working.copyWith(categoryType: categoryType);
          })
          .toList();

      // Batch-fetch auth identity providers from auth.identities via RPC.
      final socialIds = users
          .map((u) => u.socialId)
          .where((s) => s.trim().isNotEmpty)
          .toList();
      final authProvidersMap = await fetchBatchAuthProviders(socialIds);

      // Attach auth providers to each user.
      if (authProvidersMap.isNotEmpty) {
        for (var i = 0; i < users.length; i++) {
          final providers = authProvidersMap[users[i].socialId];
          if (providers != null && providers.isNotEmpty) {
            users[i] = users[i].copyWith(authProviders: providers);
          }
        }
      }

      return users;
    } catch (e) {
      debugPrint('UserService.fetchCustomers failed: $e');
      if (_isMissingTableError(e)) _throwMissingBusinessesTable(e);
      rethrow;
    }
  }

  static Future<UserData> fetchCustomerById(String businessId) async {
    Object? lastErr;
    for (final t in _businessesTableCandidates) {
      try {
        final row = await SupabaseService.selectSingle(t, filters: {'id': businessId});
        if (row == null) continue;
        var u = UserData.fromJson(row);
        // Resolve bare-filename avatar to full Storage URL.
        final resolved = GiveawayService.resolveStorageUrl(u.avatar) ?? u.avatar;
        if (resolved != u.avatar) u = u.copyWith(avatar: resolved);
        if (u.customerNumber.trim().isEmpty) {
          final fromSerial = _generateBusinessNumberFromSerialId(u.id);
          u = fromSerial.isNotEmpty
              ? u.copyWith(customerNumber: fromSerial)
              : u.copyWith(customerNumber: _generateCustomerNumber(u.id));
        }
        // Fetch auth identity providers from auth.identities via RPC.
        if (u.socialId.trim().isNotEmpty) {
          final providers = await fetchAuthProviders(u.socialId);
          if (providers.isNotEmpty) {
            u = u.copyWith(authProviders: providers);
          }
        }
        return u;
      } catch (e) {
        lastErr = e;
      }
    }
    if (lastErr != null && _isMissingTableError(lastErr)) {
      _throwMissingBusinessesTable(lastErr);
    }
    throw StateError('Business not found: $businessId');
  }

  /// Fetch a `{businessId -> display_name}` map for the provided business ids.
  ///
  /// This is used by pages that reference `Trailers.bussinessid` and want to
  /// display a human-friendly Business Name instead of a numeric id.
  static Future<Map<int, String>> fetchBusinessNamesByIds({required List<int> businessIds}) async {
    final ids = businessIds.where((e) => e > 0).toSet().toList(growable: false);
    if (ids.isEmpty) return const <int, String>{};

    try {
      final rows = await SupabaseService.from(businessesTable)
          .select('id,display_name')
          .inFilter('id', ids);

      final out = <int, String>{};
      for (final r in (rows as List)) {
        if (r is! Map) continue;
        final idRaw = r['id'];
        final id = idRaw is int ? idRaw : idRaw is num ? idRaw.toInt() : int.tryParse(idRaw?.toString() ?? '');
        if (id == null) continue;
        final name = (r['display_name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        out[id] = name;
      }
      return out;
    } catch (e) {
      debugPrint('UserService.fetchBusinessNamesByIds failed: $e');
      rethrow;
    }
  }
}
