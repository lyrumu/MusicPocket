import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../daos/track_dao.dart';
import '../../services/metadata_service.dart';
import '../../services/content_hash_service.dart';

class TrackRepository {
  TrackRepository(
    this._dao,
    MetadataService metadataService, {
    ContentHashService? contentHashService,
    Future<Directory> Function()? getDocumentsDirectory,
    Future<void> Function(File file)? deleteFile,
    TrackMetadata Function(String filePath)? extractMetadata,
  }) : _contentHashService = contentHashService ?? ContentHashService.instance,
       _getDocumentsDirectory =
           getDocumentsDirectory ?? getApplicationDocumentsDirectory,
       _deleteFile = deleteFile ?? _defaultDeleteFile,
       _extractMetadata = extractMetadata ?? metadataService.extractMetadata;

  final TrackDao _dao;
  final ContentHashService _contentHashService;
  final Future<Directory> Function() _getDocumentsDirectory;
  final Future<void> Function(File file) _deleteFile;
  final TrackMetadata Function(String filePath) _extractMetadata;

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

  Future<void> deleteTrack(int id) async {
    final track = await _dao.getById(id);
    if (track == null) return;

    final appDir = await _getDocumentsDirectory();
    final coverPaths = <String>{
      ?track.coverPath,
      ?track.originalCoverPath,
      ?track.customCoverPath,
    };

    for (final coverPath in coverPaths) {
      final referenced = await _dao.isCoverPathReferenced(
        coverPath,
        excludingTrackId: id,
      );
      if (!referenced) {
        await _deleteManagedFile(
          coverPath,
          managedDirectory: p.join(appDir.path, _coverDirName),
        );
      }
    }

    await _deleteManagedFile(
      track.filePath,
      managedDirectory: p.join(appDir.path, _audioDirName),
    );

    try {
      await _dao.deleteTrack(id);
    } catch (error) {
      throw TrackDeletionException('数据库记录删除失败', cause: error);
    }
  }

  Future<CoverUpdateResult> setCustomCoverFromFile(
    int id,
    String sourceImagePath,
  ) async {
    final storedPath = await _saveCustomCoverFile(sourceImagePath);
    try {
      return await _setCustomCover(id, storedPath);
    } catch (_) {
      await _deleteManagedCoverIfUnreferenced(storedPath, ignoreFailure: true);
      rethrow;
    }
  }

