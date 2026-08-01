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
  late TabController _tabController;

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
    final tracksAsync = ref.watch(tracksProvider);
    final currentTrackAsync = ref.watch(currentTrackProvider);

    final tracks = tracksAsync.asData?.value ?? [];
    final currentTrack = currentTrackAsync.asData?.value;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerHeight: 0,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.outline,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: '歌曲'),
                    Tab(text: '艺术家'),
                    Tab(text: '歌单'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTracksList(tracks, currentTrack),
              _buildArtistsList(tracks),
              const PlaylistTab(),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildTracksList(List<Track> tracks, Track? currentTrack) {
    if (tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue_music_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('暂无歌曲', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('点击底部导入按钮添加音频', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isCurrent = currentTrack?.id == track.id;
        return TrackListTile(
          track: track,
          isPlaying: isCurrent,
          onTap: () {
            AudioPlayerService.instance.playTracks(tracks, startIndex: index);
          },
          onLongPress: () => TrackQuickActions.show(context, track),
          onPlayNext: () => AudioPlayerService.instance.playNextTrack(track),
          onEdit: () => TrackEditSheet.show(context, track),
          onAddToPlaylist: () => AddToPlaylistSheet.show(context, track),
        );
      },
    );
  }

  Widget _buildArtistsList(List<Track> tracks) {
    final artists = ref.watch(artistsProvider);

    if (artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('暂无艺术家', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              '导入歌曲后自动按艺术家分类',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ListTile(
          leading: CoverImage(
            coverPath: artist.coverPath,
            seed: artist.name,
            size: 48,
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
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openArtistDetail(context, artist.name),
        );
      },
    );
  }

  void _openArtistDetail(BuildContext context, String artistName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArtistDetailScreen(artistName: artistName),
      ),
    );
  }
}
