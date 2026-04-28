import 'package:flutter/material.dart';

ThemeData buildNotyTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  const primaryIndigo = Color(0xFF7C89FF);
  const secondaryIndigo = Color(0xFFA5B4FC);
  const accentGreen = Color(0xFF34D399);

  final baseScheme = ColorScheme.fromSeed(
    seedColor: primaryIndigo,
    brightness: brightness,
  );

  final colorScheme = isDark
      ? baseScheme.copyWith(
          primary: primaryIndigo,
          onPrimary: Colors.white,
          secondary: secondaryIndigo,
          onSecondary: const Color(0xFF08101F),
          tertiary: accentGreen,
          onTertiary: const Color(0xFF04130D),
          error: const Color(0xFFF87171),
          onError: const Color(0xFF1F0A0A),
          surface: const Color(0xFF0B1120),
          onSurface: const Color(0xFFF5F7FF),
          onSurfaceVariant: const Color(0xFF94A3B8),
          surfaceContainerHighest: const Color(0xFF1B2436),
          outline: const Color(0xFF243041),
          primaryContainer: const Color(0xFF18213A),
          onPrimaryContainer: const Color(0xFFE5E9FF),
          secondaryContainer: const Color(0xFF151D31),
          onSecondaryContainer: const Color(0xFFE5E7EB),
          tertiaryContainer: const Color(0xFF0F1F1A),
          onTertiaryContainer: const Color(0xFFCCFCE7),
        )
      : baseScheme.copyWith(
          primary: const Color(0xFF4F46E5),
          onPrimary: Colors.white,
          secondary: const Color(0xFF6366F1),
          onSecondary: Colors.white,
          tertiary: const Color(0xFF059669),
          onTertiary: Colors.white,
          error: const Color(0xFFDC2626),
          surface: const Color(0xFFF8FAFC),
          onSurface: const Color(0xFF0F172A),
          onSurfaceVariant: const Color(0xFF64748B),
          surfaceContainerHighest: const Color(0xFFE2E8F0),
          outline: const Color(0xFFCBD5E1),
          primaryContainer: const Color(0xFFE0E7FF),
          onPrimaryContainer: const Color(0xFF1E1B4B),
          secondaryContainer: const Color(0xFFEFF6FF),
          onSecondaryContainer: const Color(0xFF1E293B),
          tertiaryContainer: const Color(0xFFD1FAE5),
          onTertiaryContainer: const Color(0xFF064E3B),
        );

  final surfaceColor = colorScheme.surface;
  final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
  final cardBorder = colorScheme.outline.withValues(alpha: isDark ? 0.9 : 0.6);
  final inputFill = isDark ? const Color(0xFF121A2B) : Colors.white;
  final inputBorder = colorScheme.outline;
  final appBarForeground = colorScheme.onSurface;
  final bodyPrimary = colorScheme.onSurface;
  final bodySecondary = colorScheme.onSurfaceVariant;
  final labelColor = colorScheme.onSurfaceVariant;

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
      backgroundColor: isDark ? const Color(0xFF0E1525) : Colors.white,
      indicatorColor: colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.16),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
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
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? const Color(0xFF121826) : const Color(0xFFF1F5F9),
      disabledColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primaryContainer,
      secondarySelectedColor: colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      side: BorderSide(color: cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: TextStyle(
        color: colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant, size: 18),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return isDark ? const Color(0xFF121826) : const Color(0xFFF1F5F9);
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimaryContainer;
          }
          return colorScheme.onSurfaceVariant;
        }),
        side: WidgetStatePropertyAll(BorderSide(color: cardBorder)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: cardBorder),
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
