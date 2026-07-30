import 'package:flutter/material.dart';

import '../../core/extensions/track_extensions.dart';
import '../../data/database/app_database.dart';
import '../common/cover_placeholder.dart';

class TrackListTile extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onAddToPlaylist;

  const TrackListTile({
    super.key,
    required this.track,
    this.isPlaying = false,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onAddToPlaylist,
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
          if (onAddToPlaylist != null)
            IconButton(
              icon: const Icon(Icons.playlist_add_outlined, size: 20),
              visualDensity: VisualDensity.compact,
              onPressed: onAddToPlaylist,
            ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
            ),
          if (isPlaying)
            Icon(Icons.equalizer, color: theme.colorScheme.primary, size: 20),
        ],
      ),
    );
  }
}
