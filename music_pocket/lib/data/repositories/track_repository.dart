import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../daos/track_dao.dart';
import '../../services/metadata_service.dart';

class TrackRepository {
  TrackRepository(this._dao, this._metadataService);

  final TrackDao _dao;
  final MetadataService _metadataService;

  static const _audioDirName = 'audio';
  static const _coverDirName = 'covers';

  Stream<List<Track>> watchAll() => _dao.watchAll();

  Stream<Track?> watchById(int id) => _dao.watchById(id);

  Stream<List<Track>> watchByFolder(String folderPath) =>
      _dao.watchByFolder(folderPath);

  Future<List<Track>> search(String query) => _dao.search(query);

  Future<Track?> getById(int id) => _dao.getById(id);

  Future<List<Track>> getAll() => _dao.getAll();

  Future<List<Track>> getByIds(List<int> ids) => _dao.getByIds(ids);

  Future<Track?> getByFilePath(String filePath) => _dao.getByFilePath(filePath);

  Future<List<String>> getAllFilePaths() => _dao.getAllFilePaths();

  Future<int> toggleFavorite(int id, bool favorite) =>
      _dao.toggleFavorite(id, favorite);

  Future<int> markPlayed(int id) => _dao.markPlayed(id);

  Future<int> deleteTrack(int id) => _dao.deleteTrack(id);

  Future<String> saveCustomCoverFile(String sourceImagePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final coverDir = Directory(p.join(appDir.path, _coverDirName));
    if (!await coverDir.exists()) {
      await coverDir.create(recursive: true);
    }
    final ext = p.extension(sourceImagePath).isNotEmpty
        ? p.extension(sourceImagePath).toLowerCase()
        : '.jpg';
    final name = '${DateTime.now().microsecondsSinceEpoch}$ext';
    final dest = File(p.join(coverDir.path, name));
    await File(sourceImagePath).copy(dest.path);
    return dest.path;
  }

  Future<int> setCustomCover(int id, String? coverPath) {
    return _dao.setUserEdited(id, TracksCompanion(coverPath: Value(coverPath)));
  }

  Future<int> clearCustomCover(int id) => setCustomCover(id, null);

  Future<int> editTrackMetadata(
    int id, {
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    String? genre,
    int? year,
    String? notes,
  }) {
    return _dao.setUserEdited(
      id,
      TracksCompanion(
        title: title == null ? const Value.absent() : Value(title),
        artist: artist == null ? const Value.absent() : Value(artist),
        album: album == null ? const Value.absent() : Value(album),
        albumArtist: albumArtist == null
            ? const Value.absent()
            : Value(albumArtist),
        genre: genre == null ? const Value.absent() : Value(genre),
        year: year == null ? const Value.absent() : Value(year),
        notes: notes == null ? const Value.absent() : Value(notes),
      ),
    );
  }

  Future<ImportResult> importPath(String sourcePath) async {
    final existing = await _dao.getByFilePath(sourcePath);
    if (existing != null) {
      return ImportResult(track: existing, skipped: true);
    }

    final meta = _metadataService.extractMetadata(sourcePath);

    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(appDir.path, _audioDirName));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    final coverDir = Directory(p.join(appDir.path, _coverDirName));
    if (!await coverDir.exists()) {
      await coverDir.create(recursive: true);
    }

    final storedFileName =
        '${DateTime.now().microsecondsSinceEpoch}${p.extension(meta.filePath)}';
    final storedPath = p.join(audioDir.path, storedFileName);

    if (meta.fileSize != null && meta.fileSize! > 0) {
      await File(sourcePath).copy(storedPath);
    } else {
      await File(sourcePath).copy(storedPath);
    }

    String? coverPath;
    if (meta.coverBytes != null && meta.coverBytes!.isNotEmpty) {
      final ext2 = _coverExtension(meta.coverMimeType);
      final coverFileName = '${DateTime.now().microsecondsSinceEpoch}$ext2';
      final coverFile = File(p.join(coverDir.path, coverFileName));
      await coverFile.writeAsBytes(meta.coverBytes!);
      coverPath = coverFile.path;
    }

    final id = await _dao.insertTrack(
      TracksCompanion.insert(
        title: meta.title,
        artist: Value(meta.artist),
        album: Value(meta.album),
        albumArtist: Value(meta.albumArtist),
        genre: Value(meta.genre),
        year: Value(meta.year),
        durationMs: Value(meta.durationMs),
        coverPath: Value(coverPath),
        filePath: storedPath,
        fileType: Value(meta.fileType),
        bitrate: Value(meta.bitrate),
        sampleRate: Value(meta.sampleRate),
        fileSize: Value(meta.fileSize),
        addedAt: DateTime.now(),
      ),
    );

    final track = await _dao.getById(id);
    return ImportResult(track: track!, skipped: false);
  }

  String _coverExtension(String? mimeType) {
    if (mimeType == null) return '.jpg';
    if (mimeType.contains('png')) return '.png';
    if (mimeType.contains('jpeg') || mimeType.contains('jpg')) return '.jpg';
    if (mimeType.contains('webp')) return '.webp';
    if (mimeType.contains('bmp')) return '.bmp';
    return '.jpg';
  }
}

class ImportResult {
  final Track track;
  final bool skipped;

  const ImportResult({required this.track, required this.skipped});
}
