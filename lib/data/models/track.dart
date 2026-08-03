import 'package:freezed_annotation/freezed_annotation.dart';

part 'track.freezed.dart';
part 'track.g.dart';

@freezed
class TrackModel with _$TrackModel {
  const factory TrackModel({
    required int id,
    required String title,
    @Default('') String artist,
    @Default('') String album,
    @Default('') String albumArtist,
    @Default('') String genre,
    int? year,
    @Default(0) int durationMs,
    String? coverPath,
    required String filePath,
    String? fileType,
    int? bitrate,
    int? sampleRate,
    int? fileSize,
    required DateTime addedAt,
    DateTime? modifiedAt,
    @Default(0) int playCount,
    DateTime? lastPlayedAt,
    @Default(false) bool isFavorite,
    String? notes,
  }) = _TrackModel;

  factory TrackModel.fromJson(Map<String, dynamic> json) =>
      _$TrackModelFromJson(json);

  const TrackModel._();

  String get durationFormatted {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get displayArtist => artist.isEmpty ? '未知艺术家' : artist;
  String get displayAlbum => album.isEmpty ? '未知专辑' : album;
}
