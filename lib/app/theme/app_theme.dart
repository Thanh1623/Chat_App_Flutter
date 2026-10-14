import 'package:chat_app/app/theme/app_accent.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light(AppAccent accent) => _build(accent, Brightness.light);

  static ThemeData dark(AppAccent accent) => _build(accent, Brightness.dark);

  static ThemeData _build(AppAccent accent, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent.seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const UnderlineInputBorder(),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD0D4D9)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent.seed, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
