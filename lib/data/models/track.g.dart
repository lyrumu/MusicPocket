// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TrackModelImpl _$$TrackModelImplFromJson(Map<String, dynamic> json) =>
    _$TrackModelImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      artist: json['artist'] as String? ?? '',
      album: json['album'] as String? ?? '',
      albumArtist: json['albumArtist'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      year: (json['year'] as num?)?.toInt(),
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      coverPath: json['coverPath'] as String?,
      filePath: json['filePath'] as String,
      fileType: json['fileType'] as String?,
      bitrate: (json['bitrate'] as num?)?.toInt(),
      sampleRate: (json['sampleRate'] as num?)?.toInt(),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      addedAt: DateTime.parse(json['addedAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      lastPlayedAt: json['lastPlayedAt'] == null
          ? null
          : DateTime.parse(json['lastPlayedAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$TrackModelImplToJson(_$TrackModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'album': instance.album,
      'albumArtist': instance.albumArtist,
      'genre': instance.genre,
      'year': instance.year,
      'durationMs': instance.durationMs,
      'coverPath': instance.coverPath,
      'filePath': instance.filePath,
      'fileType': instance.fileType,
      'bitrate': instance.bitrate,
      'sampleRate': instance.sampleRate,
      'fileSize': instance.fileSize,
      'addedAt': instance.addedAt.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'playCount': instance.playCount,
      'lastPlayedAt': instance.lastPlayedAt?.toIso8601String(),
      'isFavorite': instance.isFavorite,
      'notes': instance.notes,
    };
