import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_pocket/data/database/app_database.dart';
import 'package:music_pocket/data/repositories/track_repository.dart';
import 'package:music_pocket/services/metadata_service.dart';

void main() {
  group('TrackRepository.importPath', () {
    late AppDatabase db;
    late Directory tempDir;
    late TrackRepository repository;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      tempDir = await Directory.systemTemp.createTemp('music_pocket_import_');
      repository = TrackRepository(
        db.trackDao,
        MetadataService.instance,
        getDocumentsDirectory: () async => tempDir,
      );
    });

    tearDown(() async {
      await db.close();
      await tempDir.delete(recursive: true);
    });

    test('skips the same file imported twice from the same path', () async {
      final source = await _writeFile(tempDir, 'source/song.mp3', [1, 2, 3, 4]);

      final first = await repository.importPath(source.path);
      final second = await repository.importPath(source.path);

      expect(first.skipped, isFalse);
      expect(second.skipped, isTrue);
      expect(second.track.id, first.track.id);
      expect((await db.trackDao.getAll()), hasLength(1));
    });

    test('skips identical content imported from a different path', () async {
      final firstSource = await _writeFile(tempDir, 'source-a/song.mp3', [
        5,
        6,
        7,
        8,
      ]);
      final secondSource = await _writeFile(tempDir, 'source-b/copy.mp3', [
        5,
        6,
        7,
        8,
      ]);

      final first = await repository.importPath(firstSource.path);
      final second = await repository.importPath(secondSource.path);

      expect(first.skipped, isFalse);
      expect(second.skipped, isTrue);
      expect(second.track.id, first.track.id);
      expect((await db.trackDao.getAll()), hasLength(1));
    });

    test('imports files with the same name and different content', () async {
      final firstSource = await _writeFile(tempDir, 'source-a/song.mp3', [
        9,
        10,
        11,
      ]);
      final secondSource = await _writeFile(tempDir, 'source-b/song.mp3', [
        12,
        13,
        14,
      ]);

      final first = await repository.importPath(firstSource.path);
      final second = await repository.importPath(secondSource.path);
      final tracks = await db.trackDao.getAll();

      expect(first.skipped, isFalse);
      expect(second.skipped, isFalse);
      expect(tracks, hasLength(2));
      expect(tracks.map((track) => track.contentHash).toSet(), hasLength(2));
    });

    test('uses embedded artwork as the original cover after import', () async {
      final source = await _writeFile(tempDir, 'source/covered.mp3', [31, 32]);
      repository = TrackRepository(
        db.trackDao,
        MetadataService.instance,
        getDocumentsDirectory: () async => tempDir,
        extractMetadata: (filePath) => TrackMetadata(
          title: 'Covered track',
          filePath: filePath,
          fileSize: 2,
          coverBytes: Uint8List.fromList([41, 42, 43]),
          coverMimeType: 'image/png',
        ),
      );

      final result = await repository.importPath(source.path);

      expect(result.track.coverPath, isNotNull);
      expect(result.track.originalCoverPath, result.track.coverPath);
      expect(result.track.customCoverPath, isNull);
      expect(await File(result.track.coverPath!).readAsBytes(), [41, 42, 43]);
    });

    test('backfills an old track hash before detecting a duplicate', () async {
      final storedFile = await _writeFile(tempDir, 'audio/legacy.mp3', [
        15,
        16,
        17,
      ]);
      final legacyId = await db.trackDao.insertTrack(
        TracksCompanion.insert(
          title: 'Legacy track',
          filePath: storedFile.path,
          addedAt: DateTime.now(),
        ),
      );
      final secondStoredFile = await _writeFile(
        tempDir,
        'audio/legacy-copy.mp3',
        [15, 16, 17],
      );
      await db.trackDao.insertTrack(
        TracksCompanion.insert(
          title: 'Legacy duplicate',
          filePath: secondStoredFile.path,
          addedAt: DateTime.now(),
        ),
      );
      final source = await _writeFile(tempDir, 'source/duplicate.mp3', [
        15,
        16,
        17,
      ]);

      final result = await repository.importPath(source.path);
      final legacyTrack = await db.trackDao.getById(legacyId);

      expect(result.skipped, isTrue);
      expect(result.track.id, legacyId);
      expect(legacyTrack!.contentHash, isNotNull);
      final tracks = await db.trackDao.getAll();
      expect(tracks, hasLength(2));
      expect(tracks.map((track) => track.contentHash).toSet(), hasLength(1));
    });
  });

  test('upgrades a v2 database without losing existing tracks', () async {
    final tempDir = await Directory.systemTemp.createTemp('music_pocket_v2_');
    final databaseFile = File('${tempDir.path}/music_pocket.db');
    final legacyDb = AppDatabase.forTesting(NativeDatabase(databaseFile));

    await legacyDb.customStatement('PRAGMA foreign_keys = OFF');
    await legacyDb.customStatement('DROP TABLE tracks');
    await legacyDb.customStatement('''
      CREATE TABLE tracks (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT NOT NULL DEFAULT '',
        album TEXT NOT NULL DEFAULT '',
        album_artist TEXT NOT NULL DEFAULT '',
        genre TEXT NOT NULL DEFAULT '',
        year INTEGER NULL,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        cover_path TEXT NULL,
        file_path TEXT NOT NULL UNIQUE,
        file_type TEXT NULL,
        bitrate INTEGER NULL,
        sample_rate INTEGER NULL,
        file_size INTEGER NULL,
        added_at INTEGER NOT NULL,
        modified_at INTEGER NULL,
        play_count INTEGER NOT NULL DEFAULT 0,
        last_played_at INTEGER NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        notes TEXT NULL,
        is_user_edited INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await legacyDb.customStatement(
      'INSERT INTO tracks (title, file_path, added_at) VALUES (?, ?, ?)',
      [
        'Legacy track',
        '/audio/legacy.mp3',
        DateTime(2025, 1, 1).millisecondsSinceEpoch,
      ],
    );
    await legacyDb.customStatement('PRAGMA user_version = 2');
    await legacyDb.close();

    final upgradedDb = AppDatabase.forTesting(NativeDatabase(databaseFile));
    addTearDown(() async {
      await upgradedDb.close();
      await tempDir.delete(recursive: true);
    });

    final track = await upgradedDb.trackDao.getById(1);

    expect(track, isNotNull);
    expect(track!.title, 'Legacy track');
    expect(track.filePath, '/audio/legacy.mp3');
    expect(track.contentHash, isNull);
    expect(track.originalCoverPath, isNull);
    expect(track.customCoverPath, isNull);
  });

  test('upgrades a v3 cover as legacy custom state', () async {
    final tempDir = await Directory.systemTemp.createTemp('music_pocket_v3_');
    final databaseFile = File('${tempDir.path}/music_pocket.db');
    final legacyDb = AppDatabase.forTesting(NativeDatabase(databaseFile));

    await legacyDb.customStatement('PRAGMA foreign_keys = OFF');
    await legacyDb.customStatement('DROP TABLE tracks');
    await legacyDb.customStatement('''
      CREATE TABLE tracks (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT NOT NULL DEFAULT '',
        album TEXT NOT NULL DEFAULT '',
        album_artist TEXT NOT NULL DEFAULT '',
        genre TEXT NOT NULL DEFAULT '',
        year INTEGER NULL,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        cover_path TEXT NULL,
        file_path TEXT NOT NULL UNIQUE,
        content_hash TEXT NULL,
        file_type TEXT NULL,
        bitrate INTEGER NULL,
        sample_rate INTEGER NULL,
        file_size INTEGER NULL,
        added_at INTEGER NOT NULL,
        modified_at INTEGER NULL,
        play_count INTEGER NOT NULL DEFAULT 0,
        last_played_at INTEGER NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        notes TEXT NULL,
        is_user_edited INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await legacyDb.customStatement(
      'INSERT INTO tracks (title, cover_path, file_path, added_at) '
      'VALUES (?, ?, ?, ?)',
      [
        'Legacy cover',
        '/covers/legacy.jpg',
        '/audio/legacy.mp3',
        DateTime(2025, 1, 1).millisecondsSinceEpoch,
      ],
    );
    await legacyDb.customStatement('PRAGMA user_version = 3');
    await legacyDb.close();

    final upgradedDb = AppDatabase.forTesting(NativeDatabase(databaseFile));
    addTearDown(() async {
      await upgradedDb.close();
      await tempDir.delete(recursive: true);
    });

    final track = await upgradedDb.trackDao.getById(1);

    expect(track, isNotNull);
    expect(track!.coverPath, '/covers/legacy.jpg');
    expect(track.originalCoverPath, isNull);
    expect(track.customCoverPath, '/covers/legacy.jpg');
  });
}

Future<File> _writeFile(
  Directory root,
  String relativePath,
  List<int> bytes,
) async {
  final file = File('${root.path}/$relativePath');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  return file;
}
