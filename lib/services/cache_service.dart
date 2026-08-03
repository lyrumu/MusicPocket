import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_player_service.dart';

class CacheClearResult {
  final int freedBytes;
  final bool success;

  CacheClearResult({required this.freedBytes, this.success = true});
}

class CacheService {
  CacheService._();
  static final instance = CacheService._();

  Future<CacheClearResult> clearCache() async {
    var freed = 0;
    var success = true;

    try {
      await AudioPlayerService.instance.stop();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final cacheDir = await getApplicationCacheDirectory();
      freed += await _clearDirectory(cacheDir);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CacheService] clear cache error: $e');
        debugPrint('$st');
      }
      success = false;
    }

    return CacheClearResult(freedBytes: freed, success: success);
  }

  Future<int> _clearDirectory(Directory dir) async {
    var total = 0;
    if (!await dir.exists()) return 0;
    await for (final entity in dir.list()) {
      try {
        if (entity is File) {
          total += await entity.length();
          await entity.delete();
        } else if (entity is Directory) {
          total += await _directorySize(entity);
          await entity.delete(recursive: true);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[CacheService] failed to delete ${entity.path}: $e');
        }
      }
    }
    return total;
  }

  Future<int> _directorySize(Directory dir) async {
    var total = 0;
    if (!await dir.exists()) return 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
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
}
