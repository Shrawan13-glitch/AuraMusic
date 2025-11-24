import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../data/services/local_storage.dart';

final likedSongsProvider = StateNotifierProvider<LikedSongsNotifier, List<SongModel>>((ref) {
  return LikedSongsNotifier();
});

class LikedSongsNotifier extends StateNotifier<List<SongModel>> {
  LikedSongsNotifier() : super(LocalStorage.getLikedSongs());

  void toggleLike(SongModel song) {
    if (LocalStorage.isLiked(song.id)) {
      LocalStorage.unlikeSong(song.id);
      state = state.where((s) => s.id != song.id).toList();
    } else {
      LocalStorage.likeSong(song);
      state = [...state, song];
    }
  }

  bool isLiked(String id) => LocalStorage.isLiked(id);
}

final recentSongsProvider = Provider<List<SongModel>>((ref) {
  return LocalStorage.getRecentSongs();
});
