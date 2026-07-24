// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PlaylistModel _$PlaylistModelFromJson(Map<String, dynamic> json) {
  return _PlaylistModel.fromJson(json);
}

/// @nodoc
mixin _$PlaylistModel {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String? get coverPath => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this PlaylistModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaylistModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaylistModelCopyWith<PlaylistModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaylistModelCopyWith<$Res> {
  factory $PlaylistModelCopyWith(
    PlaylistModel value,
    $Res Function(PlaylistModel) then,
  ) = _$PlaylistModelCopyWithImpl<$Res, PlaylistModel>;
  @useResult
  $Res call({
    int id,
    String name,
    String description,
    String? coverPath,
    DateTime createdAt,
    DateTime updatedAt,
    int sortOrder,
  });
}

/// @nodoc
class _$PlaylistModelCopyWithImpl<$Res, $Val extends PlaylistModel>
    implements $PlaylistModelCopyWith<$Res> {
  _$PlaylistModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaylistModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? coverPath = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? sortOrder = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            coverPath: freezed == coverPath
                ? _value.coverPath
                : coverPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaylistModelImplCopyWith<$Res>
    implements $PlaylistModelCopyWith<$Res> {
  factory _$$PlaylistModelImplCopyWith(
    _$PlaylistModelImpl value,
    $Res Function(_$PlaylistModelImpl) then,
  ) = __$$PlaylistModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String description,
    String? coverPath,
    DateTime createdAt,
    DateTime updatedAt,
    int sortOrder,
  });
}

/// @nodoc
class __$$PlaylistModelImplCopyWithImpl<$Res>
    extends _$PlaylistModelCopyWithImpl<$Res, _$PlaylistModelImpl>
    implements _$$PlaylistModelImplCopyWith<$Res> {
  __$$PlaylistModelImplCopyWithImpl(
    _$PlaylistModelImpl _value,
    $Res Function(_$PlaylistModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaylistModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? coverPath = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? sortOrder = null,
  }) {
    return _then(
      _$PlaylistModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        coverPath: freezed == coverPath
            ? _value.coverPath
            : coverPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaylistModelImpl implements _PlaylistModel {
  const _$PlaylistModelImpl({
    required this.id,
    required this.name,
    this.description = '',
    this.coverPath,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
  });

  factory _$PlaylistModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaylistModelImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  @JsonKey()
  final String description;
  @override
  final String? coverPath;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'PlaylistModel(id: $id, name: $name, description: $description, coverPath: $coverPath, createdAt: $createdAt, updatedAt: $updatedAt, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.coverPath, coverPath) ||
                other.coverPath == coverPath) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    coverPath,
    createdAt,
    updatedAt,
    sortOrder,
  );

  /// Create a copy of PlaylistModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistModelImplCopyWith<_$PlaylistModelImpl> get copyWith =>
      __$$PlaylistModelImplCopyWithImpl<_$PlaylistModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaylistModelImplToJson(this);
  }
}

abstract class _PlaylistModel implements PlaylistModel {
  const factory _PlaylistModel({
    required final int id,
    required final String name,
    final String description,
    final String? coverPath,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final int sortOrder,
  }) = _$PlaylistModelImpl;

  factory _PlaylistModel.fromJson(Map<String, dynamic> json) =
      _$PlaylistModelImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get description;
  @override
  String? get coverPath;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  int get sortOrder;

  /// Create a copy of PlaylistModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaylistModelImplCopyWith<_$PlaylistModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlaylistTrackModel _$PlaylistTrackModelFromJson(Map<String, dynamic> json) {
  return _PlaylistTrackModel.fromJson(json);
}

/// @nodoc
mixin _$PlaylistTrackModel {
  int get id => throw _privateConstructorUsedError;
  int get playlistId => throw _privateConstructorUsedError;
  int get trackId => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;
  DateTime get addedAt => throw _privateConstructorUsedError;

  /// Serializes this PlaylistTrackModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaylistTrackModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaylistTrackModelCopyWith<PlaylistTrackModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaylistTrackModelCopyWith<$Res> {
  factory $PlaylistTrackModelCopyWith(
    PlaylistTrackModel value,
    $Res Function(PlaylistTrackModel) then,
  ) = _$PlaylistTrackModelCopyWithImpl<$Res, PlaylistTrackModel>;
  @useResult
  $Res call({
    int id,
    int playlistId,
    int trackId,
    int position,
    DateTime addedAt,
  });
}

