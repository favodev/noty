import 'package:flutter/material.dart';
import 'package:noty/app/noty_theme.dart';
import 'package:noty/core/supabase/supabase_bootstrap.dart';
import 'package:noty/features/shell/presentation/noty_shell.dart';

class NotyApp extends StatelessWidget {
  const NotyApp({
    super.key,
    this.supabaseState = const SupabaseBootstrapState.notConfigured(),
  });

  final SupabaseBootstrapState supabaseState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTY',
      debugShowCheckedModeBanner: false,
      theme: buildNotyTheme(),
      home: NotyShell(supabaseState: supabaseState),
    );
  }
}