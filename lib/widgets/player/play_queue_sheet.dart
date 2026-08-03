import 'package:flutter/material.dart';

import 'play_queue_content.dart';

class PlayQueueSheet extends StatelessWidget {
  const PlayQueueSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const PlayQueueSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.64;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(theme),
          Expanded(child: const PlayQueueContent(showClose: true)),
        ],
      ),
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withAlpha(80),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
