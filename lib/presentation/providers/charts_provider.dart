import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/charts_repository.dart';

final chartsRepositoryProvider = Provider((ref) => ChartsRepository());

final youtubeChartsProvider = FutureProvider<List<SongModel>>((ref) async {
  print('🔄 Loading YouTube Charts...');
  final repository = ref.watch(chartsRepositoryProvider);
  final songs = await repository.getYouTubeCharts();
  print('📦 Charts Provider returned ${songs.length} songs');
  return songs;
});

final trendingShortsProvider = FutureProvider<List<SongModel>>((ref) async {
  print('🔄 Loading Trending Shorts...');
  final repository = ref.watch(chartsRepositoryProvider);
  final songs = await repository.getTrendingShorts();
  print('📦 Shorts Provider returned ${songs.length} songs');
  return songs;
});

final dailyMusicVideosProvider = FutureProvider<List<SongModel>>((ref) async {
  print('🔄 Loading Daily Music Videos...');
  final repository = ref.watch(chartsRepositoryProvider);
  final songs = await repository.getDailyMusicVideos();
  print('📦 Music Videos Provider returned ${songs.length} songs');
  return songs;
});
