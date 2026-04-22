import 'package:noty/core/config/app_env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrapState {
  const SupabaseBootstrapState({
    required this.configured,
    required this.initialized,
    required this.message,
  });

  const SupabaseBootstrapState.notConfigured()
      : configured = false,
        initialized = false,
        message = 'Supabase no configurado (faltan variables de entorno).';

  final bool configured;
  final bool initialized;
  final String message;
}

Future<SupabaseBootstrapState> bootstrapSupabase() async {
  if (!AppEnv.hasSupabaseConfig) {
    return const SupabaseBootstrapState.notConfigured();
  }

  try {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );

    return const SupabaseBootstrapState(
      configured: true,
      initialized: true,
      message: 'Supabase inicializado correctamente.',
    );
  } catch (_) {
    return const SupabaseBootstrapState(
      configured: true,
      initialized: false,
      message: 'Hubo un error al inicializar Supabase.',
    );
  }
}