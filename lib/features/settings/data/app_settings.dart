import 'package:flutter/material.dart';

import '../../compression/data/compression_models.dart';

class AppSettings {
  const AppSettings({
    this.language = 'system',
    this.theme = ThemeMode.system,
    this.compression = CompressionChoice.medium,
    this.onboarded = false,
  });
  final String language;
  final ThemeMode theme;
  final CompressionChoice compression;
  final bool onboarded;
  Locale? get locale => language == 'system' ? null : Locale(language);
  AppSettings copyWith({
    String? language,
    ThemeMode? theme,
    CompressionChoice? compression,
    bool? onboarded,
  }) => AppSettings(
    language: language ?? this.language,
    theme: theme ?? this.theme,
    compression: compression ?? this.compression,
    onboarded: onboarded ?? this.onboarded,
  );
  Map<String, Object> toMap() => {
    'id': 1,
    'language': language,
    'theme': theme.name,
    'compression': compression.name,
    'onboarded': onboarded ? 1 : 0,
  };
  factory AppSettings.fromMap(Map<String, Object?> row) => AppSettings(
    language: ['system', 'en', 'bn'].contains(row['language'])
        ? row['language'] as String
        : 'system',
    theme:
        ThemeMode.values.where((v) => v.name == row['theme']).firstOrNull ??
        ThemeMode.system,
    compression:
        CompressionChoice.values
            .where((v) => v.name == row['compression'])
            .firstOrNull ??
        CompressionChoice.medium,
    onboarded: row['onboarded'] == 1,
  );
}
