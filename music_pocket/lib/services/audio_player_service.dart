import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database/app_database.dart';
import '../data/repositories/playlist_repository.dart';
import '../data/repositories/track_repository.dart';
import 'audio_handler.dart';

enum PlayMode { list, one, shuffle }

class PlayQueueItem {
  final Track track;
  final bool manual;

  const PlayQueueItem(this.track, {required this.manual});
}

class PlayQueueSnapshot {
  final Track? current;
  final List<PlayQueueItem> upNext;

  const PlayQueueSnapshot({this.current, required this.upNext});

  bool get isEmpty => current == null && upNext.isEmpty;
}

enum _SourceKind { none, library, artist, playlist }

class _SourceDesc {
  final _SourceKind kind;
  final String? name;
  final int? playlistId;

  const _SourceDesc({this.kind = _SourceKind.none, this.name, this.playlistId});

  bool get isEmpty => kind == _SourceKind.none;
}

class _QEntry {
  final Track track;
  bool manual;
  final int sourceIndex;

  _QEntry(this.track, {required this.manual, this.sourceIndex = -1});

  int get id => track.id;
}

class _HistoryEntry {
  final int trackId;
  final int sourceIndex;

  _HistoryEntry(this.trackId, this.sourceIndex);
}

class AudioPlayerService {
  AudioPlayerService._() {
    unawaited(_player.setVolume(1.0));
    _durationSub = _player.durationStream.listen((d) {
      if (d != null) _duration = d;
    });
  }
  static final instance = AudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();

  Track? _current;
  int _lastSourceIndex = -1;
  List<Track> _source = [];
  _SourceDesc _sourceDesc = const _SourceDesc();
  final List<_QEntry> _upNext = [];
  final List<_HistoryEntry> _history = [];
  final Set<int> _shuffleRecent = {};
  PlayMode _playMode = PlayMode.list;

  TrackRepository? _trackRepo;
  PlaylistRepository? _playlistRepo;
  bool _restoring = false;
  Timer? _persistTimer;
  int _positionMs = 0;

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
  final StreamController<PlayQueueSnapshot> _queueController =
      StreamController<PlayQueueSnapshot>.broadcast();

  double _volume = 1.0;
  Duration _duration = Duration.zero;

  static const int _historyMax = 64;
  static const int _shuffleRecentMax = 12;

  AudioPlayer get player => _player;
  Track? get currentTrack => _current;
  PlayMode get playMode => _playMode;
  List<Track> get upNextTracks =>
      List.unmodifiable(_upNext.map((e) => e.track));

  PlayQueueSnapshot get queue => PlayQueueSnapshot(
    current: _current,
    upNext: _upNext
        .map((e) => PlayQueueItem(e.track, manual: e.manual))
        .toList(growable: false),
  );

  Stream<Track?> get currentTrackStream => _currentTrackController.stream;
  Stream<PlayMode> get playModeStream => _playModeController.stream;
  Stream<PlayQueueSnapshot> get queueStream => _queueController.stream;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<double> get volumeStream => _volumeController.stream;

  Duration get position => _player.position;
  Duration get duration => _duration;
  bool get playing => _player.playing;
  double get volume => _volume;

  Future<void> init(
    TrackRepository trackRepo,
    PlaylistRepository playlistRepo,
  ) async {
    _trackRepo = trackRepo;
    _playlistRepo = playlistRepo;
    await _restore();
  }

