import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _primary = Color(0xFF006B5F);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: brightness,
      ),
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
