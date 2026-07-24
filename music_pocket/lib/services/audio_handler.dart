import 'package:audio_service/audio_service.dart';

import 'audio_player_service.dart';

class MusicPocketAudioHandler extends BaseAudioHandler with SeekHandler {
  MusicPocketAudioHandler();

  static const _commonActions = <MediaAction>{
    MediaAction.seek,
    MediaAction.skipToNext,
    MediaAction.skipToPrevious,
  };

  void emitState({required bool playing, required AudioProcessingState proc}) {
    final controls = <MediaControl>[
      MediaControl.skipToPrevious,
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
    ];
    final prev = playbackState.value;
    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: _commonActions,
        androidCompactActionIndices: const [0, 1, 2],
        processingState: proc,
        playing: playing,
        updatePosition: prev.position,
        bufferedPosition: prev.bufferedPosition,
        speed: 1.0,
        queueIndex: 0,
      ),
    );
  }

  void emitMediaItem(MediaItem item) => mediaItem.add(item);

  @override
  Future<void> play() => AudioPlayerService.instance.play();

  @override
  Future<void> pause() => AudioPlayerService.instance.pause();

  @override
  Future<void> stop() async {
    await AudioPlayerService.instance.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) =>
      AudioPlayerService.instance.seek(position);

  @override
  Future<void> skipToNext() => AudioPlayerService.instance.playNext();

  @override
  Future<void> skipToPrevious() => AudioPlayerService.instance.playPrevious();
}
