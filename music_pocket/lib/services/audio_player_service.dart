import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../data/database/app_database.dart';
import 'audio_handler.dart';

enum PlayMode { list, one, shuffle }

class AudioPlayerService {
  AudioPlayerService._() {
    unawaited(_player.setVolume(1.0));
    _durationSub = _player.durationStream.listen((d) {
      if (d != null) _duration = d;
    });
  }
  static final instance = AudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();
  final List<Track> _queue = [];
  int _currentIndex = -1;
  PlayMode _playMode = PlayMode.list;
  final List<int> _shuffleHistory = [];

  MusicPocketAudioHandler? _handler;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Track?>? _mediaItemSyncSub;
  StreamSubscription<Duration?>? _durationSub;
  bool _completingGuard = false;

  final StreamController<Track?> _currentTrackController =
      StreamController<Track?>.broadcast();
  final StreamController<PlayMode> _playModeController =
      StreamController<PlayMode>.broadcast();
  final StreamController<double> _volumeController =
      StreamController<double>.broadcast();

  double _volume = 1.0;
  Duration _duration = Duration.zero;


  AudioPlayer get player => _player;
  List<Track> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  PlayMode get playMode => _playMode;

  Track? get currentTrack {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return null;
    return _queue[_currentIndex];
  }

  Stream<Track?> get currentTrackStream => _currentTrackController.stream;
  Stream<PlayMode> get playModeStream => _playModeController.stream;

  static const int _shuffleHistorySize = 5;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<double> get volumeStream => _volumeController.stream;

  Duration get position => _player.position;
  Duration get duration => _duration;
  bool get playing => _player.playing;
  double get volume => _volume;

  Future<void> loadAndPlay(String filePath, {bool autoPlay = true}) async {
    try {
      await _player
          .setFilePath(filePath)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException('setFilePath timeout: $filePath'),
          );
      final dur = _player.duration;
      if (dur != null) _duration = dur;
      if (autoPlay) {
        await _player.play();
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AudioPlayerService] ERROR loading file: $filePath');
        debugPrint('[AudioPlayerService] $e');
        debugPrint('[AudioPlayerService] $st');
      }
    }
  }

  Future<void> play() async => _player.play();
  Future<void> pause() async => _player.pause();
  Future<void> stop() async => _player.stop();

  Future<void> seek(Duration position) async => _player.seek(position);

  Future<void> setVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    await _player.setVolume(clamped);
    _volume = clamped;
    _volumeController.add(clamped);
  }

  Future<void> togglePlay() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> stopAndClear() async {
    await _player.stop();
    _queue.clear();
    _currentIndex = -1;
    _shuffleHistory.clear();
    _currentTrackController.add(null);
  }

  void setQueue(List<Track> tracks, {int startIndex = 0}) {
    _queue.clear();
    _queue.addAll(tracks);
    _currentIndex = tracks.isEmpty
        ? -1
        : startIndex.clamp(0, tracks.length - 1);
    _shuffleHistory.clear();
    _currentTrackController.add(currentTrack);
  }

  Future<void> playTracks(List<Track> tracks, {int startIndex = 0}) async {
    setQueue(tracks, startIndex: startIndex);
    final t = currentTrack;
    if (t != null) {
      await loadAndPlay(t.filePath);
    }
  }

  void addToQueue(Track track) {
    _queue.add(track);
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (_currentIndex >= _queue.length) {
        _currentIndex = _queue.length - 1;
        _currentTrackController.add(currentTrack);
      }
    }
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;

    final nextIndex = _getNextIndex();
    if (nextIndex >= 0 && nextIndex < _queue.length) {
      _currentIndex = nextIndex;
      _currentTrackController.add(currentTrack);
      await loadAndPlay(_queue[_currentIndex].filePath);
    }
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;

    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }

    final prevIndex = _getPrevIndex();
    if (prevIndex >= 0 && prevIndex < _queue.length) {
      _currentIndex = prevIndex;
      _currentTrackController.add(currentTrack);
      await loadAndPlay(_queue[_currentIndex].filePath);
    }
  }

  void cyclePlayMode() {
    switch (_playMode) {
      case PlayMode.list:
        _playMode = PlayMode.one;
      case PlayMode.one:
        _playMode = PlayMode.shuffle;
      case PlayMode.shuffle:
        _playMode = PlayMode.list;
    }
    if (_playMode == PlayMode.shuffle) {
      _shuffleHistory.clear();
    }
    _playModeController.add(_playMode);
  }

  int _getNextIndex() {
    if (_queue.isEmpty) return -1;

    if (_playMode == PlayMode.shuffle) {
      return _smartShufflePick();
    }

    if (_currentIndex < 0) return 0;

    return (_currentIndex + 1) % _queue.length;
  }

  int _getPrevIndex() {
    if (_queue.isEmpty) return -1;
    if (_currentIndex < 0) return 0;

    return (_currentIndex - 1 + _queue.length) % _queue.length;
  }

  int _smartShufflePick() {
    if (_queue.isEmpty) return -1;

    if (_currentIndex >= 0) {
      _shuffleHistory.add(_currentIndex);
      if (_shuffleHistory.length > _shuffleHistorySize) {
        _shuffleHistory.removeAt(0);
      }
    }

    final historySet = _shuffleHistory.toSet();
    final candidates = <int>[];
    for (var i = 0; i < _queue.length; i++) {
      if (!historySet.contains(i)) {
        candidates.add(i);
      }
    }

    if (candidates.isEmpty) {
      return _queue.length > 1 ? (_currentIndex + 1) % _queue.length : 0;
    }

    candidates.shuffle();
    return candidates.first;
  }

  Future<void> dispose() async {
    await _playerStateSub?.cancel();
    await _mediaItemSyncSub?.cancel();
    await _durationSub?.cancel();
    await _player.dispose();
    await _currentTrackController.close();
    await _playModeController.close();
    await _volumeController.close();
  }

  void attachHandler(MusicPocketAudioHandler handler) {
    if (_handler != null) return;
    _handler = handler;

    _playerStateSub?.cancel();
    _playerStateSub = _player.playerStateStream.listen((state) {
      handler.emitState(
        playing: state.playing,
        proc: _mapProcessingState(state.processingState),
      );
      if (state.processingState == ProcessingState.completed) {
        if (!_completingGuard) {
          _completingGuard = true;
          _onPlaybackCompleted();
        }
      } else {
        _completingGuard = false;
      }
    });

    _mediaItemSyncSub?.cancel();
    _mediaItemSyncSub = currentTrackStream.listen((t) {
      if (t != null) handler.emitMediaItem(_toMediaItem(t));
    });
  }

  AudioProcessingState _mapProcessingState(ProcessingState s) {
    switch (s) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  MediaItem _toMediaItem(Track t) {
    return MediaItem(
      id: t.filePath,
      title: t.title.isEmpty ? '未知曲目' : t.title,
      artist: t.artist.isEmpty ? '未知艺术家' : t.artist,
      album: t.album,
      artUri: t.coverPath != null ? Uri.file(t.coverPath!) : null,
      duration: Duration(milliseconds: t.durationMs),
    );
  }

  Future<void> _onPlaybackCompleted() async {
    if (_playMode == PlayMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }
    await playNext();
  }
}
