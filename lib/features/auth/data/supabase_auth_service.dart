import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  bool get isEmailConfirmed {
    final user = currentUser;
    if (user == null) {
      return false;
    }

    return user.emailConfirmedAt != null;
  }

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

  Future<void> sendPasswordResetEmail({required String email}) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(email);
  }
}