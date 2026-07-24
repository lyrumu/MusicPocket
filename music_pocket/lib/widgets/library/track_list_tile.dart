import 'package:flutter/material.dart';

import '../../core/extensions/track_extensions.dart';
import '../../data/database/app_database.dart';
import '../common/cover_placeholder.dart';

class TrackListTile extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TrackListTile({
    super.key,
    required this.track,
    this.isPlaying = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: CoverImage(coverPath: track.coverPath, seed: track.title),
      ),
      title: Text(
        track.displayTitle,
        style: TextStyle(
          color: isPlaying ? theme.colorScheme.primary : null,
          fontWeight: isPlaying ? FontWeight.w600 : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.displayArtist,
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(track.durationFormatted, style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
          if (isPlaying)
            Icon(Icons.equalizer, color: theme.colorScheme.primary, size: 20),
        ],
      ),
    );
  }
}
