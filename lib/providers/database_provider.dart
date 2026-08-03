import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/repositories/playlist_repository.dart';
import '../data/repositories/track_repository.dart';
import '../services/metadata_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final metadataServiceProvider = Provider<MetadataService>((ref) {
  return MetadataService.instance;
});

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return TrackRepository(
    ref.watch(appDatabaseProvider).trackDao,
    ref.watch(metadataServiceProvider),
  );
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepository(ref.watch(appDatabaseProvider).playlistDao);
});
