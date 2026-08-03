import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../daos/playlist_dao.dart';
import '../daos/track_dao.dart';

part 'app_database.g.dart';

class Tracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get artist => text().withDefault(const Constant(''))();
  TextColumn get album => text().withDefault(const Constant(''))();
  TextColumn get albumArtist => text().withDefault(const Constant(''))();
  TextColumn get genre => text().withDefault(const Constant(''))();
  IntColumn get year => integer().nullable()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get coverPath => text().nullable()();
  TextColumn get originalCoverPath => text().nullable()();
  TextColumn get customCoverPath => text().nullable()();
  TextColumn get filePath => text().unique()();
  TextColumn get contentHash => text().nullable()();
  TextColumn get fileType => text().nullable()();
  IntColumn get bitrate => integer().nullable()();
  IntColumn get sampleRate => integer().nullable()();
  IntColumn get fileSize => integer().nullable()();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isUserEdited => boolean().withDefault(const Constant(false))();
}

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get coverPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class PlaylistTracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId => integer().references(Playlists, #id)();
  IntColumn get trackId => integer().references(Tracks, #id)();
  IntColumn get position => integer()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {playlistId, trackId},
  ];
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get color => text().withDefault(const Constant('#808080'))();
}

class TrackCategories extends Table {
  IntColumn get trackId => integer().references(Tracks, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {trackId, categoryId},
  ];
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Tracks,
    Playlists,
    PlaylistTracks,
    Categories,
    TrackCategories,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @visibleForTesting
  AppDatabase.forTesting(super.e);

  late final TrackDao trackDao = TrackDao(this);
  late final PlaylistDao playlistDao = PlaylistDao(this);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tracks, tracks.isUserEdited);
      }
      if (from < 3) {
        await m.addColumn(tracks, tracks.contentHash);
      }
      if (from < 4) {
        await m.addColumn(tracks, tracks.originalCoverPath);
        await m.addColumn(tracks, tracks.customCoverPath);
        await customStatement(
          'UPDATE tracks SET custom_cover_path = cover_path '
          'WHERE cover_path IS NOT NULL AND cover_path != \'\'',
        );
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'music_pocket', 'music_pocket.db'));
    return NativeDatabase.createInBackground(file);
  });
}
