import 'package:hive_flutter/hive_flutter.dart';
import '../models/song_model.dart';

class LocalStorage {
  static const _likedSongsBox = 'liked_songs';
  static const _recentBox = 'recent_songs';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_likedSongsBox);
    await Hive.openBox(_recentBox);
  }

  static Box get _liked => Hive.box(_likedSongsBox);
  static Box get _recent => Hive.box(_recentBox);

  static Future<void> likeSong(SongModel song) async {
    await _liked.put(song.id, {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'albumArt': song.albumArt,
      'url': song.url,
    });
  }

  static Future<void> unlikeSong(String id) async {
    await _liked.delete(id);
  }

  static bool isLiked(String id) => _liked.containsKey(id);

  static List<SongModel> getLikedSongs() {
    return _liked.values.map((e) => SongModel(
      id: e['id'],
      title: e['title'],
      artist: e['artist'],
      albumArt: e['albumArt'],
      url: e['url'],
    )).toList();
  }

  static Future<void> addRecent(SongModel song) async {
    await _recent.put(song.id, {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'albumArt': song.albumArt,
      'url': song.url,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static List<SongModel> getRecentSongs() {
    final songs = _recent.values.toList();
    songs.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    return songs.take(10).map((e) => SongModel(
      id: e['id'],
      title: e['title'],
      artist: e['artist'],
      albumArt: e['albumArt'],
      url: e['url'],
    )).toList();
  }
}
