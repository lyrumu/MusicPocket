import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/daos/playlist_dao.dart';
import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/common/cover_placeholder.dart';
import '../../widgets/common/text_input_dialog.dart';
import 'playlist_detail_screen.dart';

class PlaylistTab extends ConsumerWidget {
  const PlaylistTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return playlistsAsync.when(
      data: (playlists) {
        if (playlists.isEmpty) {
          return _buildEmpty(context, ref);
        }
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: playlists.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHeader(context, ref);
                }
                final item = playlists[index - 1];
                return _PlaylistTile(
                  item: item,
                  onTap: () => _openDetail(context, item.playlist),
                  onRename: () => _renamePlaylist(context, ref, item.playlist),
                  onDelete: () => _deletePlaylist(context, ref, item.playlist),
                );
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.playlist_play_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text('还没有歌单', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('创建你的第一个歌单', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _createPlaylist(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('新建歌单'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 0, 8),
      child: Row(
        children: [
          Text('我的歌单', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建歌单',
            onPressed: () => _createPlaylist(context, ref),
          ),
        ],
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

  Future<void> _renamePlaylist(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final name = await TextInputDialog.show(
      context: context,
      title: '重命名歌单',
      initialValue: playlist.name,
      hintText: '歌单名称',
      confirmText: '保存',
    );
    if (name == null || name.isEmpty || name == playlist.name) return;

    await ref.read(playlistRepositoryProvider).rename(playlist.id, name);
  }

  Future<void> _deletePlaylist(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除歌单'),
        content: Text('确定删除歌单 "${playlist.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(playlistRepositoryProvider).deletePlaylist(playlist.id);
  }

  void _openDetail(BuildContext context, Playlist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final PlaylistWithTrackCount item;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _PlaylistTile({
    required this.item,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          minTileHeight: 66,
          leading: CoverImage(
            coverPath: item.coverPath,
            seed: item.playlist.name,
            size: 50,
            radius: 11,
          ),
          title: Text(
            item.playlist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${item.trackCount} 首歌曲',
            style: theme.textTheme.bodySmall,
          ),
          trailing: PopupMenuButton<VoidCallback>(
            tooltip: '歌单操作',
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: onRename,
                child: const Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('重命名'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: onDelete,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '删除',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
