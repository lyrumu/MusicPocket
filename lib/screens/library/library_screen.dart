import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/artist_provider.dart';
import '../../providers/track_provider.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/common/cover_placeholder.dart';
import '../../widgets/library/add_to_playlist_sheet.dart';
import '../../widgets/library/track_edit_sheet.dart';
import '../../widgets/library/track_list_tile.dart';
import '../../widgets/library/track_quick_actions.dart';
import 'artist_detail_screen.dart';
import 'playlist_tab.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tracks = ref.watch(tracksProvider).asData?.value ?? [];
    final currentTrack = ref.watch(currentTrackProvider).asData?.value;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 430),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerHeight: 0,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: theme.colorScheme.onPrimaryContainer,
                    unselectedLabelColor: theme.colorScheme.outline,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tabs: const [
                      Tab(text: '歌曲'),
                      Tab(text: '艺术家'),
                      Tab(text: '歌单'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text('${tracks.length} 首', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTracksList(tracks, currentTrack),
              _buildArtistsList(),
              const PlaylistTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTracksList(List<Track> tracks, Track? currentTrack) {
    if (tracks.isEmpty) {
      return const _LibraryEmptyState(
        icon: Icons.queue_music_outlined,
        title: '口袋里还没有音乐',
        subtitle: '点击导入，加入保存在本机的音频',
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 940),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return TrackListTile(
              track: track,
              isPlaying: currentTrack?.id == track.id,
              onTap: () {
                AudioPlayerService.instance.playTracks(
                  tracks,
                  startIndex: index,
                );
              },
              onLongPress: () => TrackQuickActions.show(context, track),
              onPlayNext: () =>
                  AudioPlayerService.instance.playNextTrack(track),
              onEdit: () => TrackEditSheet.show(context, track),
              onAddToPlaylist: () => AddToPlaylistSheet.show(context, track),
            );
          },
        ),
      ),
    );
  }

  Widget _buildArtistsList() {
    final artists = ref.watch(artistsProvider);
    if (artists.isEmpty) {
      return const _LibraryEmptyState(
        icon: Icons.person_outline_rounded,
        title: '还没有艺术家',
        subtitle: '导入歌曲后会自动按艺术家归档',
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 940),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  minTileHeight: 66,
                  leading: CoverImage(
                    coverPath: artist.coverPath,
                    seed: artist.name,
                    size: 50,
                    radius: 11,
                  ),
                  title: Text(
                    artist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${artist.tracks.length} 首歌曲',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openArtistDetail(context, artist.name),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openArtistDetail(BuildContext context, String artistName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistDetailScreen(artistName: artistName),
      ),
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LibraryEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: Icon(icon, color: theme.colorScheme.primary, size: 32),
            ),
            const SizedBox(height: 18),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
