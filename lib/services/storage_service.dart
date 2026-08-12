import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageUsage {
  final int audioBytes;
  final int coverBytes;
  final int databaseBytes;
  final int orphanedBytes;
  final List<String> orphanedPaths;

  const StorageUsage({
    required this.audioBytes,
    required this.coverBytes,
    required this.databaseBytes,
    required this.orphanedBytes,
    required this.orphanedPaths,
  });

  int get totalBytes => audioBytes + coverBytes + databaseBytes;
  int get orphanedFileCount => orphanedPaths.length;
}

class StorageCleanupResult {
  final int deletedFileCount;
  final int freedBytes;
  final int failedFileCount;

  const StorageCleanupResult({
    required this.deletedFileCount,
    required this.freedBytes,
    required this.failedFileCount,
  });
}

class StorageService {
  StorageService._()
    : _getDocumentsDirectory = getApplicationDocumentsDirectory;

  @visibleForTesting
  StorageService.forTesting(this._getDocumentsDirectory);

  static final instance = StorageService._();

  final Future<Directory> Function() _getDocumentsDirectory;

  Future<StorageUsage> getUsage({
    required Iterable<String> referencedAudioPaths,
    required Iterable<String> referencedCoverPaths,
  }) async {
    final documents = await _getDocumentsDirectory();
    final usage = await Future.wait([
      _managedDirectoryUsage(
        Directory(p.join(documents.path, 'audio')),
        referencedAudioPaths,
      ),
      _managedDirectoryUsage(
        Directory(p.join(documents.path, 'covers')),
        referencedCoverPaths,
      ),
      _directorySize(Directory(p.join(documents.path, 'music_pocket'))),
    ]);
    final audio = usage[0] as _ManagedDirectoryUsage;
    final covers = usage[1] as _ManagedDirectoryUsage;
    return StorageUsage(
      audioBytes: audio.totalBytes,
      coverBytes: covers.totalBytes,
      databaseBytes: usage[2] as int,
      orphanedBytes: audio.orphanedBytes + covers.orphanedBytes,
      orphanedPaths: [...audio.orphanedPaths, ...covers.orphanedPaths],
    );
  }

  Future<StorageCleanupResult> clearOrphanedFiles({
    required Iterable<String> candidatePaths,
    required Iterable<String> referencedAudioPaths,
    required Iterable<String> referencedCoverPaths,
  }) async {
    final documents = await _getDocumentsDirectory();
    final roots = [
      p.normalize(p.absolute(p.join(documents.path, 'audio'))),
      p.normalize(p.absolute(p.join(documents.path, 'covers'))),
    ];
    final referenced = {
      ...referencedAudioPaths.map(_normalize),
      ...referencedCoverPaths.map(_normalize),
    };
    var deleted = 0;
    var freed = 0;
    var failed = 0;

    for (final candidate in candidatePaths) {
      final path = _normalize(candidate);
      if (referenced.contains(path) ||
          !roots.any((root) => p.isWithin(root, path))) {
        continue;
      }
      try {
        if (await FileSystemEntity.type(path, followLinks: false) !=
            FileSystemEntityType.file) {
          continue;
        }
        final file = File(path);
        final size = await file.length();
        await file.delete();
        deleted++;
        freed += size;
      } catch (_) {
        failed++;
      }
    }

    return StorageCleanupResult(
      deletedFileCount: deleted,
      freedBytes: freed,
      failedFileCount: failed,
    );
  }

  Future<_ManagedDirectoryUsage> _managedDirectoryUsage(
    Directory directory,
    Iterable<String> referencedPaths,
  ) async {
    if (!await directory.exists()) return const _ManagedDirectoryUsage();
    final referenced = referencedPaths.map(_normalize).toSet();
    var total = 0;
    var orphaned = 0;
    final orphanedPaths = <String>[];
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final size = await entity.length();
      total += size;
      final path = _normalize(entity.path);
      if (!referenced.contains(path)) {
        orphaned += size;
        orphanedPaths.add(path);
      }
    }
    return _ManagedDirectoryUsage(
      totalBytes: total,
      orphanedBytes: orphaned,
      orphanedPaths: orphanedPaths,
    );
  }

  Future<int> _directorySize(Directory directory) async {
    if (!await directory.exists()) return 0;
    var total = 0;
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _normalize(String path) => p.normalize(p.absolute(path));
}

class _ManagedDirectoryUsage {
  final int totalBytes;
  final int orphanedBytes;
  final List<String> orphanedPaths;

  const _ManagedDirectoryUsage({
    this.totalBytes = 0,
    this.orphanedBytes = 0,
    this.orphanedPaths = const [],
  });
}
