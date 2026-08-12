import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/track_provider.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/common/cover_placeholder.dart';
import '../../widgets/library/track_list_tile.dart';
import '../../widgets/library/track_quick_actions.dart';
import '../../widgets/player/mini_player.dart';
import '../player/player_screen.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  bool _isManaging = false;

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(playlistTracksProvider(widget.playlist.id));
    final currentTrack = ref.watch(currentTrackProvider).asData?.value;
    final tracks = tracksAsync.asData?.value ?? [];
    final coverPath = tracks
        .where((track) => track.coverPath?.isNotEmpty ?? false)
        .firstOrNull
        ?.coverPath;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        actions: [
          TextButton(
            onPressed: tracks.isEmpty && !_isManaging
                ? null
                : () => setState(() => _isManaging = !_isManaging),
            child: Text(_isManaging ? '完成' : '管理'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _PlaylistHeader(
                    playlist: widget.playlist,
                    coverPath: coverPath,
                    trackCount: tracks.length,
                    onPlayAll: tracks.isEmpty ? null : _playAll,
                  ),
                ),
                tracksAsync.when(
                  data: (loadedTracks) {
                    if (loadedTracks.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text('歌单里还没有歌曲')),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final track = loadedTracks[index];
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 940),
                              child: TrackListTile(
                                track: track,
                                isPlaying: currentTrack?.id == track.id,
                                onTap: () => _playTrack(loadedTracks, track),
                                onLongPress: () =>
                                    TrackQuickActions.show(context, track),
                                onPlayNext: () => AudioPlayerService.instance
                                    .playNextTrack(track),
                                onRemove: _isManaging
                                    ? () => _removeTrack(track)
                                    : null,
                              ),
                            ),
                          );
                        }, childCount: loadedTracks.length),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    child: Center(child: Text('加载失败: $error')),
                  ),
                ),
              ],
            ),
          ),
          if (currentTrack != null)
            MiniPlayer(
              key: const ValueKey('playlist_mini_player'),
              onTap: () => _openFullPlayer(context),
            ),
        ],
      ),
    );
  }

  void _playTrack(List<Track> tracks, Track track) {
    AudioPlayerService.instance.playFromPlaylist(
      widget.playlist.id,
      tracks,
      startIndex: tracks.indexOf(track),
    );
  }

  void _playAll() {
    final tracks =
        ref.read(playlistTracksProvider(widget.playlist.id)).asData?.value ??
        [];
    if (tracks.isEmpty) return;
    AudioPlayerService.instance.playFromPlaylist(
      widget.playlist.id,
      tracks,
      toggleIfCurrent: false,
    );
  }

  Future<void> _removeTrack(Track track) async {
    await ref
        .read(playlistRepositoryProvider)
        .removeTrack(widget.playlist.id, track.id);
  }

  void _openFullPlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const PlayerScreen(),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: animation.drive(
            Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PlaylistHeader extends StatelessWidget {
  final Playlist playlist;
  final String? coverPath;
  final int trackCount;
  final VoidCallback? onPlayAll;

  const _PlaylistHeader({
    required this.playlist,
    required this.coverPath,
    required this.trackCount,
    required this.onPlayAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 940),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final artwork = PocketAlbumArtwork(
              coverPath: coverPath,
              seed: playlist.name,
              size: compact ? 190 : 220,
            );
            final details = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text('歌单', style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  playlist.name,
                  style: theme.textTheme.headlineLarge,
                  textAlign: compact ? TextAlign.center : TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '$trackCount 首歌曲 · 全部储存在本机',
                  style: theme.textTheme.bodyMedium,
                  textAlign: compact ? TextAlign.center : TextAlign.left,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onPlayAll,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('播放全部'),
                ),
              ],
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              child: compact
                  ? Column(
                      children: [artwork, const SizedBox(height: 14), details],
                    )
                  : Row(
                      children: [
                        artwork,
                        const SizedBox(width: 34),
                        Expanded(child: details),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
