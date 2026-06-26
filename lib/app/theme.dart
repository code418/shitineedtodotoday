import 'package:flutter/material.dart';

/// App theming. A single seed colour drives Material 3 light & dark schemes.
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF4C6FFF);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
