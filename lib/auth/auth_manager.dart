import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication contract used by the app.
///
/// This project uses Supabase Auth, so the user type is `supabase_flutter.User`.
abstract class AuthManager {
  SupabaseClient get client;

  Session? get currentSession;
  User? get currentUser;

  Future<void> signOut();

  Future<void> updateEmail({required String email, required BuildContext context});

  Future<void> resetPassword({required String email, required BuildContext context});

  /// Supabase user deletion requires a service-role key and must happen server-side.
  Future<void> deleteUser(BuildContext context);
}

mixin EmailSignInManager on AuthManager {
  Future<User?> signInWithEmail(BuildContext context, String email, String password);
  Future<User?> createAccountWithEmail(BuildContext context, String email, String password);
}
