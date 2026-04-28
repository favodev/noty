import 'package:flutter/material.dart';

ThemeData buildNotyTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  const seedColor = Color(0xFF8B5CF6);
  const accentColor = Color(0xFFD8B4FE);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );

  final surfaceColor = isDark ? const Color(0xFF090611) : const Color(0xFFF6F1FF);
  final cardColor = isDark ? const Color(0xFF140B27) : const Color(0xFFFFFBFF);
  final cardBorder = isDark ? const Color(0xFF31214A) : const Color(0xFFE7D9FF);
  final inputFill = isDark ? const Color(0xFF1A1031) : const Color(0xFFFCF8FF);
  final inputBorder = isDark ? const Color(0xFF4C3573) : const Color(0xFFD5C2F5);
  final appBarForeground = isDark ? const Color(0xFFF5EDFF) : const Color(0xFF221238);
  final bodyPrimary = isDark ? const Color(0xFFF3E8FF) : const Color(0xFF221238);
  final bodySecondary = isDark ? const Color(0xFFCBB8EA) : const Color(0xFF5B4B79);
  final labelColor = isDark ? const Color(0xFFB9A4DB) : const Color(0xFF6C5A8D);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: surfaceColor,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: surfaceColor,
      foregroundColor: appBarForeground,
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
      indicatorColor: accentColor.withValues(alpha: isDark ? 0.24 : 0.32),
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
      bodyLarge: TextStyle(color: bodyPrimary),
      bodyMedium: TextStyle(color: bodySecondary),
      titleLarge: TextStyle(color: bodyPrimary),
      titleMedium: TextStyle(color: bodyPrimary),
      labelMedium: TextStyle(color: labelColor),
    ),
  );
}
