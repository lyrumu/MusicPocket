import 'package:drift/drift.dart';

import '../database/app_database.dart';

part 'playlist_dao.g.dart';

class PlaylistWithTrackCount {
  final Playlist playlist;
  final int trackCount;
  final String? coverPath;

  PlaylistWithTrackCount(this.playlist, this.trackCount, {this.coverPath});
}

@DriftAccessor(tables: [Playlists, PlaylistTracks, Tracks])
class PlaylistDao extends DatabaseAccessor<AppDatabase> with _$PlaylistDaoMixin {
  PlaylistDao(super.db);

  $PlaylistsTable get _playlists => attachedDatabase.playlists;
  $PlaylistTracksTable get _playlistTracks => attachedDatabase.playlistTracks;
  $TracksTable get _tracks => attachedDatabase.tracks;

  Stream<List<PlaylistWithTrackCount>> watchAllWithTrackCount() {
    final query = customSelect(
      'SELECT p.*, COUNT(pt.id) AS track_count, '
      '(SELECT t.cover_path FROM playlist_tracks pt2 '
      'JOIN tracks t ON pt2.track_id = t.id '
      'WHERE pt2.playlist_id = p.id '
      'AND t.cover_path IS NOT NULL AND t.cover_path != \'\' '
      'ORDER BY pt2.position ASC LIMIT 1) AS first_cover_path '
      'FROM playlists p LEFT JOIN playlist_tracks pt ON p.id = pt.playlist_id '
      'GROUP BY p.id ORDER BY p.name COLLATE NOCASE',
      readsFrom: {_playlists, _playlistTracks, _tracks},
    );
    return query.watch().map(
      (rows) {
        final result = rows.map((row) {
          final playlist = Playlist(
            id: row.read<int>('id'),
            name: row.read<String>('name'),
            description: row.read<String>('description'),
            coverPath: row.read<String?>('cover_path'),
            createdAt: row.read<DateTime>('created_at'),
            updatedAt: row.read<DateTime>('updated_at'),
            sortOrder: row.read<int>('sort_order'),
          );
          final count = row.read<int>('track_count');
          final coverPath = row.read<String?>('first_cover_path');
          return PlaylistWithTrackCount(playlist, count, coverPath: coverPath);
        }).toList();
        return result;
      },
    );
  }

  Future<Playlist?> getById(int id) {
    return (select(_playlists)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> create(String name) {
    final now = DateTime.now();
    return into(_playlists).insert(
      PlaylistsCompanion.insert(name: name, createdAt: now, updatedAt: now),
    );
  }

  Future<int> rename(int id, String name) {
    return (update(_playlists)..where((p) => p.id.equals(id))).write(
      PlaylistsCompanion(
        name: Value(name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updatePlaylist(PlaylistsCompanion companion) {
    return update(_playlists).write(companion);
  }

  Future<int> deletePlaylist(int id) async {
    await (delete(_playlistTracks)..where((pt) => pt.playlistId.equals(id))).go();
    return (delete(_playlists)..where((p) => p.id.equals(id))).go();
  }

  Future<int?> addTrack(int playlistId, int trackId) async {
    final existing = await (select(_playlistTracks)
          ..where(
            (pt) =>
                pt.playlistId.equals(playlistId) & pt.trackId.equals(trackId),
          ))
        .getSingleOrNull();
    if (existing != null) return null;

    final maxPosition = await _maxPosition(playlistId);
    return into(_playlistTracks).insert(
      PlaylistTracksCompanion.insert(
        playlistId: playlistId,
        trackId: trackId,
        position: maxPosition + 1,
        addedAt: DateTime.now(),
      ),
    );
  }

  Future<int> removeTrack(int playlistId, int trackId) {
    return (delete(_playlistTracks)
          ..where(
            (pt) =>
                pt.playlistId.equals(playlistId) & pt.trackId.equals(trackId),
          ))
        .go();
  }

  Future<int> _maxPosition(int playlistId) async {
    final result = await (selectOnly(_playlistTracks)
          ..addColumns([_playlistTracks.position.max()])
          ..where(_playlistTracks.playlistId.equals(playlistId)))
        .getSingle();
    return result.read(_playlistTracks.position.max()) ?? 0;
  }

  Stream<List<Track>> watchPlaylistTracks(int playlistId) {
    final query = select(_tracks).join([
      innerJoin(
        _playlistTracks,
        _playlistTracks.trackId.equalsExp(_tracks.id),
      ),
    ])
      ..where(_playlistTracks.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(_playlistTracks.position)]);

    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(_tracks)).toList(),
    );
  }

  Future<List<int>> getTrackIds(int playlistId) async {
    final rows = await (selectOnly(_playlistTracks)
          ..addColumns([_playlistTracks.trackId])
          ..where(_playlistTracks.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(_playlistTracks.position)]))
        .get();
    return rows.map((r) => r.read(_playlistTracks.trackId)!).toList();
  }
}
