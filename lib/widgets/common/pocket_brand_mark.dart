import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PocketBrandMark extends StatelessWidget {
  final double size;

  const PocketBrandMark({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * 0.22),
          topRight: Radius.circular(size * 0.22),
          bottomLeft: Radius.circular(size * 0.34),
          bottomRight: Radius.circular(size * 0.34),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: Theme.of(context).colorScheme.primary),
            ),
            Positioned(
              left: size * 0.18,
              right: size * 0.18,
              bottom: 0,
              height: size * 0.16,
              child: ColoredBox(color: AppColors.clay(context).withAlpha(120)),
            ),
            Positioned(
              left: size * 0.2,
              top: -size * 0.32,
              child: Container(
                width: size * 0.6,
                height: size * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
