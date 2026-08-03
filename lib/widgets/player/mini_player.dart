import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/track_provider.dart';
import '../../services/audio_player_service.dart';
import '../common/cover_placeholder.dart';
import 'play_queue_sheet.dart';

enum _MiniAction { playMode, queue, close }

class MiniPlayer extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  double? _dragValue;
  int _seekVersion = 0;

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService.instance;
    final currentTrack = ref.watch(currentTrackProvider).asData?.value;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh.withAlpha(248),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(
                    theme.brightness == Brightness.dark ? 38 : 18,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 700;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(10, 7, 8, 3),
                        child: Row(
                          children: [
                            CoverImage(
                              coverPath: currentTrack?.coverPath,
                              seed: currentTrack?.title ?? 'current',
                              size: 48,
                              radius: 11,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentTrack?.title ?? '尚未播放',
                                    style: theme.textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentTrack?.artist ?? '选择一首歌曲',
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (!compact) _buildPlayModeButton(audioService),
                            _controlButton(
                              tooltip: '上一首',
                              icon: Icons.skip_previous_rounded,
                              onPressed: audioService.playPrevious,
                            ),
                            _buildPlayButton(audioService),
                            _controlButton(
                              tooltip: '下一首',
                              icon: Icons.skip_next_rounded,
                              onPressed: audioService.playNext,
                            ),
                            if (compact)
                              _buildCompactMenu(audioService)
                            else ...[
                              _controlButton(
                                tooltip: '播放队列',
                                icon: Icons.queue_music_rounded,
                                onPressed: () => PlayQueueSheet.show(context),
                              ),
                              _controlButton(
                                tooltip: '关闭播放器',
                                icon: Icons.close_rounded,
                                color: theme.colorScheme.outline,
                                onPressed: audioService.stopPlayback,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _buildProgressBar(audioService, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      iconSize: 23,
      color: color,
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }

  Widget _buildPlayButton(AudioPlayerService audioService) {
    return StreamBuilder<bool>(
      stream: audioService.playingStream,
      initialData: false,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return IconButton.filled(
          tooltip: isPlaying ? '暂停' : '播放',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          iconSize: 25,
          icon: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
          onPressed: audioService.togglePlay,
        );
      },
    );
  }

  Widget _buildPlayModeButton(AudioPlayerService audioService) {
    final mode =
        ref.watch(playModeProvider).asData?.value ?? audioService.playMode;
    return _controlButton(
      tooltip: _playModeLabel(mode),
      icon: _playModeIcon(mode),
      color: Theme.of(context).colorScheme.primary,
      onPressed: audioService.cyclePlayMode,
    );
  }

  Widget _buildCompactMenu(AudioPlayerService audioService) {
    final mode =
        ref.watch(playModeProvider).asData?.value ?? audioService.playMode;
    return PopupMenuButton<_MiniAction>(
      tooltip: '播放器操作',
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (action) {
        switch (action) {
          case _MiniAction.playMode:
            audioService.cyclePlayMode();
            break;
          case _MiniAction.queue:
            PlayQueueSheet.show(context);
            break;
          case _MiniAction.close:
            audioService.stopPlayback();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MiniAction.playMode,
          child: Row(
            children: [
              Icon(_playModeIcon(mode), size: 20),
              const SizedBox(width: 12),
              Text(_playModeLabel(mode)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: _MiniAction.queue,
          child: Row(
            children: [
              Icon(Icons.queue_music_rounded, size: 20),
              SizedBox(width: 12),
              Text('播放队列'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: _MiniAction.close,
          child: Row(
            children: [
              Icon(Icons.close_rounded, size: 20),
              SizedBox(width: 12),
              Text('关闭播放器'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(AudioPlayerService audioService, ThemeData theme) {
    return StreamBuilder<Duration?>(
      stream: audioService.durationStream,
      initialData: audioService.duration,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
        return StreamBuilder<Duration>(
          stream: audioService.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final enabled = duration.inMilliseconds > 0;
            final raw =
                _dragValue ??
                (enabled && position <= duration
                    ? position.inMilliseconds.clamp(0, maxMs).toDouble()
                    : 0.0);
            final value = raw.clamp(0.0, maxMs.toDouble());
            return SliderTheme(
              data: theme.sliderTheme.copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 3),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 9),
              ),
              child: SizedBox(
                height: 12,
                child: Slider(
                  value: value,
                  min: 0,
                  max: maxMs.toDouble(),
                  onChanged: enabled
                      ? (value) => setState(() => _dragValue = value)
                      : null,
                  onChangeStart: _startSeeking,
                  onChangeEnd: (value) => _finishSeeking(audioService, value),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startSeeking(double value) {
    _seekVersion++;
    setState(() => _dragValue = value);
  }

  Future<void> _finishSeeking(
    AudioPlayerService audioService,
    double value,
  ) async {
    final version = _seekVersion;
    try {
      await audioService.seek(Duration(milliseconds: value.toInt()));
    } finally {
      if (mounted && version == _seekVersion) {
        setState(() => _dragValue = null);
      }
    }
  }

  IconData _playModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.list:
        return Icons.repeat_rounded;
      case PlayMode.one:
        return Icons.repeat_one_rounded;
      case PlayMode.shuffle:
        return Icons.shuffle_rounded;
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
