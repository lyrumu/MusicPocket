// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TrackModel _$TrackModelFromJson(Map<String, dynamic> json) {
  return _TrackModel.fromJson(json);
}

/// @nodoc
mixin _$TrackModel {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get artist => throw _privateConstructorUsedError;
  String get album => throw _privateConstructorUsedError;
  String get albumArtist => throw _privateConstructorUsedError;
  String get genre => throw _privateConstructorUsedError;
  int? get year => throw _privateConstructorUsedError;
  int get durationMs => throw _privateConstructorUsedError;
  String? get coverPath => throw _privateConstructorUsedError;
  String get filePath => throw _privateConstructorUsedError;
  String? get fileType => throw _privateConstructorUsedError;
  int? get bitrate => throw _privateConstructorUsedError;
  int? get sampleRate => throw _privateConstructorUsedError;
  int? get fileSize => throw _privateConstructorUsedError;
  DateTime get addedAt => throw _privateConstructorUsedError;
  DateTime? get modifiedAt => throw _privateConstructorUsedError;
  int get playCount => throw _privateConstructorUsedError;
  DateTime? get lastPlayedAt => throw _privateConstructorUsedError;
  bool get isFavorite => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this TrackModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrackModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrackModelCopyWith<TrackModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrackModelCopyWith<$Res> {
  factory $TrackModelCopyWith(
    TrackModel value,
    $Res Function(TrackModel) then,
  ) = _$TrackModelCopyWithImpl<$Res, TrackModel>;
  @useResult
  $Res call({
    int id,
    String title,
    String artist,
    String album,
    String albumArtist,
    String genre,
    int? year,
    int durationMs,
    String? coverPath,
    String filePath,
    String? fileType,
    int? bitrate,
    int? sampleRate,
    int? fileSize,
    DateTime addedAt,
    DateTime? modifiedAt,
    int playCount,
    DateTime? lastPlayedAt,
    bool isFavorite,
    String? notes,
  });
}

/// @nodoc
class _$TrackModelCopyWithImpl<$Res, $Val extends TrackModel>
    implements $TrackModelCopyWith<$Res> {
  _$TrackModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrackModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artist = null,
    Object? album = null,
    Object? albumArtist = null,
    Object? genre = null,
    Object? year = freezed,
    Object? durationMs = null,
    Object? coverPath = freezed,
    Object? filePath = null,
    Object? fileType = freezed,
    Object? bitrate = freezed,
    Object? sampleRate = freezed,
    Object? fileSize = freezed,
    Object? addedAt = null,
    Object? modifiedAt = freezed,
    Object? playCount = null,
    Object? lastPlayedAt = freezed,
    Object? isFavorite = null,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            artist: null == artist
                ? _value.artist
                : artist // ignore: cast_nullable_to_non_nullable
                      as String,
            album: null == album
                ? _value.album
                : album // ignore: cast_nullable_to_non_nullable
                      as String,
            albumArtist: null == albumArtist
                ? _value.albumArtist
                : albumArtist // ignore: cast_nullable_to_non_nullable
                      as String,
            genre: null == genre
                ? _value.genre
                : genre // ignore: cast_nullable_to_non_nullable
                      as String,
            year: freezed == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as int?,
            durationMs: null == durationMs
                ? _value.durationMs
                : durationMs // ignore: cast_nullable_to_non_nullable
                      as int,
            coverPath: freezed == coverPath
                ? _value.coverPath
                : coverPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            filePath: null == filePath
                ? _value.filePath
                : filePath // ignore: cast_nullable_to_non_nullable
                      as String,
            fileType: freezed == fileType
                ? _value.fileType
                : fileType // ignore: cast_nullable_to_non_nullable
                      as String?,
            bitrate: freezed == bitrate
                ? _value.bitrate
                : bitrate // ignore: cast_nullable_to_non_nullable
                      as int?,
            sampleRate: freezed == sampleRate
                ? _value.sampleRate
                : sampleRate // ignore: cast_nullable_to_non_nullable
                      as int?,
            fileSize: freezed == fileSize
                ? _value.fileSize
                : fileSize // ignore: cast_nullable_to_non_nullable
                      as int?,
            addedAt: null == addedAt
                ? _value.addedAt
                : addedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            modifiedAt: freezed == modifiedAt
                ? _value.modifiedAt
                : modifiedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            playCount: null == playCount
                ? _value.playCount
                : playCount // ignore: cast_nullable_to_non_nullable
                      as int,
            lastPlayedAt: freezed == lastPlayedAt
                ? _value.lastPlayedAt
                : lastPlayedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isFavorite: null == isFavorite
                ? _value.isFavorite
                : isFavorite // ignore: cast_nullable_to_non_nullable
                      as bool,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TrackModelImplCopyWith<$Res>
    implements $TrackModelCopyWith<$Res> {
  factory _$$TrackModelImplCopyWith(
    _$TrackModelImpl value,
    $Res Function(_$TrackModelImpl) then,
  ) = __$$TrackModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String title,
    String artist,
    String album,
    String albumArtist,
    String genre,
    int? year,
    int durationMs,
    String? coverPath,
    String filePath,
    String? fileType,
    int? bitrate,
    int? sampleRate,
    int? fileSize,
    DateTime addedAt,
    DateTime? modifiedAt,
    int playCount,
    DateTime? lastPlayedAt,
    bool isFavorite,
    String? notes,
  });
}

