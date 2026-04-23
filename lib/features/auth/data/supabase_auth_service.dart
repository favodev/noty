import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  Stream<AuthState> authStateChanges() {
    return Supabase.instance.client.auth.onAuthStateChange;
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}