  Future<void> loadAndPlay(String filePath, {bool autoPlay = true}) async {
    try {
      _duration = Duration.zero;
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
  Future<void> pause() async {
    await _player.pause();
    _positionMs = _player.position.inMilliseconds;
    unawaited(persistNow());
  }

  Future<void> stop() async => _player.stop();

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      _positionMs = _player.position.inMilliseconds;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AudioPlayerService] ERROR seeking to $position');
        debugPrint('[AudioPlayerService] $e');
        debugPrint('[AudioPlayerService] $st');
      }
    }
  }

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

  Future<void> stopPlayback() async {
    await _player.stop();
    _current = null;
    _positionMs = 0;
    _emitCurrent();
    _emitQueue();
    unawaited(persistNow());
  }

  Future<void> removeCurrentAndContinue() async {
    _current = null;
    if (_upNext.isNotEmpty) {
      final entry = _upNext.removeAt(0);
      await _playEntry(entry, autoPlay: true);
    } else {
      await _player.stop();
      _positionMs = 0;
      _emitCurrent();
      _emitQueue();
      unawaited(persistNow());
    }
  }

  Future<void> prepareTrackDeletion(int trackId) async {
    if (_current?.id == trackId) {
      await _player.stop();
    }
  }

  Future<void> completeTrackDeletion(int trackId) async {
    final wasCurrent = _current?.id == trackId;
    final currentSourceIndex = _source.indexWhere(
      (track) => track.id == trackId,
    );

    _upNext.removeWhere((entry) => entry.id == trackId);
    _history.removeWhere((entry) => entry.trackId == trackId);
    _shuffleRecent.remove(trackId);

    if (currentSourceIndex >= 0) {
      _source.removeAt(currentSourceIndex);
      if (currentSourceIndex <= _lastSourceIndex) {
        _lastSourceIndex--;
      }
    }
    if (_source.isEmpty) {
      _lastSourceIndex = -1;
      _sourceDesc = const _SourceDesc();
    } else {
      _lastSourceIndex = _lastSourceIndex.clamp(-1, _source.length - 1);
    }

    if (!wasCurrent) {
      _emitQueue();
      _schedulePersist();
      return;
    }

    _current = null;
    _positionMs = 0;
    _emitCurrent();
    _emitQueue();
    await _advance(ignoreOneRepeat: true);
    _schedulePersist();
  }

  Future<void> playTracks(
    List<Track> tracks, {
    int startIndex = 0,
    bool toggleIfCurrent = true,
  }) async {
    if (tracks.isEmpty) return;
    final targetIndex = startIndex.clamp(0, tracks.length - 1);
    final targetTrack = tracks[targetIndex];
    if (toggleIfCurrent && _current?.id == targetTrack.id) {
      await togglePlay();
      return;
    }
    await _playFromContext(
      tracks,
      startIndex: targetIndex,
      source: _SourceDesc(kind: _SourceKind.library),
    );
  }

  Future<void> playFromArtist(
    String artistName,
    List<Track> tracks, {
    int startIndex = 0,
    bool toggleIfCurrent = true,
  }) async {
    if (tracks.isEmpty) return;
    final targetIndex = startIndex.clamp(0, tracks.length - 1);
    if (toggleIfCurrent && _current?.id == tracks[targetIndex].id) {
      await togglePlay();
      return;
    }
    await _playFromContext(
      tracks,
      startIndex: targetIndex,
      source: _SourceDesc(kind: _SourceKind.artist, name: artistName),
    );
  }

  Future<void> playFromPlaylist(
    int playlistId,
    List<Track> tracks, {
    int startIndex = 0,
    bool toggleIfCurrent = true,
  }) async {
    if (tracks.isEmpty) return;
    final targetIndex = startIndex.clamp(0, tracks.length - 1);
    if (toggleIfCurrent && _current?.id == tracks[targetIndex].id) {
      await togglePlay();
      return;
    }
    await _playFromContext(
      tracks,
      startIndex: targetIndex,
      source: _SourceDesc(kind: _SourceKind.playlist, playlistId: playlistId),
    );
  }

  Future<void> _playFromContext(
    List<Track> tracks, {
    required int startIndex,
    required _SourceDesc source,
  }) async {
    final oldLastSourceIndex = _lastSourceIndex;
    if (_current != null) {
      _history.add(_HistoryEntry(_current!.id, oldLastSourceIndex));
      if (_history.length > _historyMax) _history.removeAt(0);
    }
    _source = List.of(tracks);
    _sourceDesc = source;
    _lastSourceIndex = startIndex;
    if (_playMode == PlayMode.shuffle) {
      _shuffleRecent.clear();
    }
    _current = _source[startIndex];
    _shuffleRecent.add(_current!.id);
    _positionMs = 0;
    _emitCurrent();
    _emitQueue();
    _schedulePersist();
    await loadAndPlay(_current!.filePath, autoPlay: true);
  }

  void addToQueue(Track track) {
    if (_current == null) {
      _source = [];
      _sourceDesc = const _SourceDesc();
      _current = track;
      _lastSourceIndex = -1;
      _shuffleRecent.add(track.id);
      _emitCurrent();
      _emitQueue();
      _schedulePersist();
      unawaited(loadAndPlay(track.filePath, autoPlay: true));
      return;
    }
    _upNext.add(_QEntry(track, manual: true));
    _emitQueue();
    _schedulePersist();
  }

  void playNextTrack(Track track) {
    if (_current == null) {
      addToQueue(track);
      return;
    }
    _upNext.insert(0, _QEntry(track, manual: true));
    _emitQueue();
    _schedulePersist();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _upNext.length) return;
    _upNext.removeAt(index);
    _emitQueue();
    _schedulePersist();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (_upNext.length < 2) return;
    if (oldIndex < 0 || oldIndex >= _upNext.length) return;
    if (newIndex < 0) newIndex = 0;
    if (newIndex > _upNext.length) newIndex = _upNext.length;
    if (oldIndex == newIndex) return;
    final entry = _upNext.removeAt(oldIndex);
    _upNext.insert(newIndex, entry);
    _emitQueue();
    _schedulePersist();
  }

  Future<void> jumpToQueueItem(int index) async {
    if (index < 0 || index >= _upNext.length) return;
    final entry = _upNext.removeAt(index);
    await _playEntry(entry, autoPlay: true);
  }

  void clearQueue() {
    _upNext.clear();
    _emitQueue();
    _schedulePersist();
  }

  Future<void> playNext() async {
    await _advance(ignoreOneRepeat: true);
  }

  Future<void> playPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_history.isEmpty) {
      await _player.seek(Duration.zero);
      return;
    }
    final prev = _history.removeLast();
    final track = await _trackRepo?.getById(prev.trackId);
    if (track == null) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_current != null) {
      _upNext.insert(0, _QEntry(_current!, manual: true));
    }
    _current = track;
    if (prev.sourceIndex >= 0 && _playMode != PlayMode.shuffle) {
      _lastSourceIndex = prev.sourceIndex;
    }
    _positionMs = 0;
    _emitCurrent();
    _emitQueue();
    _schedulePersist();
    await loadAndPlay(track.filePath, autoPlay: true);
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
      _shuffleRecent.clear();
      if (_current != null) _shuffleRecent.add(_current!.id);
    }
    _schedulePersist();
    _playModeController.add(_playMode);
  }

  Future<void> _advance({bool ignoreOneRepeat = false}) async {
    if (_playMode == PlayMode.one && !ignoreOneRepeat) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }
    _QEntry? entry;
    if (_upNext.isNotEmpty) {
      entry = _upNext.removeAt(0);
    } else {
      entry = await _deriveNextFromSource();
    }
    if (entry == null) {
      await _player.stop();
      _positionMs = 0;
      _schedulePersist();
      return;
    }
    await _playEntry(entry, autoPlay: true);
  }

  Future<_QEntry?> _deriveNextFromSource() async {
    if (_source.isEmpty) return null;
    if (_source.length == 1) {
      final t = _source.first;
      return _QEntry(t, manual: false, sourceIndex: 0);
    }
    final currentInSource = _current == null ? -1 : _source.indexOf(_current!);
    final base = currentInSource >= 0 ? currentInSource : _lastSourceIndex;
    int idx;
    final currentId = _current?.id;
    if (_playMode == PlayMode.shuffle) {
      idx = _pickShuffleSourceIndex();
      if (idx < 0) idx = (base + 1) % _source.length;
      if (_source[idx].id == currentId) {
        idx = (idx + 1) % _source.length;
      }
    } else {
      idx = (base + 1) % _source.length;
      if (_source[idx].id == currentId) {
        idx = (idx + 1) % _source.length;
      }
    }
    return _QEntry(_source[idx], manual: false, sourceIndex: idx);
  }

  Future<void> _playEntry(_QEntry entry, {required bool autoPlay}) async {
    if (_current != null) {
      _history.add(_HistoryEntry(_current!.id, _lastSourceIndex));
      if (_history.length > _historyMax) _history.removeAt(0);
    }
    _current = entry.track;
    _shuffleRecent.add(entry.track.id);
    if (_shuffleRecent.length > _shuffleRecentMax) {
      _shuffleRecent.remove(_shuffleRecent.first);
    }
    if (!entry.manual) {
      _lastSourceIndex = entry.sourceIndex >= 0
          ? entry.sourceIndex
          : _source.indexOf(entry.track);
    }
    _positionMs = 0;
    _emitCurrent();
    _emitQueue();
    _schedulePersist();
    await loadAndPlay(entry.track.filePath, autoPlay: autoPlay);
  }

  int _pickShuffleSourceIndex() {
    final currentId = _current?.id;
    final candidates = <int>[];
    for (var i = 0; i < _source.length; i++) {
      final t = _source[i];
      if (t.id == currentId) {
        continue;
      }
      if (_shuffleRecent.length < _source.length &&
          _shuffleRecent.contains(t.id)) {
        continue;
      }
      candidates.add(i);
    }
    if (candidates.isEmpty) {
      for (var i = 0; i < _source.length; i++) {
        if (_source[i].id == currentId) {
          continue;
        }
        candidates.add(i);
      }
    }
    if (candidates.isEmpty) return -1;
    candidates.shuffle();
    return candidates.first;
  }

  void _emitCurrent() => _currentTrackController.add(_current);
  void _emitQueue() => _queueController.add(queue);

  Future<void> dispose() async {
    await _playerStateSub?.cancel();
    await _mediaItemSyncSub?.cancel();
    await _durationSub?.cancel();
    _persistTimer?.cancel();
    await _player.dispose();
    await _currentTrackController.close();
    await _playModeController.close();
    await _volumeController.close();
    await _queueController.close();
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
    await _advance(ignoreOneRepeat: true);
  }

  // ---- persistence ----

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 300), _persist);
  }

  Future<void> persistNow() async {
    _persistTimer?.cancel();
    await _persist();
  }

  Future<File> _stateFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'play_queue.json'));
  }

  Future<void> _persist() async {
    if (_trackRepo == null) return;
    try {
      final map = <String, dynamic>{
        'version': 1,
        'currentId': _current?.id,
        'lastSourceIndex': _lastSourceIndex,
        'source': {
          'kind': _sourceDesc.kind.name,
          if (_sourceDesc.name != null) 'name': _sourceDesc.name,
          if (_sourceDesc.playlistId != null)
            'playlistId': _sourceDesc.playlistId,
        },
        'manual': _upNext
            .where((e) => e.manual)
            .map((e) => e.id)
            .toList(growable: false),
        'playMode': _playMode.name,
        'history': _history
            .map((e) => {'id': e.trackId, 's': e.sourceIndex})
            .toList(growable: false),
        'shuffleRecent': _shuffleRecent.toList(growable: false),
        'positionMs': _player.position.inMilliseconds,
      };
      final file = await _stateFile();
      await file.writeAsString(jsonEncode(map), flush: true);
    } catch (e) {
      if (kDebugMode) debugPrint('[persist] $e');
    }
  }

  Future<void> _restore() async {
    if (_restoring) return;
    _restoring = true;
    try {
      final file = await _stateFile();
      if (!await file.exists()) {
        return;
      }
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      _playMode = PlayMode.values.firstWhere(
        (m) => m.name == (map['playMode'] as String? ?? 'list'),
        orElse: () => PlayMode.list,
      );

      final src = (map['source'] as Map?)?.cast<String, dynamic>();
      var sourceTracks = <Track>[];
      _sourceDesc = const _SourceDesc();
      if (src != null) {
        final kind = _SourceKind.values.firstWhere(
          (k) => k.name == (src['kind'] as String?),
          orElse: () => _SourceKind.none,
        );
        if (kind == _SourceKind.library) {
          sourceTracks = await _trackRepo!.getAll();
          _sourceDesc = _SourceDesc(kind: kind);
        } else if (kind == _SourceKind.artist) {
          final name = src['name'] as String;
          final all = await _trackRepo!.getAll();
          sourceTracks = all
              .where(
                (t) =>
                    (t.artist.trim().isEmpty ? '未知艺术家' : t.artist.trim()) ==
                    name,
              )
              .toList();
          _sourceDesc = _SourceDesc(kind: kind, name: name);
        } else if (kind == _SourceKind.playlist) {
          final pid = (src['playlistId'] as num).toInt();
          final ids = await _playlistRepo!.getTrackIds(pid);
          if (ids.isNotEmpty) {
            sourceTracks = await _trackRepo!.getByIds(ids);
          }
          _sourceDesc = _SourceDesc(kind: kind, playlistId: pid);
        }
      }
      _source = sourceTracks;
      _lastSourceIndex = (map['lastSourceIndex'] as num?)?.toInt() ?? -1;
      if (_source.isEmpty) {
        _lastSourceIndex = -1;
      } else if (_lastSourceIndex >= _source.length) {
        _lastSourceIndex = _source.length - 1;
      } else if (_lastSourceIndex < -1) {
        _lastSourceIndex = -1;
      }

      final currentId = map['currentId'] as int?;
      Track? cur;
      if (currentId != null) cur = await _trackRepo!.getById(currentId);
      if (cur == null) _lastSourceIndex = _source.isEmpty ? -1 : 0;

      _upNext.clear();
      final manualIds = ((map['manual'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toList();
      if (manualIds.isNotEmpty) {
        final tracks = await _trackRepo!.getByIds(manualIds);
        for (final t in tracks) {
          _upNext.add(_QEntry(t, manual: true));
        }
      }

      _history.clear();
      for (final e in (map['history'] as List?) ?? []) {
        final m = (e as Map).cast<String, dynamic>();
        _history.add(
          _HistoryEntry((m['id'] as num).toInt(), (m['s'] as num).toInt()),
        );
      }

      _shuffleRecent.clear();
      for (final e in (map['shuffleRecent'] as List?) ?? []) {
        _shuffleRecent.add((e as num).toInt());
      }

      _positionMs = (map['positionMs'] as num?)?.toInt() ?? 0;
      _current = cur;
      if (_current != null) _shuffleRecent.add(_current!.id);

      _emitCurrent();
      _emitQueue();
      _playModeController.add(_playMode);

      if (_current != null) {
        await loadAndPlay(_current!.filePath, autoPlay: false);
        if (_positionMs > 0) {
          await _player.seek(Duration(milliseconds: _positionMs));
        }
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[restore] $e\n$st');
    } finally {
      _restoring = false;
    }
  }
}
