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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Material(
            color: widget.isPlaying
                ? theme.colorScheme.primaryContainer.withAlpha(110)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              minTileHeight: 66,
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              leading: CoverImage(
                coverPath: widget.track.coverPath,
                seed: widget.track.title,
                size: 50,
                radius: 11,
              ),
              title: Text(
                widget.track.displayTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: widget.isPlaying ? theme.colorScheme.primary : null,
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
                  if (widget.isPlaying) ...[
                    Icon(
                      Icons.equalizer_rounded,
                      color: theme.colorScheme.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.track.durationFormatted,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (widget.onPlayNext != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: '作为下一首播放',
                      onPressed: _handlePlayNext,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        ),
                        child: _added
                            ? Icon(
                                Icons.check_circle_rounded,
                                key: const ValueKey('check'),
                                size: 21,
                                color: theme.colorScheme.primary,
                              )
                            : const Icon(
                                Icons.playlist_play_rounded,
                                key: ValueKey('play'),
                                size: 21,
                              ),
                      ),
                    ),
                  if (!compact && widget.onAddToPlaylist != null)
                    IconButton(
                      icon: const Icon(Icons.playlist_add_outlined, size: 20),
                      visualDensity: VisualDensity.compact,
                      tooltip: '加入歌单',
                      onPressed: widget.onAddToPlaylist,
                    ),
                  if (!compact && widget.onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      visualDensity: VisualDensity.compact,
                      tooltip: '编辑歌曲',
                      onPressed: widget.onEdit,
                    ),
                  if (compact && widget.onLongPress != null)
                    IconButton(
                      icon: const Icon(Icons.more_horiz_rounded, size: 21),
                      visualDensity: VisualDensity.compact,
                      tooltip: '更多操作',
                      onPressed: widget.onLongPress,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
