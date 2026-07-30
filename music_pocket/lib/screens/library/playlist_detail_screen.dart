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
import '../../widgets/player/mini_player.dart';
import '../player/player_screen.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tracksAsync = ref.watch(playlistTracksProvider(playlist.id));
    final currentTrack = ref.watch(currentTrackProvider).asData?.value;

    final tracks = tracksAsync.asData?.value ?? [];
    final coverPath = tracks
        .where((t) => t.coverPath != null && t.coverPath!.isNotEmpty)
        .firstOrNull
        ?.coverPath;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 220,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow_rounded),
                      tooltip: '播放全部',
                      onPressed: () => _playAll(context, ref),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    background: Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: coverPath != null
                            ? CoverImage(
                                coverPath: coverPath,
                                seed: playlist.name,
                                size: 120,
                                radius: 60,
                              )
                            : const Icon(Icons.queue_music, size: 96),
                      ),
                    ),
                  ),
                ),
                tracksAsync.when(
                  data: (loadedTracks) {
                    if (loadedTracks.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Text('歌单里还没有歌曲'),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final track = loadedTracks[index];
                          final isCurrent = currentTrack?.id == track.id;
                          return Dismissible(
                            key: ValueKey(
                              'playlist_${playlist.id}_track_${track.id}',
                            ),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: theme.colorScheme.error,
                              child: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.onError,
                              ),
                            ),
                            onDismissed: (_) => _removeTrack(ref, track),
                            child: TrackListTile(
                              track: track,
                              isPlaying: isCurrent,
                              onTap: () => _playTrack(context, loadedTracks, track),
                              onLongPress: () {},
                              onEdit: null,
                            ),
                          );
                        },
                        childCount: loadedTracks.length,
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(child: Text('加载失败: $e')),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 16),
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

  void _playTrack(
    BuildContext context,
    List<Track> tracks,
    Track track,
  ) {
    AudioPlayerService.instance.playTracks(
      tracks,
      startIndex: tracks.indexOf(track),
    );
  }

  void _playAll(BuildContext context, WidgetRef ref) {
    final tracks = ref.read(playlistTracksProvider(playlist.id)).asData?.value ?? [];
    if (tracks.isEmpty) return;
    AudioPlayerService.instance.playTracks(tracks);
  }

  Future<void> _removeTrack(WidgetRef ref, Track track) async {
    await ref
        .read(playlistRepositoryProvider)
        .removeTrack(playlist.id, track.id);
  }

  void _openFullPlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          );
        },
      ),
    );
  }
}
