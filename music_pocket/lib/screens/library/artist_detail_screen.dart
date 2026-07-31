import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/artist_provider.dart';
import '../../providers/track_provider.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/common/cover_placeholder.dart';
import '../../widgets/library/add_to_playlist_sheet.dart';
import '../../widgets/library/track_list_tile.dart';
import '../../widgets/player/mini_player.dart';
import '../player/player_screen.dart';

class ArtistDetailScreen extends ConsumerWidget {
  final String artistName;

  const ArtistDetailScreen({super.key, required this.artistName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artist = ref.watch(artistProvider(artistName));
    final theme = Theme.of(context);
    final currentTrack = ref.watch(currentTrackProvider).asData?.value;

    if (artist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('艺术家')),
        body: const Center(child: Text('未找到艺术家')),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 220,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(artist.name),
                    background: Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CoverImage(
                          coverPath: artist.coverPath,
                          seed: artist.name,
                          size: 120,
                          radius: 60,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          '${artist.tracks.length} 首歌曲',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () => _playArtist(context, artist),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('播放全部'),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = artist.tracks[index];
                      final isCurrent = currentTrack?.id == track.id;
                      return TrackListTile(
                        track: track,
                        isPlaying: isCurrent,
                        onTap: () => _playTrack(context, artist, track),
                        onLongPress: () {},
                        onEdit: null,
                        onAddToPlaylist: () =>
                            AddToPlaylistSheet.show(context, track),
                      );
                    },
                    childCount: artist.tracks.length,
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
              key: const ValueKey('artist_mini_player'),
              onTap: () => _openFullPlayer(context),
            ),
        ],
      ),
    );
  }

  void _playTrack(BuildContext context, Artist artist, Track track) {
    AudioPlayerService.instance.playTracks(
      artist.tracks,
      startIndex: artist.tracks.indexOf(track),
    );
  }

  void _playArtist(BuildContext context, Artist artist) {
    if (artist.tracks.isEmpty) return;
    AudioPlayerService.instance.playTracks(
      artist.tracks,
      toggleIfCurrent: false,
    );
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
