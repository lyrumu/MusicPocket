// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlaylistModelImpl _$$PlaylistModelImplFromJson(Map<String, dynamic> json) =>
    _$PlaylistModelImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      coverPath: json['coverPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$PlaylistModelImplToJson(_$PlaylistModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'coverPath': instance.coverPath,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'sortOrder': instance.sortOrder,
    };

_$PlaylistTrackModelImpl _$$PlaylistTrackModelImplFromJson(
  Map<String, dynamic> json,
) => _$PlaylistTrackModelImpl(
  id: (json['id'] as num).toInt(),
  playlistId: (json['playlistId'] as num).toInt(),
  trackId: (json['trackId'] as num).toInt(),
  position: (json['position'] as num).toInt(),
  addedAt: DateTime.parse(json['addedAt'] as String),
);

Map<String, dynamic> _$$PlaylistTrackModelImplToJson(
  _$PlaylistTrackModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'playlistId': instance.playlistId,
  'trackId': instance.trackId,
  'position': instance.position,
  'addedAt': instance.addedAt.toIso8601String(),
};
