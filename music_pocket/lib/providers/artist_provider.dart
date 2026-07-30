import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import 'track_provider.dart';

class Artist {
  final String name;
  final List<Track> tracks;
  final String? coverPath;

  Artist({required this.name, required this.tracks, this.coverPath});
}

final artistsProvider = Provider<List<Artist>>((ref) {
  final tracks = ref.watch(tracksProvider).asData?.value ?? [];
  final map = <String, List<Track>>{};

  for (final track in tracks) {
    final name = track.artist.trim().isEmpty ? '未知艺术家' : track.artist.trim();
    map.putIfAbsent(name, () => []).add(track);
  }

  final artists = map.entries.map((entry) {
    final sortedTracks = [...entry.value]..sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    return Artist(
      name: entry.key,
      tracks: sortedTracks,
      coverPath: sortedTracks.first.coverPath,
    );
  }).toList();

  artists.sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );
  return artists;
});

final artistProvider = Provider.family<Artist?, String>((ref, name) {
  final artists = ref.watch(artistsProvider);
  return artists.firstWhere((a) => a.name == name);
});