/// @nodoc
class __$$TrackModelImplCopyWithImpl<$Res>
    extends _$TrackModelCopyWithImpl<$Res, _$TrackModelImpl>
    implements _$$TrackModelImplCopyWith<$Res> {
  __$$TrackModelImplCopyWithImpl(
    _$TrackModelImpl _value,
    $Res Function(_$TrackModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrackModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artist = null,
    Object? album = null,
    Object? albumArtist = null,
    Object? genre = null,
    Object? year = freezed,
    Object? durationMs = null,
    Object? coverPath = freezed,
    Object? filePath = null,
    Object? fileType = freezed,
    Object? bitrate = freezed,
    Object? sampleRate = freezed,
    Object? fileSize = freezed,
    Object? addedAt = null,
    Object? modifiedAt = freezed,
    Object? playCount = null,
    Object? lastPlayedAt = freezed,
    Object? isFavorite = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$TrackModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        artist: null == artist
            ? _value.artist
            : artist // ignore: cast_nullable_to_non_nullable
                  as String,
        album: null == album
            ? _value.album
            : album // ignore: cast_nullable_to_non_nullable
                  as String,
        albumArtist: null == albumArtist
            ? _value.albumArtist
            : albumArtist // ignore: cast_nullable_to_non_nullable
                  as String,
        genre: null == genre
            ? _value.genre
            : genre // ignore: cast_nullable_to_non_nullable
                  as String,
        year: freezed == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int?,
        durationMs: null == durationMs
            ? _value.durationMs
            : durationMs // ignore: cast_nullable_to_non_nullable
                  as int,
        coverPath: freezed == coverPath
            ? _value.coverPath
            : coverPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        filePath: null == filePath
            ? _value.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String,
        fileType: freezed == fileType
            ? _value.fileType
            : fileType // ignore: cast_nullable_to_non_nullable
                  as String?,
        bitrate: freezed == bitrate
            ? _value.bitrate
            : bitrate // ignore: cast_nullable_to_non_nullable
                  as int?,
        sampleRate: freezed == sampleRate
            ? _value.sampleRate
            : sampleRate // ignore: cast_nullable_to_non_nullable
                  as int?,
        fileSize: freezed == fileSize
            ? _value.fileSize
            : fileSize // ignore: cast_nullable_to_non_nullable
                  as int?,
        addedAt: null == addedAt
            ? _value.addedAt
            : addedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        modifiedAt: freezed == modifiedAt
            ? _value.modifiedAt
            : modifiedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        playCount: null == playCount
            ? _value.playCount
            : playCount // ignore: cast_nullable_to_non_nullable
                  as int,
        lastPlayedAt: freezed == lastPlayedAt
            ? _value.lastPlayedAt
            : lastPlayedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isFavorite: null == isFavorite
            ? _value.isFavorite
            : isFavorite // ignore: cast_nullable_to_non_nullable
                  as bool,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TrackModelImpl extends _TrackModel {
  const _$TrackModelImpl({
    required this.id,
    required this.title,
    this.artist = '',
    this.album = '',
    this.albumArtist = '',
    this.genre = '',
    this.year,
    this.durationMs = 0,
    this.coverPath,
    required this.filePath,
    this.fileType,
    this.bitrate,
    this.sampleRate,
    this.fileSize,
    required this.addedAt,
    this.modifiedAt,
    this.playCount = 0,
    this.lastPlayedAt,
    this.isFavorite = false,
    this.notes,
  }) : super._();

  factory _$TrackModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrackModelImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  @JsonKey()
  final String artist;
  @override
  @JsonKey()
  final String album;
  @override
  @JsonKey()
  final String albumArtist;
  @override
  @JsonKey()
  final String genre;
  @override
  final int? year;
  @override
  @JsonKey()
  final int durationMs;
  @override
  final String? coverPath;
  @override
  final String filePath;
  @override
  final String? fileType;
  @override
  final int? bitrate;
  @override
  final int? sampleRate;
  @override
  final int? fileSize;
  @override
  final DateTime addedAt;
  @override
  final DateTime? modifiedAt;
  @override
  @JsonKey()
  final int playCount;
  @override
  final DateTime? lastPlayedAt;
  @override
  @JsonKey()
  final bool isFavorite;
  @override
  final String? notes;

  @override
  String toString() {
    return 'TrackModel(id: $id, title: $title, artist: $artist, album: $album, albumArtist: $albumArtist, genre: $genre, year: $year, durationMs: $durationMs, coverPath: $coverPath, filePath: $filePath, fileType: $fileType, bitrate: $bitrate, sampleRate: $sampleRate, fileSize: $fileSize, addedAt: $addedAt, modifiedAt: $modifiedAt, playCount: $playCount, lastPlayedAt: $lastPlayedAt, isFavorite: $isFavorite, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrackModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.album, album) || other.album == album) &&
            (identical(other.albumArtist, albumArtist) ||
                other.albumArtist == albumArtist) &&
            (identical(other.genre, genre) || other.genre == genre) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.coverPath, coverPath) ||
                other.coverPath == coverPath) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.bitrate, bitrate) || other.bitrate == bitrate) &&
            (identical(other.sampleRate, sampleRate) ||
                other.sampleRate == sampleRate) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.addedAt, addedAt) || other.addedAt == addedAt) &&
            (identical(other.modifiedAt, modifiedAt) ||
                other.modifiedAt == modifiedAt) &&
            (identical(other.playCount, playCount) ||
                other.playCount == playCount) &&
            (identical(other.lastPlayedAt, lastPlayedAt) ||
                other.lastPlayedAt == lastPlayedAt) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    title,
    artist,
    album,
    albumArtist,
    genre,
    year,
    durationMs,
    coverPath,
    filePath,
    fileType,
    bitrate,
    sampleRate,
    fileSize,
    addedAt,
    modifiedAt,
    playCount,
    lastPlayedAt,
    isFavorite,
    notes,
  ]);

  /// Create a copy of TrackModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrackModelImplCopyWith<_$TrackModelImpl> get copyWith =>
      __$$TrackModelImplCopyWithImpl<_$TrackModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrackModelImplToJson(this);
  }
}

