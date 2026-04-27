class AppEnv {
  AppEnv._();

  static String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  static String supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
  static String supabaseAuthRedirect = const String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT',
    defaultValue: 'noty://auth-callback',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static void configure({
    required String url,
    required String anonKey,
    String? authRedirect,
  }) {
    supabaseUrl = url;
    supabaseAnonKey = anonKey;
    if (authRedirect != null) {
      supabaseAuthRedirect = authRedirect;
    }
  }

  static void reset() {
    supabaseUrl = '';
    supabaseAnonKey = '';
    supabaseAuthRedirect = 'noty://auth-callback';
  }
}