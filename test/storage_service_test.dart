import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:music_pocket/services/storage_service.dart';

void main() {
  test('reports and safely clears unreferenced managed files', () async {
    final directory = await Directory.systemTemp.createTemp(
      'music_pocket_storage_',
    );
    final external = await Directory.systemTemp.createTemp(
      'music_pocket_storage_external_',
    );
    addTearDown(() => directory.delete(recursive: true));
    addTearDown(() => external.delete(recursive: true));

    final song = await _writeBytes('${directory.path}/audio/song.mp3', 1500);
    final oldSong = await _writeBytes('${directory.path}/audio/old.mp3', 700);
    final cover = await _writeBytes('${directory.path}/covers/cover.jpg', 500);
    final oldCover = await _writeBytes('${directory.path}/covers/old.jpg', 300);
    final externalFile = await _writeBytes(
      '${external.path}/original.mp3',
      900,
    );
    await _writeBytes('${directory.path}/music_pocket/music_pocket.db', 100);
    await _writeBytes('${directory.path}/music_pocket/music_pocket.db-wal', 20);

    final service = StorageService.forTesting(() async => directory);
    final usage = await service.getUsage(
      referencedAudioPaths: [song.path],
      referencedCoverPaths: [cover.path],
    );

    expect(usage.audioBytes, 2200);
    expect(usage.coverBytes, 800);
    expect(usage.databaseBytes, 120);
    expect(usage.totalBytes, 3120);
    expect(usage.orphanedBytes, 1000);
    expect(usage.orphanedFileCount, 2);

    final result = await service.clearOrphanedFiles(
      candidatePaths: [...usage.orphanedPaths, externalFile.path],
      referencedAudioPaths: [song.path],
      referencedCoverPaths: [cover.path],
    );

    expect(result.deletedFileCount, 2);
    expect(result.freedBytes, 1000);
    expect(result.failedFileCount, 0);
    expect(await song.exists(), isTrue);
    expect(await cover.exists(), isTrue);
    expect(await oldSong.exists(), isFalse);
    expect(await oldCover.exists(), isFalse);
    expect(await externalFile.exists(), isTrue);
  });
}

Future<File> _writeBytes(String path, int length) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(List.filled(length, 0));
  return file;
}