abstract class _TrackModel extends TrackModel {
  const factory _TrackModel({
    required final int id,
    required final String title,
    final String artist,
    final String album,
    final String albumArtist,
    final String genre,
    final int? year,
    final int durationMs,
    final String? coverPath,
    required final String filePath,
    final String? fileType,
    final int? bitrate,
    final int? sampleRate,
    final int? fileSize,
    required final DateTime addedAt,
    final DateTime? modifiedAt,
    final int playCount,
    final DateTime? lastPlayedAt,
    final bool isFavorite,
    final String? notes,
  }) = _$TrackModelImpl;
  const _TrackModel._() : super._();

  factory _TrackModel.fromJson(Map<String, dynamic> json) =
      _$TrackModelImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  String get artist;
  @override
  String get album;
  @override
  String get albumArtist;
  @override
  String get genre;
  @override
  int? get year;
  @override
  int get durationMs;
  @override
  String? get coverPath;
  @override
  String get filePath;
  @override
  String? get fileType;
  @override
  int? get bitrate;
  @override
  int? get sampleRate;
  @override
  int? get fileSize;
  @override
  DateTime get addedAt;
  @override
  DateTime? get modifiedAt;
  @override
  int get playCount;
  @override
  DateTime? get lastPlayedAt;
  @override
  bool get isFavorite;
  @override
  String? get notes;

  /// Create a copy of TrackModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrackModelImplCopyWith<_$TrackModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
