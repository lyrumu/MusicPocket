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

  bool get hasCover {
    final path = coverPath;
    return path != null && path.isNotEmpty && File(path).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: hasCover
            ? Image.file(
                File(coverPath!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _PocketCoverPainter(
        base: AppColors.getPlaceholderColor(seed),
        record: theme.brightness == Brightness.dark
            ? const Color(0xFF0C0C0B)
            : const Color(0xFF242321),
        label: AppColors.clay(context),
        cutout: theme.scaffoldBackgroundColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class PocketAlbumArtwork extends StatefulWidget {
  final String? coverPath;
  final String seed;
  final double size;
  final bool isPlaying;

  const PocketAlbumArtwork({
    super.key,
    required this.coverPath,
    required this.seed,
    required this.size,
    this.isPlaying = false,
  });

  @override
  State<PocketAlbumArtwork> createState() => _PocketAlbumArtworkState();
}

class _PocketAlbumArtworkState extends State<PocketAlbumArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation;

  @override
  void initState() {
    super.initState();
    _rotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.isPlaying) _rotation.repeat();
  }

  @override
  void didUpdateWidget(covariant PocketAlbumArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying == oldWidget.isPlaying) return;
    if (widget.isPlaying) {
      _rotation.repeat();
    } else {
      _rotation.stop();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coverSize = widget.size * 0.84;
    final recordSize = widget.size * 0.76;
    final theme = Theme.of(context);
    final shadow = Colors.black.withAlpha(
      theme.brightness == Brightness.dark ? 80 : 38,
    );

    return SizedBox.square(
      dimension: widget.size,
      child: ClipRect(
        clipBehavior: Clip.hardEdge,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              width: recordSize,
              height: recordSize,
              right: 0,
              top: (widget.size - recordSize) / 2,
              child: RotationTransition(
                turns: _rotation,
                child: CustomPaint(
                  painter: _VinylPainter(
                    record: theme.brightness == Brightness.dark
                        ? const Color(0xFF0C0C0B)
                        : const Color(0xFF242321),
                    ring: theme.colorScheme.outline.withAlpha(72),
                    label: AppColors.clay(context),
                    center: AppColors.oat(context),
                  ),
                ),
              ),
            ),
            Positioned(
              width: coverSize,
              height: coverSize,
              left: 0,
              top: (widget.size - coverSize) / 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.size * 0.055),
                  boxShadow: [
                    BoxShadow(
                      color: shadow,
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: CoverImage(
                  coverPath: widget.coverPath,
                  seed: widget.seed,
                  size: coverSize,
                  radius: widget.size * 0.055,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PocketCoverPainter extends CustomPainter {
  final Color base;
  final Color record;
  final Color label;
  final Color cutout;

  const _PocketCoverPainter({
    required this.base,
    required this.record,
    required this.label,
    required this.cutout,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    final recordCenter = Offset(size.width * 0.78, size.height * 0.5);
    final recordRadius = shortest * 0.36;
    canvas.drawCircle(recordCenter, recordRadius, Paint()..color = record);

    final ringPaint = Paint()
      ..color = Colors.white.withAlpha(34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.008;
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(
        recordCenter,
        recordRadius * (0.35 + i * 0.1),
        ringPaint,
      );
    }

    canvas.drawCircle(recordCenter, shortest * 0.105, Paint()..color = label);
    canvas.drawCircle(
      recordCenter,
      shortest * 0.024,
      Paint()..color = cutout.withAlpha(220),
    );
    canvas.drawCircle(
      Offset.zero.translate(0, size.height * 0.5),
      shortest * 0.14,
      Paint()..color = cutout,
    );
  }

  @override
  bool shouldRepaint(covariant _PocketCoverPainter oldDelegate) {
    return base != oldDelegate.base ||
        record != oldDelegate.record ||
        label != oldDelegate.label ||
        cutout != oldDelegate.cutout;
  }
}

class _VinylPainter extends CustomPainter {
  final Color record;
  final Color ring;
  final Color label;
  final Color center;

  const _VinylPainter({
    required this.record,
    required this.ring,
    required this.label,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerPoint = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(centerPoint, radius, Paint()..color = record);
    final ringPaint = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 8; i++) {
      canvas.drawCircle(centerPoint, radius * (0.32 + i * 0.075), ringPaint);
    }
    canvas.drawCircle(centerPoint, radius * 0.21, Paint()..color = label);
    canvas.drawCircle(centerPoint, radius * 0.075, Paint()..color = center);
  }

  @override
  bool shouldRepaint(covariant _VinylPainter oldDelegate) {
    return record != oldDelegate.record ||
        ring != oldDelegate.ring ||
        label != oldDelegate.label ||
        center != oldDelegate.center;
  }
}
