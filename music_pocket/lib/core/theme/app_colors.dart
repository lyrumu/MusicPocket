import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Light theme
  static const Color lightBgBase = Color(0xFFFAF9F5);
  static const Color lightBgDeep = Color(0xFFF1EFE9);
  static const Color lightFgBase = Color(0xFF1F1E1D);
  static const Color lightFgMute = Color(0xFF6B6962);
  static const Color lightFgSoft = Color(0xFF8A8880);
  static const Color lightLine = Color(0xFFC9C7BF);
  static const Color lightAccent = Color(0xFFD97757);

  // Dark theme
  static const Color darkBgBase = Color(0xFF141413);
  static const Color darkBgDeep = Color(0xFF0F0E0D);
  static const Color darkFgBase = Color(0xFFFAF9F5);
  static const Color darkFgMute = Color(0xFFB0AEA6);
  static const Color darkFgSoft = Color(0xFF807D77);
  static const Color darkLine = Color(0xFF30302E);
  static const Color darkAccent = Color(0xFFE08769);

  // Spectrum gradient (from Notes music player)
  static const List<Color> spectrumColors = [
    Color(0xFFFF3B6B),
    Color(0xFFFF7A3C),
    Color(0xFFFFD23F),
    Color(0xFF5BE584),
    Color(0xFF3AA9FF),
    Color(0xFF8A5BFF),
    Color(0xFFFF3B6B),
  ];

  static LinearGradient get spectrumGradient => const LinearGradient(
    colors: spectrumColors,
    stops: [0.0, 0.16, 0.32, 0.48, 0.64, 0.82, 1.0],
  );

  static LinearGradient get spectrumGradientSoft => LinearGradient(
    colors: spectrumColors.map((c) => c.withAlpha(217)).toList(),
    stops: const [0.0, 0.16, 0.32, 0.48, 0.64, 0.82, 1.0],
  );

  // Placeholder cover colors (for tracks without artwork)
  static const List<Color> placeholderCovers = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
  ];

  static Color getPlaceholderColor(String? text) {
    if (text == null || text.isEmpty) return placeholderCovers[0];
    final hash = text.hashCode.abs();
    return placeholderCovers[hash % placeholderCovers.length];
  }
}
