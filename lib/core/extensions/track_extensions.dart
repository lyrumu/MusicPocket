import '../../data/database/app_database.dart';

extension TrackDisplayX on Track {
  String get displayTitle => title.isEmpty ? '未知标题' : title;
  String get displayArtist => artist.isEmpty ? '未知艺术家' : artist;
  String get displayAlbum => album.isEmpty ? '未知专辑' : album;

  String get durationFormatted {
    final d = Duration(milliseconds: durationMs);
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
