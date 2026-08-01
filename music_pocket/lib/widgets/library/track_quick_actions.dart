import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/track_extensions.dart';
import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../services/audio_player_service.dart';
import '../common/cover_placeholder.dart';
import 'add_to_playlist_sheet.dart';
import 'track_edit_sheet.dart';

class TrackQuickActions extends ConsumerWidget {
  final Track track;

  const TrackQuickActions({super.key, required this.track});

  static Future<void> show(BuildContext context, Track track) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TrackQuickActions(track: track),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CoverImage(
                    coverPath: track.coverPath,
                    seed: track.title,
                    size: 44,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        track.displayArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.play_circle_outlined),
            title: const Text('作为下一首播放'),
            onTap: () {
              AudioPlayerService.instance.playNextTrack(track);
              _toast(context, '将作为下一首播放');
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add_outlined),
            title: const Text('加入播放列表'),
            onTap: () {
              AudioPlayerService.instance.addToQueue(track);
              _toast(context, '已加入播放列表');
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music_outlined),
            title: const Text('加入歌单'),
            onTap: () {
              Navigator.of(context).pop();
              AddToPlaylistSheet.show(context, track);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('编辑信息'),
            onTap: () {
              Navigator.of(context).pop();
              TrackEditSheet.show(context, track);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text('删除歌曲', style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => _confirmDelete(context, ref),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    });
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除歌曲'),
        content: Text('确定删除「${track.displayTitle}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final repo = ref.read(trackRepositoryProvider);
    await repo.deleteTrack(track.id);
    if (AudioPlayerService.instance.currentTrack?.id == track.id) {
      await AudioPlayerService.instance.removeCurrentAndContinue();
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('已删除歌曲'), duration: Duration(seconds: 2)),
    );
  }
}