import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/daos/playlist_dao.dart';
import 'artist_provider.dart';
import 'database_provider.dart';
import 'playlist_provider.dart';

class SearchResults {
  final List<Track> tracks;
  final List<Artist> artists;
  final List<PlaylistWithTrackCount> playlists;

  const SearchResults({
    this.tracks = const [],
    this.artists = const [],
    this.playlists = const [],
  });

  bool get isEmpty => tracks.isEmpty && artists.isEmpty && playlists.isEmpty;
}

final searchResultsProvider =
    FutureProvider.family<SearchResults, String>((ref, query) async {
  final q = query.trim();
  if (q.isEmpty) return const SearchResults();

  final tracks = await ref.watch(trackRepositoryProvider).search(q);

  final lower = q.toLowerCase();
  final artists = ref
      .watch(artistsProvider)
      .where((a) => a.name.toLowerCase().contains(lower))
      .toList();

  final playlists = (ref.watch(playlistsProvider).asData?.value ?? [])
      .where((p) => p.playlist.name.toLowerCase().contains(lower))
      .toList();

  return SearchResults(tracks: tracks, artists: artists, playlists: playlists);
});