import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/extensions/track_extensions.dart';
import '../../data/database/app_database.dart';
import '../common/cover_placeholder.dart';

class TrackListTile extends StatefulWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onPlayNext;

  const TrackListTile({
    super.key,
    required this.track,
    this.isPlaying = false,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onAddToPlaylist,
    this.onPlayNext,
  });

  @override
  State<TrackListTile> createState() => _TrackListTileState();
}

class _TrackListTileState extends State<TrackListTile> {
  bool _added = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _handlePlayNext() {
    widget.onPlayNext?.call();
    if (!mounted) return;
    _resetTimer?.cancel();
    setState(() => _added = true);
    _resetTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: CoverImage(coverPath: widget.track.coverPath, seed: widget.track.title),
      ),
      title: Text(
        widget.track.displayTitle,
        style: TextStyle(
          color: widget.isPlaying ? theme.colorScheme.primary : null,
          fontWeight: widget.isPlaying ? FontWeight.w600 : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        widget.track.displayArtist,
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.track.durationFormatted, style: theme.textTheme.bodySmall),
          const SizedBox(width: 4),
          if (widget.onPlayNext != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: '作为下一首播放',
              onPressed: _handlePlayNext,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  );
                },
                child: _added
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('check'),
                        size: 22,
                        color: theme.colorScheme.primary,
                      )
                    : const Icon(
                        Icons.playlist_play,
                        key: ValueKey('play'),
                        size: 22,
                      ),
              ),
            ),
          if (widget.onAddToPlaylist != null)
            IconButton(
              icon: const Icon(Icons.playlist_add_outlined, size: 20),
              visualDensity: VisualDensity.compact,
              tooltip: '加入歌单',
              onPressed: widget.onAddToPlaylist,
            ),
          if (widget.onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              visualDensity: VisualDensity.compact,
              onPressed: widget.onEdit,
            ),
          if (widget.isPlaying)
            Icon(Icons.equalizer, color: theme.colorScheme.primary, size: 20),
        ],
      ),
    );
  }
}