import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../providers/track_provider.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/common/cover_placeholder.dart';
import '../../widgets/player/play_queue_sheet.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  double? _dragValue;
  int _seekVersion = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audioService = AudioPlayerService.instance;
    final currentTrack = ref.watch(currentTrackProvider).asData?.value;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.65),
            radius: 1.2,
            colors: [
              AppColors.oat(
                context,
              ).withAlpha(theme.brightness == Brightness.dark ? 62 : 100),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<bool>(
            stream: audioService.playingStream,
            initialData: false,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;
              return Column(
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final desktop = constraints.maxWidth >= 840;
                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            desktop ? 36 : 24,
                            desktop ? 28 : 12,
                            desktop ? 36 : 24,
                            30,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: math.max(
                                0,
                                constraints.maxHeight - 58,
                              ),
                            ),
                            child: desktop
                                ? _buildDesktopPlayer(
                                    constraints,
                                    currentTrack,
                                    audioService,
                                    isPlaying,
                                  )
                                : _buildMobilePlayer(
                                    constraints,
                                    currentTrack,
                                    audioService,
                                    isPlaying,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: '收起播放器',
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => PlayQueueSheet.show(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  children: [
                    Text('正在播放', style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      '查看播放队列',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPlayer(
    BoxConstraints constraints,
    Track? currentTrack,
    AudioPlayerService audioService,
    bool isPlaying,
  ) {
    final artSize = math.min(430.0, constraints.maxWidth * 0.44);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: PocketAlbumArtwork(
                  coverPath: currentTrack?.coverPath,
                  seed: currentTrack?.title ?? 'placeholder',
                  size: artSize,
                  isPlaying: isPlaying,
                ),
              ),
            ),
            const SizedBox(width: 52),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: _buildPlayerDetails(
                  currentTrack,
                  audioService,
                  isPlaying,
                  centered: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePlayer(
    BoxConstraints constraints,
    Track? currentTrack,
    AudioPlayerService audioService,
    bool isPlaying,
  ) {
    final artSize = math.min(350.0, math.max(230.0, constraints.maxWidth - 36));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PocketAlbumArtwork(
          coverPath: currentTrack?.coverPath,
          seed: currentTrack?.title ?? 'placeholder',
          size: artSize,
          isPlaying: isPlaying,
        ),
        const SizedBox(height: 24),
        _buildPlayerDetails(
          currentTrack,
          audioService,
          isPlaying,
          centered: true,
        ),
      ],
    );
  }

  Widget _buildPlayerDetails(
    Track? currentTrack,
    AudioPlayerService audioService,
    bool isPlaying, {
    required bool centered,
  }) {
    final theme = Theme.of(context);
    final title = currentTrack?.title ?? '尚未播放';
    final subtitle = currentTrack == null
        ? '选择一首歌曲开始播放'
        : currentTrack.artist.isEmpty
        ? currentTrack.album
        : '${currentTrack.artist} · ${currentTrack.album}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          '仅在本机',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.clay(context),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: theme.textTheme.headlineMedium,
          textAlign: centered ? TextAlign.center : TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium,
          textAlign: centered ? TextAlign.center : TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 22),
        _buildProgressBar(audioService),
        const SizedBox(height: 16),
        _buildControls(audioService, isPlaying),
      ],
    );
  }

  Widget _buildProgressBar(AudioPlayerService audioService) {
    return StreamBuilder<Duration>(
      stream: audioService.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? audioService.position;
        final duration = audioService.duration;
        final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
        final enabled = duration.inMilliseconds > 0;
        final value =
            (_dragValue ??
                    (enabled
                        ? position.inMilliseconds.clamp(0, maxMs).toDouble()
                        : 0.0))
                .clamp(0.0, maxMs.toDouble());
        return Column(
          children: [
            Slider(
              value: value,
              min: 0,
              max: maxMs.toDouble(),
              onChanged: enabled
                  ? (value) => setState(() => _dragValue = value)
                  : null,
              onChangeStart: _startSeeking,
              onChangeEnd: (value) => _finishSeeking(audioService, value),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(position),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _fmt(duration),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(AudioPlayerService audioService, bool isPlaying) {
    final theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, _) {
        final mode =
            ref.watch(playModeProvider).asData?.value ?? audioService.playMode;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: _playModeLabel(mode),
              icon: Icon(_playModeIcon(mode)),
              color: mode == PlayMode.list
                  ? theme.colorScheme.outline
                  : theme.colorScheme.primary,
              onPressed: audioService.cyclePlayMode,
            ),
            IconButton(
              tooltip: '上一首',
              iconSize: 34,
              icon: const Icon(Icons.skip_previous_rounded),
              onPressed: audioService.playPrevious,
            ),
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(62),
                    blurRadius: 22,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: IconButton(
                tooltip: isPlaying ? '暂停' : '播放',
                iconSize: 34,
                color: Colors.white,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                onPressed: audioService.togglePlay,
              ),
            ),
            IconButton(
              tooltip: '下一首',
              iconSize: 34,
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: audioService.playNext,
            ),
            IconButton(
              tooltip: '播放队列',
              icon: const Icon(Icons.queue_music_rounded),
              onPressed: () => PlayQueueSheet.show(context),
            ),
          ],
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

  String _fmt(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
