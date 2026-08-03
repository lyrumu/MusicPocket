import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../services/audio_player_service.dart';
import 'database_provider.dart';

final tracksProvider = StreamProvider<List<Track>>((ref) {
  return ref.watch(trackRepositoryProvider).watchAll();
});

final searchTracksProvider = FutureProvider.family<List<Track>, String>((
  ref,
  query,
) {
  return ref.watch(trackRepositoryProvider).search(query);
});

final currentTrackProvider = StreamProvider<Track?>((ref) {
  final controller = StreamController<Track?>();
  controller.add(AudioPlayerService.instance.currentTrack);
  final sub = AudioPlayerService.instance.currentTrackStream.listen(
    controller.add,
  );
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

final playModeProvider = StreamProvider<PlayMode>((ref) {
  final controller = StreamController<PlayMode>();
  controller.add(AudioPlayerService.instance.playMode);
  final sub = AudioPlayerService.instance.playModeStream.listen(controller.add);
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

final playQueueProvider = StreamProvider<PlayQueueSnapshot>((ref) {
  final controller = StreamController<PlayQueueSnapshot>();
  controller.add(AudioPlayerService.instance.queue);
  final sub = AudioPlayerService.instance.queueStream.listen(controller.add);
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});
