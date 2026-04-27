import 'package:flutter/material.dart';

ThemeData buildNotyTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0B6BFD),
    brightness: brightness,
  );

  final surfaceColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6FB);
  final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
  final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  final inputFill = isDark ? const Color(0xFF1E293B) : Colors.white;
  final inputBorder = isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: surfaceColor,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: surfaceColor,
      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: cardBorder),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      backgroundColor: cardColor,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.3),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
      bodyMedium: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
      titleLarge: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
      titleMedium: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
      labelMedium: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
    ),
  );
}