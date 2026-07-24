import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../database/app_database.dart';

part 'track_dao.g.dart';

@DriftAccessor(tables: [Tracks])
class TrackDao extends DatabaseAccessor<AppDatabase> with _$TrackDaoMixin {
  TrackDao(super.db);

  $TracksTable get _tbl => attachedDatabase.tracks;

  Stream<List<Track>> watchAll() {
    return (select(
      _tbl,
    )..orderBy([(t) => OrderingTerm(expression: t.title)])).watch();
  }

  Stream<Track?> watchById(int id) {
    return (select(_tbl)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Stream<List<Track>> watchByFolder(String folderPath) {
    final prefix = '$folderPath${p.separator}';
    final escaped = prefix.replaceAll('%', '\\%').replaceAll('_', '\\_');
    return (select(_tbl)
          ..where((t) => t.filePath.like('$escaped%'))
          ..orderBy([(t) => OrderingTerm(expression: t.title)]))
        .watch();
  }

  Future<List<Track>> search(String query) {
    final escaped = '%${query.replaceAll('%', '\\%').replaceAll('_', '\\_')}%';
    return (select(_tbl)
          ..where(
            (t) =>
                t.title.like(escaped) |
                t.artist.like(escaped) |
                t.album.like(escaped),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.title)]))
        .get();
  }

  Future<Track?> getById(int id) {
    return (select(_tbl)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Track?> getByFilePath(String filePath) {
    return (select(
      _tbl,
    )..where((t) => t.filePath.equals(filePath))).getSingleOrNull();
  }

  Future<List<String>> getAllFilePaths() async {
    final rows = await (selectOnly(_tbl)..addColumns([_tbl.filePath])).get();
    return rows.map((r) => r.read(_tbl.filePath)!).toList();
  }

  Future<int> insertTrack(TracksCompanion entry) {
    return into(_tbl).insert(entry);
  }

  Future<bool> updateTrack(Track track) {
    return update(_tbl).replace(track);
  }

  Future<int> deleteTrack(int id) {
    return (delete(_tbl)..where((t) => t.id.equals(id))).go();
  }

  Future<int> toggleFavorite(int id, bool favorite) {
    return (update(_tbl)..where((t) => t.id.equals(id))).write(
      TracksCompanion(isFavorite: Value(favorite)),
    );
  }

  Future<int> markPlayed(int id) {
    return customUpdate(
      'UPDATE tracks SET play_count = play_count + 1, last_played_at = ? WHERE id = ?',
      variables: [Variable.withDateTime(DateTime.now()), Variable.withInt(id)],
      updates: {_tbl},
    );
  }

  Future<int> setCoverPath(int id, String? coverPath) {
    return (update(_tbl)..where((t) => t.id.equals(id))).write(
      TracksCompanion(coverPath: Value(coverPath)),
    );
  }

  Future<int> patchTrackFields(int id, TracksCompanion patch) {
    return (update(_tbl)..where((t) => t.id.equals(id))).write(patch);
  }

  Future<int> setUserEdited(int id, TracksCompanion patch) {
    final merged = patch.copyWith(isUserEdited: const Value(true));
    return (update(_tbl)..where((t) => t.id.equals(id))).write(merged);
  }
}
