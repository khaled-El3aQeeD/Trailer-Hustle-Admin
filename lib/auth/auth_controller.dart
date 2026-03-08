import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';

/// Single source of truth for Supabase auth state.
///
/// Listens to `onAuthStateChange` and exposes a simple `isSignedIn` flag.
class AuthController extends ChangeNotifier {
  AuthController() {
    _session = SupabaseConfig.client.auth.currentSession;
    _sub = SupabaseConfig.client.auth.onAuthStateChange.listen((data) async {
      _session = data.session;
      // Real auth state changes should always disable test bypass.
      if (_session != null) _bypassLoginForTesting = false;
      notifyListeners();
      await _ensureUserRow();
    });

    // Best-effort user row creation on cold start too.
    scheduleMicrotask(_ensureUserRow);
  }

  StreamSubscription<AuthState>? _sub;
  Session? _session;
  bool _bypassLoginForTesting = false;

  Session? get session => _session;
  User? get user => _session?.user;
  bool get isSignedIn => _session != null || _bypassLoginForTesting;
  bool get isBypassLoginForTestingEnabled => _bypassLoginForTesting;

  /// Enables a local-only auth bypass so you can test UI without logging in.
  ///
  /// This does NOT create a Supabase session and should only be used for
  /// development/testing.
  void enableBypassLoginForTesting() {
    _bypassLoginForTesting = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    // Always clear bypass first so AuthGate can switch immediately.
    if (_bypassLoginForTesting) {
      _bypassLoginForTesting = false;
      notifyListeners();
    }

    try {
      // If we don't have a real session, there's nothing to sign out of.
      if (_session != null) await SupabaseConfig.client.auth.signOut();
    } catch (e) {
      debugPrint('Sign out failed: $e');
      rethrow;
    }
  }

  /// Best-effort: ensures the signed-in user's related Business record has a
  /// stable human-friendly identifier (Business ID).
  ///
  /// Your project stores admin-facing data in a Businesses table (not `public.users`).
  /// Because schemas differ, this method is intentionally resilient:
  /// - It targets the exact table name (`Businesses`)
  /// - It tries to locate the business row by common FK columns (`user_id`, `owner_id`, ...)
  /// - It only updates an existing row (does not create a new business)
  Future<void> _ensureUserRow() async {
    final u = user;
    if (u == null) return;

    try {
      const tables = ['Businesses'];
      const fkCols = ['user_id', 'owner_id', 'auth_user_id', 'user_uuid', 'owner_uuid', 'userId', 'ownerId'];
      const idCols = ['id', 'business_id', 'businessId'];

      Map<String, dynamic>? businessRow;
      String? tableUsed;
      String? idColUsed;
      dynamic idValue;

      Future<Map<String, dynamic>?> tryFindRow(String table) async {
        // 1) Try FK columns to auth user id
        for (final col in fkCols) {
          try {
            final r = await SupabaseConfig.client.from(table).select('*').eq(col, u.id).maybeSingle();
            if (r != null) {
              idColUsed = 'id';
              idValue = r['id'] ?? r['business_id'] ?? r['businessId'];
              return r;
            }
          } catch (_) {}
        }
        // 2) Try the record id equals auth user id (some schemas use auth uid as PK)
        for (final col in idCols) {
          try {
            final r = await SupabaseConfig.client.from(table).select('*').eq(col, u.id).maybeSingle();
            if (r != null) {
              idColUsed = col;
              idValue = u.id;
              return r;
            }
          } catch (_) {}
        }
        return null;
      }

      for (final t in tables) {
        try {
          businessRow = await tryFindRow(t);
          if (businessRow != null) {
            tableUsed = t;
            break;
          }
        } catch (e) {
          debugPrint('AuthController: business lookup failed for table=$t: $e');
        }
      }

      if (businessRow == null || tableUsed == null) return;

      final existing = (businessRow['business_number'] ?? businessRow['customer_number'] ?? '').toString().trim();
      if (existing.isNotEmpty) return;

      final generated = _generateCustomerNumber(u.id);
      final now = DateTime.now().toUtc().toIso8601String();

      // Only update columns that might exist; PostgREST will reject unknown columns,
      // so we keep this tight.
      final patch = <String, dynamic>{
        'business_number': generated,
        'customer_number': generated,
        'updated_at': now,
      };

      // If we failed to infer the id value, don't update.
      if (idValue == null) return;

      try {
        await SupabaseConfig.client.from(tableUsed).update(patch).eq(idColUsed ?? 'id', idValue);
      } catch (e) {
        debugPrint('AuthController: failed to persist business identifier (continuing): $e');
      }
    } catch (e) {
      // Don't break navigation if the DB isn't ready yet.
      debugPrint('Failed to ensure business identifier: $e');
    }
  }

  String _generateCustomerNumber(String uuid) {
    // Deterministic, human-friendly ID derived from the auth UUID.
    // Format: TH-######### (9 digits)
    // This avoids race conditions / sequences while staying stable.
    var hash = 0;
    for (final c in uuid.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    final n = hash % 1000000000;
    return 'TH-${n.toString().padLeft(9, '0')}';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
