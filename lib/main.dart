import 'package:flutter/widgets.dart';
import 'package:noty/app/noty_app.dart';
import 'package:noty/core/supabase/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseState = await bootstrapSupabase();
  runApp(NotyApp(supabaseState: supabaseState));
}

