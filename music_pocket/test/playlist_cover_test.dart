import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_pocket/data/database/app_database.dart';

void main() {
  group('Playlist cover from first track', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('watchAllWithTrackCount returns cover of first added track', () async {
      final trackId1 = await db.trackDao.insertTrack(
        TracksCompanion.insert(
          title: 'First Track',
          coverPath: const Value('/covers/first.jpg'),
          filePath: '/audio/first.mp3',
          addedAt: DateTime.now(),
        ),
      );
      final trackId2 = await db.trackDao.insertTrack(
        TracksCompanion.insert(
          title: 'Second Track',
          coverPath: const Value('/covers/second.jpg'),
          filePath: '/audio/second.mp3',
          addedAt: DateTime.now(),
        ),
      );

      final playlistId = await db.playlistDao.create('My Playlist');

      await db.playlistDao.addTrack(playlistId, trackId2);
      await db.playlistDao.addTrack(playlistId, trackId1);

      final playlists = await db.playlistDao.watchAllWithTrackCount().first;
      final playlist = playlists.firstWhere((p) => p.playlist.id == playlistId);

      expect(playlist.trackCount, 2);
      expect(playlist.coverPath, '/covers/second.jpg');
    });

    test('empty playlist has null cover', () async {
      final playlistId = await db.playlistDao.create('Empty Playlist');

      final playlists = await db.playlistDao.watchAllWithTrackCount().first;
      final playlist = playlists.firstWhere((p) => p.playlist.id == playlistId);

      expect(playlist.trackCount, 0);
      expect(playlist.coverPath, isA<Null>());
    });

    test('falls back to next track when first added track has no cover', () async {
      final trackWithCover = await db.trackDao.insertTrack(
        TracksCompanion.insert(
          title: 'With Cover',
          coverPath: const Value('/covers/has_cover.jpg'),
          filePath: '/audio/with_cover.mp3',
          addedAt: DateTime.now(),
        ),
      );
      final trackWithoutCover = await db.trackDao.insertTrack(
        TracksCompanion.insert(
          title: 'Without Cover',
          filePath: '/audio/without_cover.mp3',
          addedAt: DateTime.now(),
        ),
      );

      final playlistId = await db.playlistDao.create('Fallback Playlist');
      await db.playlistDao.addTrack(playlistId, trackWithoutCover);
      await db.playlistDao.addTrack(playlistId, trackWithCover);

      final playlists = await db.playlistDao.watchAllWithTrackCount().first;
      final playlist = playlists.firstWhere((p) => p.playlist.id == playlistId);

      expect(playlist.trackCount, 2);
      expect(playlist.coverPath, '/covers/has_cover.jpg');
    });
  });
}
