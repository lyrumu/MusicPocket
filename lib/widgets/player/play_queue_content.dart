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
        if (snapshot.current != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _CurrentTile(track: snapshot.current!),
          ),
        Expanded(
          child: snapshot.upNext.isEmpty && snapshot.current == null
              ? _buildEmpty(theme)
              : snapshot.upNext.isEmpty
              ? _buildHint(theme)
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
      child: Row(
        children: [
          Text('播放队列', style: theme.textTheme.titleLarge),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.queue_music_outlined,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text('播放队列为空', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('长按歌曲加入播放列表', style: theme.textTheme.bodySmall),
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
      color: theme.colorScheme.primaryContainer.withAlpha(120),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => AudioPlayerService.instance.togglePlay(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
          child: Row(
            children: [
              CoverImage(
                coverPath: track.coverPath,
                seed: track.title,
                size: 46,
                radius: 10,
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

  const _QueueItem({super.key, required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audio = AudioPlayerService.instance;
    final track = item.track;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: key,
          minTileHeight: 64,
          contentPadding: const EdgeInsets.fromLTRB(10, 0, 4, 0),
          leading: CoverImage(
            coverPath: track.coverPath,
            seed: track.title,
            size: 46,
            radius: 10,
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
                tooltip: '从播放队列移除',
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
        ),
      ),
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
            BoxShadow(color: color, blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      ),
    );
  }
}
