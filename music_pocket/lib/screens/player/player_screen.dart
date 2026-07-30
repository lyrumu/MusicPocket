import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/database_provider.dart';
import '../../providers/track_provider.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/common/cover_placeholder.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final audioService = AudioPlayerService.instance;
    final currentTrack = ref.watch(currentTrackProvider).asData?.value;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? AppColors.darkBgBase : AppColors.lightBgBase,
              isDark
                  ? AppColors.darkBgBase.withAlpha(240)
                  : AppColors.lightBgBase.withAlpha(240),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _buildTopBar(context),
                        const Spacer(),
                        _buildAlbumArt(currentTrack),
                        const Spacer(),
                        _buildTrackInfo(context, currentTrack),
                        const SizedBox(height: 24),
                        _buildProgressBar(
                          context,
                          ref,
                          audioService,
                          currentTrack,
                        ),
                        const SizedBox(height: 16),
                        _buildControls(context, ref, audioService, currentTrack),
                        const SizedBox(height: 32),
                        _buildBottomActions(context, ref, currentTrack),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Column(
            children: [
              Text('正在播放', style: Theme.of(context).textTheme.bodySmall),
              Text('播放列表', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(dynamic currentTrack) {
    final coverPath =
        currentTrack?.coverPath != null &&
            File(currentTrack!.coverPath!).existsSync()
        ? currentTrack.coverPath
        : null;
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CoverImage(
        coverPath: coverPath,
        seed: currentTrack?.title ?? 'placeholder',
        size: 300,
        radius: 16,
      ),
    );
  }

  Widget _buildTrackInfo(BuildContext context, currentTrack) {
    final title = currentTrack?.title ?? '尚未播放';
    final subtitle = currentTrack == null
        ? '选择一首歌曲开始播放'
        : (currentTrack.artist.isEmpty
              ? currentTrack.album
              : '${currentTrack.artist} · ${currentTrack.album}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    WidgetRef ref,
    AudioPlayerService audioService,
    currentTrack,
  ) {
    return StreamBuilder<Duration>(
      stream: audioService.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = audioService.duration;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor: Theme.of(
                    context,
                  ).colorScheme.outline.withAlpha(60),
                  thumbColor: Theme.of(context).colorScheme.primary,
                  overlayColor: Theme.of(
                    context,
                  ).colorScheme.primary.withAlpha(30),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Slider(
                  value: duration.inMilliseconds > 0
                      ? position.inMilliseconds
                            .clamp(0, duration.inMilliseconds)
                            .toDouble()
                      : 0,
                  min: 0,
                  max: duration.inMilliseconds > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1,
                  onChanged: duration.inMilliseconds > 0
                      ? (value) => audioService.seek(
                          Duration(milliseconds: value.toInt()),
                        )
                      : null,
                ),
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
          ),
        );
      },
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    AudioPlayerService audioService,
    currentTrack,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final mode =
                  ref.watch(playModeProvider).asData?.value ??
                  audioService.playMode;
              return IconButton(
                icon: Icon(
                  _getPlayModeIcon(mode),
                  color: mode != PlayMode.list
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                onPressed: audioService.cyclePlayMode,
              );
            },
          ),
          IconButton(
            iconSize: 36,
            icon: const Icon(Icons.skip_previous_rounded),
            onPressed: audioService.playPrevious,
          ),
          StreamBuilder<bool>(
            stream: audioService.playingStream,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;
              return Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: IconButton(
                  iconSize: 36,
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  onPressed: audioService.togglePlay,
                ),
              );
            },
          ),
          IconButton(
            iconSize: 36,
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: audioService.playNext,
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    WidgetRef ref,
    currentTrack,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              currentTrack?.isFavorite == true
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: currentTrack?.isFavorite == true
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: currentTrack == null
                ? null
                : () async {
                    final repo = ref.read(trackRepositoryProvider);
                    await repo.toggleFavorite(
                      currentTrack.id,
                      !currentTrack.isFavorite,
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: currentTrack == null ? null : () {},
          ),
          IconButton(icon: const Icon(Icons.queue_music), onPressed: () {}),
        ],
      ),
    );
  }

  IconData _getPlayModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.list:
        return Icons.repeat;
      case PlayMode.one:
        return Icons.repeat_one;
      case PlayMode.shuffle:
        return Icons.shuffle;
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
