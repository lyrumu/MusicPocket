import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/track_extensions.dart';
import '../../data/database/app_database.dart';
import '../../providers/track_provider.dart';
import '../../services/audio_player_service.dart';
import '../common/cover_placeholder.dart';

class PlayQueueContent extends ConsumerWidget {
  final bool showClose;
  final VoidCallback? onClose;

  const PlayQueueContent({super.key, this.showClose = false, this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audio = AudioPlayerService.instance;
    final snapshot = ref.watch(playQueueProvider).asData?.value ?? audio.queue;
    final mode = ref.watch(playModeProvider).asData?.value ?? audio.playMode;

    return Column(
      children: [
        _buildHeader(context, theme, audio, mode, snapshot),
        const Divider(height: 1),
        if (snapshot.current != null) _CurrentTile(track: snapshot.current!),
        Expanded(
          child: snapshot.upNext.isEmpty && snapshot.current == null
              ? _buildEmpty(theme)
              : snapshot.upNext.isEmpty
                  ? _buildHint(theme)
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: snapshot.upNext.length,
                      proxyDecorator: (child, _, _) => _ProxyDecorator(
                        color: theme.colorScheme.primary.withAlpha(30),
                        child: child,
                      ),
                      onReorderItem: audio.reorderQueue,
                      itemBuilder: (context, index) {
                        final item = snapshot.upNext[index];
                        return _QueueItem(
                          key: ValueKey(
                            'q_${item.track.id}_${index}_${item.manual}',
                          ),
                          item: item,
                          index: index,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AudioPlayerService audio,
    PlayMode mode,
    PlayQueueSnapshot snapshot,
  ) {
    final count = snapshot.upNext.length;
    final total = count + (snapshot.current != null ? 1 : 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
      child: Row(
        children: [
          Text('播放列表', style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          Text(
            '$total 首',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(_playModeIcon(mode)),
            color: mode != PlayMode.list
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            tooltip: _playModeLabel(mode),
            onPressed: audio.cyclePlayMode,
          ),
          if (showClose)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: onClose ?? () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.queue_music_outlined,
            size: 56,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text('播放列表为空', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '长按歌曲加入播放列表',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildHint(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '没有手动加入的歌曲',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }

  IconData _playModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.list:
        return Icons.repeat;
      case PlayMode.one:
        return Icons.repeat_one;
      case PlayMode.shuffle:
        return Icons.shuffle;
    }
  }

  String _playModeLabel(PlayMode mode) {
    switch (mode) {
      case PlayMode.list:
        return '列表循环';
      case PlayMode.one:
        return '单曲循环';
      case PlayMode.shuffle:
        return '随机播放';
    }
  }
}

class _CurrentTile extends StatelessWidget {
  final Track track;

  const _CurrentTile({required this.track});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withAlpha(20),
      child: InkWell(
        onTap: () => AudioPlayerService.instance.togglePlay(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CoverImage(
                  coverPath: track.coverPath,
                  seed: track.title,
                  size: 40,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      track.displayArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.lock_outline,
                size: 16,
                color: theme.colorScheme.primary.withAlpha(160),
              ),
              const SizedBox(width: 6),
              StreamBuilder<bool>(
                stream: AudioPlayerService.instance.playingStream,
                builder: (context, snap) {
                  final playing = snap.data ?? false;
                  return Icon(
                    playing ? Icons.equalizer : Icons.pause_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  final PlayQueueItem item;
  final int index;

  const _QueueItem({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audio = AudioPlayerService.instance;
    final track = item.track;

    return ListTile(
      key: key,
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CoverImage(coverPath: track.coverPath, seed: track.title, size: 40),
      ),
      title: Text(
        track.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.displayArtist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            visualDensity: VisualDensity.compact,
            tooltip: '从播放列表移除',
            onPressed: () => audio.removeFromQueue(index),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(left: 4, right: 8),
              child: Icon(Icons.drag_indicator_rounded, size: 22),
            ),
          ),
        ],
      ),
      onTap: () => audio.jumpToQueueItem(index),
    );
  }
}

class _ProxyDecorator extends StatelessWidget {
  final Widget child;
  final Color color;

  const _ProxyDecorator({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}