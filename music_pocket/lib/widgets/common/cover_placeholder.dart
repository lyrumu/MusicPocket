import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class CoverImage extends StatelessWidget {
  final String? coverPath;
  final String seed;
  final double size;
  final double radius;

  const CoverImage({
    super.key,
    required this.coverPath,
    required this.seed,
    this.size = 48,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (coverPath != null && coverPath!.isNotEmpty) {
      final file = File(coverPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(),
          ),
        );
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final base = AppColors.getPlaceholderColor(seed);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, base.withAlpha(180)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note, color: Colors.white70, size: 24),
      ),
    );
  }
}
