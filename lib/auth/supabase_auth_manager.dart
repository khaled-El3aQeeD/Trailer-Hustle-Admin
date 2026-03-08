import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trailerhustle_admin/auth/auth_manager.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';

class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  @override
  SupabaseClient get client => SupabaseConfig.client;

  @override
  Session? get currentSession => client.auth.currentSession;

  @override
  User? get currentUser => currentSession?.user;

  @override
  Future<User?> signInWithEmail(BuildContext context, String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(email: email, password: password);
      return res.user;
    } on AuthException catch (e) {
      debugPrint('Supabase signInWithEmail AuthException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Supabase signInWithEmail failed: $e');
      rethrow;
    }
  }

  @override
  Future<User?> createAccountWithEmail(BuildContext context, String email, String password) async {
    try {
      final res = await client.auth.signUp(email: email, password: password);
      return res.user;
    } on AuthException catch (e) {
      debugPrint('Supabase createAccountWithEmail AuthException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Supabase createAccountWithEmail failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateEmail({required String email, required BuildContext context}) async {
    try {
      await client.auth.updateUser(UserAttributes(email: email));
    } on AuthException catch (e) {
      debugPrint('Supabase updateEmail AuthException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Supabase updateEmail failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> resetPassword({required String email, required BuildContext context}) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      debugPrint('Supabase resetPassword AuthException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Supabase resetPassword failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(BuildContext context) async {
    throw UnsupportedError(
      'Deleting a Supabase user requires a service-role key. Implement via an Edge Function.',
    );
  }
}
