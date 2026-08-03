import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/artist_provider.dart';
import '../../providers/track_provider.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/common/cover_placeholder.dart';
import '../../widgets/library/add_to_playlist_sheet.dart';
import '../../widgets/library/track_list_tile.dart';
import '../../widgets/library/track_quick_actions.dart';
import '../../widgets/player/mini_player.dart';
import '../player/player_screen.dart';

class ArtistDetailScreen extends ConsumerWidget {
  final String artistName;

  const ArtistDetailScreen({super.key, required this.artistName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artist = ref.watch(artistProvider(artistName));
    final currentTrack = ref.watch(currentTrackProvider).asData?.value;

    if (artist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('艺术家')),
        body: const Center(child: Text('未找到艺术家')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(artist.name)),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ArtistHeader(
                    artist: artist,
                    onPlayAll: () => _playArtist(artist),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final track = artist.tracks[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 940),
                          child: TrackListTile(
                            track: track,
                            isPlaying: currentTrack?.id == track.id,
                            onTap: () => _playTrack(artist, track),
                            onLongPress: () =>
                                TrackQuickActions.show(context, track),
                            onPlayNext: () => AudioPlayerService.instance
                                .playNextTrack(track),
                            onAddToPlaylist: () =>
                                AddToPlaylistSheet.show(context, track),
                          ),
                        ),
                      );
                    }, childCount: artist.tracks.length),
                  ),
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

  void _playTrack(Artist artist, Track track) {
    AudioPlayerService.instance.playFromArtist(
      artist.name,
      artist.tracks,
      startIndex: artist.tracks.indexOf(track),
    );
  }

  void _playArtist(Artist artist) {
    if (artist.tracks.isEmpty) return;
    AudioPlayerService.instance.playFromArtist(
      artist.name,
      artist.tracks,
      toggleIfCurrent: false,
    );
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

class _ArtistHeader extends StatelessWidget {
  final Artist artist;
  final VoidCallback onPlayAll;

  const _ArtistHeader({required this.artist, required this.onPlayAll});

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
              coverPath: artist.coverPath,
              seed: artist.name,
              size: compact ? 190 : 220,
            );
            final details = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text('艺术家', style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  artist.name,
                  style: theme.textTheme.headlineLarge,
                  textAlign: compact ? TextAlign.center : TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${artist.tracks.length} 首歌曲 · 全部储存在本机',
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
