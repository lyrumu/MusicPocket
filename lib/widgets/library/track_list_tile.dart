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
  final VoidCallback? onRemove;

  const TrackListTile({
    super.key,
    required this.track,
    this.isPlaying = false,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onAddToPlaylist,
    this.onPlayNext,
    this.onRemove,
  });

  @override
  State<TrackListTile> createState() => _TrackListTileState();
}

class _TrackListTileState extends State<TrackListTile> {
  static const double _maxDragExtent = 112;
  static const double _triggerExtent = 68;

  bool _added = false;
  bool _isDragging = false;
  double _dragExtent = 0;
  Timer? _closeTimer;
  Timer? _resetTimer;

  @override
  void dispose() {
    _closeTimer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }

  void _handlePlayNext() {
    widget.onPlayNext?.call();
    if (!mounted) return;
    _closeTimer?.cancel();
    _resetTimer?.cancel();
    setState(() {
      _added = true;
      _isDragging = false;
      _dragExtent = _maxDragExtent;
    });
    _closeTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _dragExtent = 0);
    });
    _resetTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _added = false);
    });
  }

  void _updateDrag(DragUpdateDetails details) {
    final next = (_dragExtent - details.delta.dx)
        .clamp(0.0, _maxDragExtent)
        .toDouble();
    if (next == _dragExtent) return;
    setState(() => _dragExtent = next);
  }

  void _finishDrag({bool commit = true}) {
    final shouldAdd =
        commit && widget.onPlayNext != null && _dragExtent >= _triggerExtent;
    if (shouldAdd) {
      _handlePlayNext();
      return;
    }
    setState(() {
      _isDragging = false;
      _dragExtent = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final canDrag = widget.onPlayNext != null && !_added;
        final tile = Material(
          color: widget.isPlaying
              ? Color.alphaBlend(
                  theme.colorScheme.primaryContainer.withAlpha(110),
                  theme.colorScheme.surface,
                )
              : theme.colorScheme.surface,
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
                if (widget.onRemove != null)
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: '从歌单移除',
                    onPressed: widget.onRemove,
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
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: !canDrag
                ? null
                : (_) => setState(() => _isDragging = true),
            onHorizontalDragUpdate: !canDrag ? null : _updateDrag,
            onHorizontalDragEnd: !canDrag ? null : (_) => _finishDrag(),
            onHorizontalDragCancel: !canDrag
                ? null
                : () => _finishDrag(commit: false),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: TweenAnimationBuilder<double>(
                duration: _isDragging || reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: _isDragging ? Curves.linear : Curves.easeOutCubic,
                tween: Tween(end: _dragExtent),
                builder: (context, dragExtent, child) {
                  final progress = (dragExtent / _maxDragExtent).clamp(
                    0.0,
                    1.0,
                  );
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: theme.colorScheme.primaryContainer,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Opacity(
                              opacity: Curves.easeOut.transform(progress),
                              child: Transform.translate(
                                offset: Offset(18 * (1 - progress), 0),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 18),
                                  child: AnimatedSwitcher(
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 180),
                                    child: _added
                                        ? Row(
                                            key: const ValueKey('check'),
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle_rounded,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '已加入',
                                                style: theme
                                                    .textTheme
                                                    .labelLarge
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            key: const ValueKey('play'),
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.playlist_play_rounded,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '加入下一首',
                                                style: theme
                                                    .textTheme
                                                    .labelLarge
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        key: ValueKey('track_swipe_content_${widget.track.id}'),
                        offset: Offset(-dragExtent, 0),
                        child: child,
                      ),
                    ],
                  );
                },
                child: tile,
              ),
            ),
          ),
        );
      },
    );
  }
}
