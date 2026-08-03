import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_pocket/data/database/app_database.dart';
import 'package:music_pocket/data/repositories/track_repository.dart';
import 'package:music_pocket/services/metadata_service.dart';

void main() {
  group('TrackRepository managed file cleanup', () {
    late AppDatabase db;
    late Directory appDir;
    late Directory externalDir;
    late TrackRepository repository;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      appDir = await Directory.systemTemp.createTemp('music_pocket_files_');
      externalDir = await Directory.systemTemp.createTemp(
        'music_pocket_external_',
      );
      repository = TrackRepository(
        db.trackDao,
        MetadataService.instance,
        getDocumentsDirectory: () async => appDir,
      );
    });

    tearDown(() async {
      await db.close();
      if (await appDir.exists()) await appDir.delete(recursive: true);
      if (await externalDir.exists()) {
        await externalDir.delete(recursive: true);
      }
    });

    test('deletes managed audio and unreferenced covers', () async {
      final audio = await _writeFile(appDir, 'audio/song.mp3', [1, 2, 3]);
      final original = await _writeFile(appDir, 'covers/original.jpg', [4]);
      final custom = await _writeFile(appDir, 'covers/custom.jpg', [5]);
      final id = await _insertTrack(
        db,
        audio,
        coverPath: custom.path,
        originalCoverPath: original.path,
        customCoverPath: custom.path,
      );

      await repository.deleteTrack(id);

      expect(await db.trackDao.getById(id), isNull);
      expect(await audio.exists(), isFalse);
      expect(await original.exists(), isFalse);
      expect(await custom.exists(), isFalse);
    });

    test('keeps a cover referenced by another track', () async {
      final sharedCover = await _writeFile(appDir, 'covers/shared.jpg', [6]);
      final firstAudio = await _writeFile(appDir, 'audio/first.mp3', [7]);
      final secondAudio = await _writeFile(appDir, 'audio/second.mp3', [8]);
      final firstId = await _insertTrack(
        db,
        firstAudio,
        coverPath: sharedCover.path,
        originalCoverPath: sharedCover.path,
      );
      await _insertTrack(
        db,
        secondAudio,
        coverPath: sharedCover.path,
        originalCoverPath: sharedCover.path,
      );

      await repository.deleteTrack(firstId);

      expect(await db.trackDao.getById(firstId), isNull);
      expect(await firstAudio.exists(), isFalse);
      expect(await sharedCover.exists(), isTrue);
    });

    test('never deletes files outside managed directories', () async {
      final externalAudio = await _writeFile(externalDir, 'original/song.mp3', [
        9,
      ]);
      final externalCover = await _writeFile(
        externalDir,
        'original/cover.jpg',
        [10],
      );
      final id = await _insertTrack(
        db,
        externalAudio,
        coverPath: externalCover.path,
        originalCoverPath: externalCover.path,
      );

      await repository.deleteTrack(id);

      expect(await db.trackDao.getById(id), isNull);
      expect(await externalAudio.exists(), isTrue);
      expect(await externalCover.exists(), isTrue);
    });

    test(
      'keeps the database record when managed audio deletion fails',
      () async {
        final audio = await _writeFile(appDir, 'audio/locked.mp3', [11]);
        final id = await _insertTrack(db, audio);
        repository = TrackRepository(
          db.trackDao,
          MetadataService.instance,
          getDocumentsDirectory: () async => appDir,
          deleteFile: (_) async => throw const FileSystemException('locked'),
        );

        await expectLater(
          repository.deleteTrack(id),
          throwsA(isA<TrackDeletionException>()),
        );

        expect(await db.trackDao.getById(id), isNotNull);
        expect(await audio.exists(), isTrue);
      },
    );

    test('missing managed files do not block database deletion', () async {
      final missingAudio = File('${appDir.path}/audio/missing.mp3');
      final id = await _insertTrack(db, missingAudio);

      await repository.deleteTrack(id);

      expect(await db.trackDao.getById(id), isNull);
    });

    test('clearing a custom cover restores the original cover', () async {
      final audio = await _writeFile(appDir, 'audio/covered.mp3', [12]);
      final original = await _writeFile(appDir, 'covers/original.png', [13]);
      final custom = await _writeFile(appDir, 'covers/custom.png', [14]);
      final id = await _insertTrack(
        db,
        audio,
        coverPath: custom.path,
        originalCoverPath: original.path,
        customCoverPath: custom.path,
      );

      final result = await repository.clearCustomCover(id);
      final track = await db.trackDao.getById(id);

      expect(result.coverPath, original.path);
      expect(result.warning, isNull);
      expect(track!.coverPath, original.path);
      expect(track.originalCoverPath, original.path);
      expect(track.customCoverPath, isNull);
      expect(await original.exists(), isTrue);
      expect(await custom.exists(), isFalse);
    });

    test('replaces a custom cover and removes the old custom file', () async {
      final audio = await _writeFile(appDir, 'audio/replace.mp3', [15]);
      final original = await _writeFile(appDir, 'covers/original.jpg', [16]);
      final oldCustom = await _writeFile(appDir, 'covers/old.jpg', [17]);
      final newSource = await _writeFile(externalDir, 'new.jpg', [18]);
      final id = await _insertTrack(
        db,
        audio,
        coverPath: oldCustom.path,
        originalCoverPath: original.path,
        customCoverPath: oldCustom.path,
      );

      final result = await repository.setCustomCoverFromFile(
        id,
        newSource.path,
      );
      final track = await db.trackDao.getById(id);

      expect(result.warning, isNull);
      expect(track!.coverPath, result.coverPath);
      expect(track.customCoverPath, result.coverPath);
      expect(track.originalCoverPath, original.path);
      expect(await File(result.coverPath!).exists(), isTrue);
      expect(await oldCustom.exists(), isFalse);
      expect(await original.exists(), isTrue);
    });

    test('legacy cover state is recalculated from embedded artwork', () async {
      final audio = await _writeFile(appDir, 'audio/legacy.mp3', [19]);
      final legacyCover = await _writeFile(appDir, 'covers/legacy.jpg', [20]);
      final id = await _insertTrack(
        db,
        audio,
        coverPath: legacyCover.path,
        customCoverPath: legacyCover.path,
      );
      repository = TrackRepository(
        db.trackDao,
        MetadataService.instance,
        getDocumentsDirectory: () async => appDir,
        extractMetadata: (filePath) => TrackMetadata(
          title: 'Legacy',
          filePath: filePath,
          coverBytes: Uint8List.fromList([21, 22, 23]),
          coverMimeType: 'image/png',
        ),
      );

      final result = await repository.clearCustomCover(id);
      final track = await db.trackDao.getById(id);

      expect(result.coverPath, isNotNull);
      expect(track!.coverPath, result.coverPath);
      expect(track.originalCoverPath, result.coverPath);
      expect(track.customCoverPath, isNull);
      expect(await File(result.coverPath!).readAsBytes(), [21, 22, 23]);
      expect(await legacyCover.exists(), isFalse);
    });
  });
}

Future<int> _insertTrack(
  AppDatabase db,
  File audio, {
  String? coverPath,
  String? originalCoverPath,
  String? customCoverPath,
}) {
  return db.trackDao.insertTrack(
    TracksCompanion.insert(
      title: 'Track',
      filePath: audio.path,
      coverPath: Value(coverPath),
      originalCoverPath: Value(originalCoverPath),
      customCoverPath: Value(customCoverPath),
      addedAt: DateTime.now(),
    ),
  );
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
