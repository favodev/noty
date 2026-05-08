import 'package:flutter/widgets.dart';
import 'package:noty/app/noty_app.dart';
import 'package:noty/core/supabase/supabase_bootstrap.dart';
import 'package:noty/core/background/background_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await BackgroundSyncManager.initialize();
  await BackgroundSyncManager.registerPeriodicSync();
  
  final supabaseState = await bootstrapSupabase();
  runApp(NotyApp(supabaseState: supabaseState));
}

