import 'package:freezed_annotation/freezed_annotation.dart';

part 'playlist.freezed.dart';
part 'playlist.g.dart';

@freezed
class PlaylistModel with _$PlaylistModel {
  const factory PlaylistModel({
    required int id,
    required String name,
    @Default('') String description,
    String? coverPath,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(0) int sortOrder,
  }) = _PlaylistModel;

  factory PlaylistModel.fromJson(Map<String, dynamic> json) =>
      _$PlaylistModelFromJson(json);
}

@freezed
class PlaylistTrackModel with _$PlaylistTrackModel {
  const factory PlaylistTrackModel({
    required int id,
    required int playlistId,
    required int trackId,
    required int position,
    required DateTime addedAt,
  }) = _PlaylistTrackModel;

  factory PlaylistTrackModel.fromJson(Map<String, dynamic> json) =>
      _$PlaylistTrackModelFromJson(json);
}
