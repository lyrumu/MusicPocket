import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/database/app_database.dart';
import '../../providers/search_provider.dart';
import '../../providers/track_provider.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/common/cover_placeholder.dart';
import '../../widgets/library/add_to_playlist_sheet.dart';
import '../../widgets/library/track_edit_sheet.dart';
import '../../widgets/library/track_list_tile.dart';
import '../../widgets/library/track_quick_actions.dart';
import '../library/artist_detail_screen.dart';
import '../library/playlist_detail_screen.dart';

class _PlatformTarget {
  final String label;
  final String Function(String query) buildSearchUrl;

  const _PlatformTarget(this.label, this.buildSearchUrl);
}

final List<_PlatformTarget> _platforms = [
  _PlatformTarget(
    '网易云音乐',
    (q) => 'https://music.163.com/#/search/m/?s=${Uri.encodeQueryComponent(q)}',
  ),
  _PlatformTarget(
    'QQ音乐',
    (q) => 'https://y.qq.com/n/ryqq/search?w=${Uri.encodeQueryComponent(q)}',
  ),
  _PlatformTarget(
    'Apple Music',
    (q) =>
        'https://music.apple.com/cn/search?term=${Uri.encodeQueryComponent(q)}',
  ),
  _PlatformTarget(
    'Spotify',
    (q) => 'https://open.spotify.com/search/${Uri.encodeQueryComponent(q)}',
  ),
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  void _clearQuery() {
    _controller.clear();
    _debounce?.cancel();
    setState(() => _query = '');
  }

  Future<void> _launchPlatform(String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri);
      if (!ok && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法打开链接，请稍后重试')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('打开链接失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 940),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: _buildSearchField(theme),
            ),
            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onChanged: _onChanged,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: '搜索歌曲、艺术家或歌单',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearQuery,
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_query.isEmpty) {
      return _buildEmptyHint(
        theme,
        icon: Icons.search_rounded,
        title: '搜索本地资源',
        subtitle: '输入关键词即可搜索已导入的歌曲、艺术家与歌单。\n若本地没有匹配，可跳转到外部音乐平台继续搜索。',
      );
    }

    final resultsAsync = ref.watch(searchResultsProvider(_query));
    final currentTrack = ref.watch(currentTrackProvider).asData?.value;

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildEmptyHint(
        theme,
        icon: Icons.error_outline,
        title: '搜索出错',
        subtitle: '$e',
      ),
      data: (results) {
        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            if (results.tracks.isNotEmpty) ...[
              _buildSectionHeader(theme, '歌曲', results.tracks.length),
              ...results.tracks.map((track) {
                final isCurrent = currentTrack?.id == track.id;
                return TrackListTile(
                  track: track,
                  isPlaying: isCurrent,
                  onTap: () {
                    AudioPlayerService.instance.playTracks(
                      results.tracks,
                      startIndex: results.tracks.indexOf(track),
                    );
                  },
                  onLongPress: () => TrackQuickActions.show(context, track),
                  onPlayNext: () =>
                      AudioPlayerService.instance.playNextTrack(track),
                  onEdit: () => TrackEditSheet.show(context, track),
                  onAddToPlaylist: () =>
                      AddToPlaylistSheet.show(context, track),
                );
              }),
            ],
            if (results.artists.isNotEmpty) ...[
              _buildSectionHeader(theme, '艺术家', results.artists.length),
              ...results.artists.map(
                (artist) => ListTile(
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
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openArtist(context, artist.name),
                ),
              ),
            ],
            if (results.playlists.isNotEmpty) ...[
              _buildSectionHeader(theme, '歌单', results.playlists.length),
              ...results.playlists.map(
                (p) => ListTile(
                  leading: CoverImage(
                    coverPath: p.coverPath,
                    seed: p.playlist.name,
                    size: 48,
                  ),
                  title: Text(
                    p.playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${p.trackCount} 首歌曲',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openPlaylist(context, p.playlist),
                ),
              ),
            ],
            if (results.isEmpty)
              _buildEmptyHint(
                theme,
                icon: Icons.search_off_rounded,
                title: '本地未找到匹配结果',
                subtitle: '试试跳转到外部音乐平台搜索「$_query」',
              ),
            _buildExternalSection(theme, _query),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalSection(ThemeData theme, String query) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '在网上搜索',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '跳转到外部音乐平台搜索「$query」',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _platforms.map((p) {
              return ActionChip(
                label: Text(p.label),
                avatar: const Icon(Icons.open_in_new_rounded, size: 18),
                onPressed: () => _launchPlatform(p.buildSearchUrl(query)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHint(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 32, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 18),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openArtist(BuildContext context, String artistName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArtistDetailScreen(artistName: artistName),
      ),
    );
  }

  void _openPlaylist(BuildContext context, Playlist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }
}
