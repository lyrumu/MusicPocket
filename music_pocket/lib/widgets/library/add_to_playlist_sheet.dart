import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/playlist_provider.dart';
import '../common/text_input_dialog.dart';

class AddToPlaylistSheet extends ConsumerWidget {
  final Track track;

  const AddToPlaylistSheet({super.key, required this.track});

  static Future<void> show(BuildContext context, Track track) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddToPlaylistSheet(track: track),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlistsAsync = ref.watch(playlistsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '加入歌单',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _createPlaylist(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('新建'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: playlistsAsync.when(
                data: (playlists) {
                  if (playlists.isEmpty) {
                    return const Center(child: Text('还没有歌单'));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final item = playlists[index];
                      return ListTile(
                        title: Text(item.playlist.name),
                        subtitle: Text('${item.trackCount} 首歌曲'),
                        onTap: () => _addToPlaylist(context, ref, item.playlist),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    final name = await TextInputDialog.show(
      context: context,
      title: '新建歌单',
      hintText: '歌单名称',
      confirmText: '创建',
    );
    if (name == null || name.isEmpty || !context.mounted) return;

    await ref.read(playlistRepositoryProvider).create(name);
  }

  Future<void> _addToPlaylist(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final result = await ref
        .read(playlistRepositoryProvider)
        .addTrack(playlist.id, track.id);
    if (!context.mounted) return;

    Navigator.of(context).pop();
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${track.title} 已在这首歌单中')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加到 ${playlist.name}')),
      );
    }
  }
}