/// @nodoc
class _$PlaylistTrackModelCopyWithImpl<$Res, $Val extends PlaylistTrackModel>
    implements $PlaylistTrackModelCopyWith<$Res> {
  _$PlaylistTrackModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaylistTrackModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? playlistId = null,
    Object? trackId = null,
    Object? position = null,
    Object? addedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            playlistId: null == playlistId
                ? _value.playlistId
                : playlistId // ignore: cast_nullable_to_non_nullable
                      as int,
            trackId: null == trackId
                ? _value.trackId
                : trackId // ignore: cast_nullable_to_non_nullable
                      as int,
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as int,
            addedAt: null == addedAt
                ? _value.addedAt
                : addedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaylistTrackModelImplCopyWith<$Res>
    implements $PlaylistTrackModelCopyWith<$Res> {
  factory _$$PlaylistTrackModelImplCopyWith(
    _$PlaylistTrackModelImpl value,
    $Res Function(_$PlaylistTrackModelImpl) then,
  ) = __$$PlaylistTrackModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int playlistId,
    int trackId,
    int position,
    DateTime addedAt,
  });
}

/// @nodoc
class __$$PlaylistTrackModelImplCopyWithImpl<$Res>
    extends _$PlaylistTrackModelCopyWithImpl<$Res, _$PlaylistTrackModelImpl>
    implements _$$PlaylistTrackModelImplCopyWith<$Res> {
  __$$PlaylistTrackModelImplCopyWithImpl(
    _$PlaylistTrackModelImpl _value,
    $Res Function(_$PlaylistTrackModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaylistTrackModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? playlistId = null,
    Object? trackId = null,
    Object? position = null,
    Object? addedAt = null,
  }) {
    return _then(
      _$PlaylistTrackModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        playlistId: null == playlistId
            ? _value.playlistId
            : playlistId // ignore: cast_nullable_to_non_nullable
                  as int,
        trackId: null == trackId
            ? _value.trackId
            : trackId // ignore: cast_nullable_to_non_nullable
                  as int,
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as int,
        addedAt: null == addedAt
            ? _value.addedAt
            : addedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaylistTrackModelImpl implements _PlaylistTrackModel {
  const _$PlaylistTrackModelImpl({
    required this.id,
    required this.playlistId,
    required this.trackId,
    required this.position,
    required this.addedAt,
  });

  factory _$PlaylistTrackModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaylistTrackModelImplFromJson(json);

  @override
  final int id;
  @override
  final int playlistId;
  @override
  final int trackId;
  @override
  final int position;
  @override
  final DateTime addedAt;

  @override
  String toString() {
    return 'PlaylistTrackModel(id: $id, playlistId: $playlistId, trackId: $trackId, position: $position, addedAt: $addedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistTrackModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.playlistId, playlistId) ||
                other.playlistId == playlistId) &&
            (identical(other.trackId, trackId) || other.trackId == trackId) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.addedAt, addedAt) || other.addedAt == addedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, playlistId, trackId, position, addedAt);

  /// Create a copy of PlaylistTrackModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistTrackModelImplCopyWith<_$PlaylistTrackModelImpl> get copyWith =>
      __$$PlaylistTrackModelImplCopyWithImpl<_$PlaylistTrackModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaylistTrackModelImplToJson(this);
  }
}

abstract class _PlaylistTrackModel implements PlaylistTrackModel {
  const factory _PlaylistTrackModel({
    required final int id,
    required final int playlistId,
    required final int trackId,
    required final int position,
    required final DateTime addedAt,
  }) = _$PlaylistTrackModelImpl;

  factory _PlaylistTrackModel.fromJson(Map<String, dynamic> json) =
      _$PlaylistTrackModelImpl.fromJson;

  @override
  int get id;
  @override
  int get playlistId;
  @override
  int get trackId;
  @override
  int get position;
  @override
  DateTime get addedAt;

  /// Create a copy of PlaylistTrackModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaylistTrackModelImplCopyWith<_$PlaylistTrackModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
