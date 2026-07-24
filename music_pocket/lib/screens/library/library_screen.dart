import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/track_provider.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/library/track_edit_sheet.dart';
import '../../widgets/library/track_list_tile.dart';
import '../import/import_screen.dart';

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

    return SafeArea(
      child: Column(
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
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _openImportScreen(context),
                  tooltip: '导入音乐',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTracksList(tracks, currentTrack),
                _buildPlaceholder(
                  icon: Icons.person_outline,
                  title: '艺术家',
                  subtitle: '${_uniqueCount(tracks.map((t) => t.artist))} 位艺术家',
                ),
                _buildPlaceholder(
                  icon: Icons.playlist_play_outlined,
                  title: '暂无歌单',
                  subtitle: '歌单创建与管理功能后续实现',
                  actionText: '敬请期待',
                ),
              ],
            ),
          ),
        ],
      ),
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
            Text('点击右上角 + 导入音频', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
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
          onLongPress: () => TrackEditSheet.show(context, track),
        );
      },
    );
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (actionText != null) ...[
            const SizedBox(height: 12),
            Text(
              actionText,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  int _uniqueCount(Iterable<String> values) {
    final set = <String>{};
    for (final v in values) {
      final trimmed = v.trim();
      if (trimmed.isNotEmpty) set.add(trimmed);
    }
    return set.length;
  }

  void _openImportScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ImportScreen()));
  }
}
