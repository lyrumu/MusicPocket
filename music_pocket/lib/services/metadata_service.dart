import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class TrackMetadata {
  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final String genre;
  final int? year;
  final int durationMs;
  final String filePath;
  final String? fileType;
  final int? bitrate;
  final int? sampleRate;
  final int? fileSize;
  final Uint8List? coverBytes;
  final String? coverMimeType;

  const TrackMetadata({
    required this.title,
    this.artist = '',
    this.album = '',
    this.albumArtist = '',
    this.genre = '',
    this.year,
    this.durationMs = 0,
    required this.filePath,
    this.fileType,
    this.bitrate,
    this.sampleRate,
    this.fileSize,
    this.coverBytes,
    this.coverMimeType,
  });
}

class MetadataService {
  MetadataService._();
  static final instance = MetadataService._();

  TrackMetadata extractMetadata(String filePath) {
    final file = File(filePath);
    final fallbackTitle = p.basenameWithoutExtension(filePath);
    final fileType = p.extension(filePath).replaceFirst('.', '').toLowerCase();

    int? fileSize;
    try {
      fileSize = file.lengthSync();
    } catch (_) {}

    try {
      final meta = readMetadata(file, getImage: true);

      Picture? cover;
      for (final pic in meta.pictures) {
        if (pic.pictureType == PictureType.coverFront) {
          cover = pic;
          break;
        }
      }
      cover ??= meta.pictures.isNotEmpty ? meta.pictures.first : null;

      return TrackMetadata(
        title: (meta.title?.isNotEmpty ?? false) ? meta.title! : fallbackTitle,
        artist: meta.artist ?? '',
        album: meta.album ?? '',
        albumArtist: '',
        genre: meta.genres.isNotEmpty ? meta.genres.first : '',
        year: meta.year != null && meta.year!.year > 0 ? meta.year!.year : null,
        durationMs: meta.duration?.inMilliseconds ?? 0,
        filePath: filePath,
        fileType: fileType,
        bitrate: meta.bitrate,
        sampleRate: meta.sampleRate,
        fileSize: fileSize,
        coverBytes: cover?.bytes,
        coverMimeType: cover?.mimetype,
      );
    } catch (e) {
      debugPrint('[MetadataService] Failed to parse $filePath: $e');
      return TrackMetadata(
        title: fallbackTitle,
        filePath: filePath,
        fileType: fileType,
        fileSize: fileSize,
      );
    }
  }
}
