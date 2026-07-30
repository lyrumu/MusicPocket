import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/daos/playlist_dao.dart';
import 'database_provider.dart';

final playlistsProvider = StreamProvider<List<PlaylistWithTrackCount>>((ref) {
  return ref.watch(playlistRepositoryProvider).watchAllWithTrackCount();
});

final playlistTracksProvider = StreamProvider.family<List<Track>, int>((ref, playlistId) {
  return ref.watch(playlistRepositoryProvider).watchPlaylistTracks(playlistId);
});
