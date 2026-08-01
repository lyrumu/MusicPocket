import '../daos/playlist_dao.dart';
import '../database/app_database.dart';

class PlaylistRepository {
  PlaylistRepository(this._dao);

  final PlaylistDao _dao;

  Stream<List<PlaylistWithTrackCount>> watchAllWithTrackCount() =>
      _dao.watchAllWithTrackCount();

  Future<Playlist?> getById(int id) => _dao.getById(id);

  Future<int> create(String name) => _dao.create(name);

  Future<int> rename(int id, String name) => _dao.rename(id, name);

  Future<int> deletePlaylist(int id) => _dao.deletePlaylist(id);

  Future<int?> addTrack(int playlistId, int trackId) =>
      _dao.addTrack(playlistId, trackId);

  Future<int> removeTrack(int playlistId, int trackId) =>
      _dao.removeTrack(playlistId, trackId);

  Stream<List<Track>> watchPlaylistTracks(int playlistId) =>
      _dao.watchPlaylistTracks(playlistId);

  Future<List<int>> getTrackIds(int playlistId) => _dao.getTrackIds(playlistId);

}
