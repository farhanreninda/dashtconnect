import 'package:flutter/material.dart';

const brandBlue = Color(0xFF006BFD);

ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: brandBlue,
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFFACC8FF) : const Color(0xFF0052CC),
        onPrimary: dark ? const Color(0xFF00265F) : Colors.white,
        primaryContainer: dark
            ? const Color(0xFF17355F)
            : const Color(0xFFE7EFFF),
        onPrimaryContainer: dark
            ? const Color(0xFFDCE8FF)
            : const Color(0xFF13458C),
        secondaryContainer: dark
            ? const Color(0xFF17355F)
            : const Color(0xFFE7EFFF),
        onSecondaryContainer: dark
            ? const Color(0xFFDCE8FF)
            : const Color(0xFF13458C),
        surface: dark ? const Color(0xFF10141B) : const Color(0xFFF6F7F9),
        surfaceContainerLowest: dark ? const Color(0xFF171E28) : Colors.white,
        surfaceContainerLow: dark
            ? const Color(0xFF1B2634)
            : const Color(0xFFEFF2F6),
        surfaceContainer: dark
            ? const Color(0xFF243247)
            : const Color(0xFFE7EDF5),
        surfaceContainerHigh: dark
            ? const Color(0xFF2B3B51)
            : const Color(0xFFDFE7F2),
        onSurface: dark ? const Color(0xFFEEF1F6) : const Color(0xFF17202F),
        onSurfaceVariant: dark
            ? const Color(0xFFB2C0D6)
            : const Color(0xFF536071),
        outline: dark ? const Color(0xFF8495AF) : const Color(0xFF758198),
        outlineVariant: dark
            ? const Color(0xFF2B3B54)
            : const Color(0xFFDFE6F2),
      );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
  );
  TextStyle heading(double size) => TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.18,
    letterSpacing: -0.6,
    color: scheme.onSurface,
  );
  final text = base.textTheme.copyWith(
    headlineMedium: heading(30),
    headlineSmall: heading(26),
    titleLarge: heading(20),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
    bodySmall: base.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      height: 1.45,
      color: scheme.onSurfaceVariant,
    ),
    labelLarge: base.textTheme.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );
  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorMaxLines: 4,
      labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      contentPadding: EdgeInsets.all(16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: buttonShape,
        side: BorderSide(color: scheme.outline),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      toolbarHeight: 60,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: buttonShape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: scheme.primary,
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
      iconColor: scheme.primary,
      collapsedIconColor: scheme.onSurfaceVariant,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      titleTextStyle: text.titleMedium,
      subtitleTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      iconColor: scheme.primary,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
