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
          // Match your Businesses schema as closely as possible.
          'display_name': userData.name,
          'email': userData.email,
          'mobile_number': userData.phone,
          // Public website URL.
          // User confirmed the column name is exactly `website`.
          'website': userData.website,
          // Images in your schema: `image` + `profile_image`.
          'profile_image': userData.avatar,
          // Admin flags.
          // `status` is an int in your schema: treat 1 as active.
          'status': userData.isActive ? 1 : 0,
          // `subscriptionStatus` is a string in your schema.
          'subscriptionStatus': userData.isSubscribed ? 'active' : 'inactive',
          // `subscriptionType` is smallint; best-effort mapping: 2+ means “Pro”.
          'subscriptionType': userData.hasHustleProPlan ? 2 : 1,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
        filters: {'id': userData.id},
      );
    } catch (e) {
      debugPrint('UserService.updateUser failed: $e');
      rethrow;
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

      return rows
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
          .toList(growable: false);
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
        if (u.customerNumber.trim().isNotEmpty) return u;
        final fromSerial = _generateBusinessNumberFromSerialId(u.id);
        return fromSerial.isNotEmpty ? u.copyWith(customerNumber: fromSerial) : u.copyWith(customerNumber: _generateCustomerNumber(u.id));
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
