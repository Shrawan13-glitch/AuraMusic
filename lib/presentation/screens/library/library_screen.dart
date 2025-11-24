import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/liked_songs_provider.dart';
import '../../providers/player_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedSongs = ref.watch(likedSongsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Library'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Songs'),
              Tab(text: 'Artists'),
              Tab(text: 'Albums'),
              Tab(text: 'Playlists'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            likedSongs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No liked songs yet', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: likedSongs.length,
                    itemBuilder: (context, index) {
                      final song = likedSongs[index];
                      final currentSong = ref.watch(playerProvider).currentSong;
                      final isPlaying = currentSong?.id == song.id;
                      return ListTile(
                        onTap: () => ref.read(playerProvider.notifier).playSong(song, queue: likedSongs, index: index),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: song.albumArt ?? '',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[800]),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.music_note),
                            ),
                          ),
                        ),
                        title: Text(song.title, style: TextStyle(color: isPlaying ? const Color(0xFF8B5CF6) : null), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: isPlaying ? const Icon(Icons.graphic_eq, color: Color(0xFF8B5CF6)) : null,
                      );
                    },
                  ),
            const Center(child: Text('Artists - Coming Soon')),
            const Center(child: Text('Albums - Coming Soon')),
            const Center(child: Text('Playlists - Coming Soon')),
          ],
        ),
      ),
    );
  }
}
