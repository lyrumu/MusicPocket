import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/track_provider.dart';
import '../../services/audio_player_service.dart';
import '../common/cover_placeholder.dart';
import 'play_queue_sheet.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService.instance;
    final currentTrack = ref.watch(currentTrackProvider).asData?.value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkBgDeep.withAlpha(230)
              : AppColors.lightBgDeep.withAlpha(230),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildProgressBar(audioService, theme),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    CoverImage(
                      coverPath: currentTrack?.coverPath,
                      seed: currentTrack?.title ?? 'current',
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    _buildTrackInfo(
                      context,
                      currentTrack?.title,
                      currentTrack?.artist,
                    ),
                    _buildCenterControls(context, audioService),
                    _buildSideControls(context, audioService),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(AudioPlayerService audioService, ThemeData theme) {
    return StreamBuilder<Duration?>(
      stream: audioService.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
        return StreamBuilder<Duration>(
          stream: audioService.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final enabled = duration.inMilliseconds > 0;
            final raw = _dragValue ??
                (enabled && position <= duration
                    ? position.inMilliseconds.clamp(0, maxMs).toDouble()
                    : 0.0);
            final value = raw.clamp(0.0, maxMs.toDouble());
            return SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: theme.colorScheme.outline.withAlpha(50),
                thumbColor: theme.colorScheme.primary,
                overlayColor: theme.colorScheme.primary.withAlpha(30),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: SizedBox(
                height: 12,
                child: Slider(
                  value: value,
                  min: 0,
                  max: maxMs.toDouble(),
                  onChanged:
                      enabled ? (v) => setState(() => _dragValue = v) : null,
                  onChangeStart: (v) => setState(() => _dragValue = v),
                  onChangeEnd: (v) {
                    setState(() => _dragValue = null);
                    audioService.seek(Duration(milliseconds: v.toInt()));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrackInfo(BuildContext context, String? title, String? artist) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? '尚未播放',
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            artist ?? '选择一首歌曲',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls(
    BuildContext context,
    AudioPlayerService audioService,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          iconSize: 26,
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: () => audioService.playPrevious(),
        ),
        StreamBuilder<bool>(
          stream: audioService.playingStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data ?? false;
            return IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              iconSize: 30,
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              onPressed: () => audioService.togglePlay(),
            );
          },
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          iconSize: 26,
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: () => audioService.playNext(),
        ),
      ],
    );
  }

  Widget _buildSideControls(
    BuildContext context,
    AudioPlayerService audioService,
  ) {
    final modeAsync = ref.watch(playModeProvider);
    final mode = modeAsync.asData?.value ?? audioService.playMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          iconSize: 18,
          icon: Icon(_playModeIcon(mode)),
          color: Theme.of(context).colorScheme.primary,
          onPressed: audioService.cyclePlayMode,
          tooltip: _playModeLabel(mode),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          iconSize: 18,
          icon: const Icon(Icons.queue_music_rounded),
          color: Theme.of(context).colorScheme.primary,
          tooltip: '播放列表',
          onPressed: () => PlayQueueSheet.show(context),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          iconSize: 18,
          icon: const Icon(Icons.close_rounded),
          color: Theme.of(context).colorScheme.outline,
          onPressed: () => audioService.stopPlayback(),
          tooltip: '关闭播放器',
        ),
      ],
    );
  }

  IconData _playModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.list:
        return Icons.repeat;
      case PlayMode.one:
        return Icons.repeat_one;
      case PlayMode.shuffle:
        return Icons.shuffle;
    }
  }

  String _playModeLabel(PlayMode mode) {
    switch (mode) {
      case PlayMode.list:
        return '列表循环';
      case PlayMode.one:
        return '单曲循环';
      case PlayMode.shuffle:
        return '随机播放';
    }
  }
}
