import 'package:flutter/material.dart';

class ThemePalette {
  const ThemePalette({
    required this.key,
    required this.label,
    required this.primary,
    required this.secondary,
  });

  final String key;
  final String label;
  final Color primary;
  final Color secondary;
}

const defaultThemePaletteKey = 'ocean';
const customThemePrefix = 'custom|';

const themePalettes = <ThemePalette>[
  ThemePalette(
    key: 'ocean',
    label: '海蓝绿',
    primary: Color(0xFF182442),
    secondary: Color(0xFF006A6A),
  ),
  ThemePalette(
    key: 'sunset',
    label: '日落橙',
    primary: Color(0xFF4A2313),
    secondary: Color(0xFFE26D00),
  ),
  ThemePalette(
    key: 'forest',
    label: '森林绿',
    primary: Color(0xFF1F3324),
    secondary: Color(0xFF2E7D32),
  ),
  ThemePalette(
    key: 'berry',
    label: '莓红',
    primary: Color(0xFF4A1D33),
    secondary: Color(0xFFB83280),
  ),
];

ThemePalette resolveThemePalette(String? key) {
  final custom = parseCustomThemePalette(key);
  if (custom != null) return custom;
  for (final p in themePalettes) {
    if (p.key == key) return p;
  }
  return themePalettes.first;
}

String encodeCustomThemeMode({
  required Color primary,
  required Color secondary,
}) {
  return '$customThemePrefix${_hex6(primary)}|${_hex6(secondary)}';
}

ThemePalette? parseCustomThemePalette(String? key) {
  if (key == null || !key.startsWith(customThemePrefix)) return null;
  final parts = key.split('|');
  if (parts.length != 3) return null;
  final primary = _parseHexColor(parts[1]);
  final secondary = _parseHexColor(parts[2]);
  if (primary == null || secondary == null) return null;
  return ThemePalette(
    key: key,
    label: '自定义',
    primary: primary,
    secondary: secondary,
  );
}

const selectableThemeColors = <Color>[
  Color(0xFF182442),
  Color(0xFF4A2313),
  Color(0xFF1F3324),
  Color(0xFF4A1D33),
  Color(0xFF0D3B66),
  Color(0xFF6B3A00),
  Color(0xFF2E7D32),
  Color(0xFFB83280),
  Color(0xFF006A6A),
  Color(0xFFE26D00),
  Color(0xFF5E35B1),
  Color(0xFF00838F),
];

String _hex6(Color c) => c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

Color? _parseHexColor(String hex) {
  final h = hex.trim().replaceAll('#', '');
  if (h.length != 6) return null;
  final value = int.tryParse(h, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}
