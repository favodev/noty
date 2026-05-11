import 'package:flutter/material.dart';
import 'package:noty/app/noty_theme.dart';
import 'package:noty/features/shell/presentation/noty_shell.dart';

class NotyApp extends StatefulWidget {
  const NotyApp({
    super.key,
    this.enableLocalPersistence = true,
  });

  final bool enableLocalPersistence;

  @override
  State<NotyApp> createState() => _NotyAppState();
}

class _NotyAppState extends State<NotyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTY',
      debugShowCheckedModeBanner: false,
      theme: buildNotyTheme(Brightness.light),
      darkTheme: buildNotyTheme(Brightness.dark),
      themeMode: _themeMode,
      home: NotyShell(
        enableLocalPersistence: widget.enableLocalPersistence,
        currentThemeMode: _themeMode,
        onThemeChanged: (mode) {
          if (!mounted) return;
          setState(() {
            _themeMode = mode;
          });
        },
      ),
    );
  }
}