  Future<String> _saveCustomCoverFile(String sourceImagePath) async {
    final appDir = await _getDocumentsDirectory();
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

  Future<CoverUpdateResult> _setCustomCover(int id, String coverPath) async {
    var track = await _requireTrack(id);
    track = await _ensureOriginalCoverState(track);
    final oldCustomPath = track.customCoverPath;

    await _dao.setUserEdited(
      id,
      TracksCompanion(
        coverPath: Value(coverPath),
        customCoverPath: Value(coverPath),
      ),
    );

    final warning = await _cleanupReplacedCover(oldCustomPath, coverPath);
    return CoverUpdateResult(coverPath: coverPath, warning: warning);
  }

  Future<CoverUpdateResult> clearCustomCover(int id) async {
    var track = await _requireTrack(id);
    track = await _ensureOriginalCoverState(track);
    final oldCustomPath = track.customCoverPath;
    final originalCoverPath = track.originalCoverPath;

    await _dao.setUserEdited(
      id,
      TracksCompanion(
        coverPath: Value(originalCoverPath),
        customCoverPath: const Value(null),
      ),
    );

    final warning = await _cleanupReplacedCover(
      oldCustomPath,
      originalCoverPath,
    );
    return CoverUpdateResult(coverPath: originalCoverPath, warning: warning);
  }

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
    final contentHash = await _contentHashService.calculateFileHash(sourcePath);
    await _backfillContentHashes();
    final existing = await _dao.getByContentHash(contentHash);
    if (existing != null) {
      return ImportResult(track: existing, skipped: true);
    }

    final meta = _extractMetadata(sourcePath);

    final appDir = await _getDocumentsDirectory();
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
        originalCoverPath: Value(coverPath),
        filePath: storedPath,
        contentHash: Value(contentHash),
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

  Future<void> _backfillContentHashes() async {
    final tracks = await _dao.getWithoutContentHash();
    for (final track in tracks) {
      final contentHash = await _contentHashService.calculateFileHash(
        track.filePath,
      );
      await _dao.setContentHash(track.id, contentHash);
    }
  }

  Future<Track> _requireTrack(int id) async {
    final track = await _dao.getById(id);
    if (track == null) {
      throw StateError('Track $id does not exist');
    }
    return track;
  }

  Future<Track> _ensureOriginalCoverState(Track track) async {
    if (track.originalCoverPath != null &&
        track.originalCoverPath!.isNotEmpty) {
      return track;
    }

    final metadata = _extractMetadata(track.filePath);
    final coverBytes = metadata.coverBytes;
    String? originalCoverPath;
    String? customCoverPath = track.customCoverPath ?? track.coverPath;

    if (coverBytes != null && coverBytes.isNotEmpty) {
      final currentPath = track.coverPath;
      if (currentPath != null &&
          await _fileMatchesBytes(currentPath, coverBytes)) {
        originalCoverPath = currentPath;
        customCoverPath = null;
      } else {
        final appDir = await _getDocumentsDirectory();
        originalCoverPath = await _saveCoverBytes(
          appDir,
          coverBytes,
          metadata.coverMimeType,
        );
      }
    }

    try {
      await _dao.patchTrackFields(
        track.id,
        TracksCompanion(
          originalCoverPath: Value(originalCoverPath),
          customCoverPath: Value(customCoverPath),
        ),
      );
    } catch (_) {
      if (originalCoverPath != null && originalCoverPath != track.coverPath) {
        await _deleteManagedCoverIfUnreferenced(
          originalCoverPath,
          ignoreFailure: true,
        );
      }
      rethrow;
    }
    return (await _dao.getById(track.id))!;
  }

  Future<String> _saveCoverBytes(
    Directory appDir,
    List<int> bytes,
    String? mimeType,
  ) async {
    final coverDir = Directory(p.join(appDir.path, _coverDirName));
    if (!await coverDir.exists()) {
      await coverDir.create(recursive: true);
    }
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}${_coverExtension(mimeType)}';
    final file = File(p.join(coverDir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<bool> _fileMatchesBytes(String filePath, List<int> bytes) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    try {
      return const ListEquality<int>().equals(await file.readAsBytes(), bytes);
    } catch (_) {
      return false;
    }
  }

  Future<String?> _cleanupReplacedCover(
    String? oldPath,
    String? activePath,
  ) async {
    if (oldPath == null || oldPath.isEmpty || oldPath == activePath) {
      return null;
    }
    try {
      await _deleteManagedCoverIfUnreferenced(oldPath);
      return null;
    } catch (error) {
      return '封面已更新，但旧封面文件清理失败：$error';
    }
  }

  Future<void> _deleteManagedCoverIfUnreferenced(
    String coverPath, {
    bool ignoreFailure = false,
  }) async {
    if (await _dao.isCoverPathReferenced(coverPath)) return;
    try {
      final appDir = await _getDocumentsDirectory();
      await _deleteManagedFile(
        coverPath,
        managedDirectory: p.join(appDir.path, _coverDirName),
      );
    } catch (_) {
      if (!ignoreFailure) rethrow;
    }
  }

  Future<void> _deleteManagedFile(
    String filePath, {
    required String managedDirectory,
  }) async {
    final normalizedFile = p.normalize(p.absolute(filePath));
    final normalizedDirectory = p.normalize(p.absolute(managedDirectory));
    if (!p.isWithin(normalizedDirectory, normalizedFile)) return;

    final type = await FileSystemEntity.type(
      normalizedFile,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) return;
    if (type != FileSystemEntityType.file &&
        type != FileSystemEntityType.link) {
      throw TrackDeletionException('托管路径不是文件：$filePath');
    }
    try {
      await _deleteFile(File(normalizedFile));
    } catch (error) {
      throw TrackDeletionException('无法删除托管文件：$filePath', cause: error);
    }
  }

  static Future<void> _defaultDeleteFile(File file) async {
    await file.delete();
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

class CoverUpdateResult {
  final String? coverPath;
  final String? warning;

  const CoverUpdateResult({required this.coverPath, this.warning});
}

class TrackDeletionException implements Exception {
  final String message;
  final Object? cause;

  const TrackDeletionException(this.message, {this.cause});

  @override
  String toString() => cause == null ? message : '$message（$cause）';
}
