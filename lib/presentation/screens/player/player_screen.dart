import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../providers/player_provider.dart';
import '../../providers/liked_songs_provider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => context.pop())),
        body: const Center(child: Text('No song playing')),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1E1E1E),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Queue', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('${playerState.queue.length} songs', style: TextStyle(color: Colors.grey[400])),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: playerState.queue.length,
                          itemBuilder: (context, index) {
                            final queueSong = playerState.queue[index];
                            final isCurrent = index == playerState.currentIndex;
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: queueSong.albumArt ?? '',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.grey[800]),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.music_note, size: 20),
                                  ),
                                ),
                              ),
                              title: Text(
                                queueSong.title,
                                style: TextStyle(
                                  color: isCurrent ? const Color(0xFF8B5CF6) : null,
                                  fontWeight: isCurrent ? FontWeight.bold : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(queueSong.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: isCurrent ? const Icon(Icons.graphic_eq, color: Color(0xFF8B5CF6)) : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: song.albumArt ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[900]),
              errorWidget: (context, url, error) => Container(color: Colors.grey[900]),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Expanded(
                    child: Center(
                      child: Hero(
                        tag: 'album_art',
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              imageUrl: song.albumArt ?? '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey[800]),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.music_note, size: 100),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist,
                              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          ref.watch(likedSongsProvider.notifier).isLiked(song.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: ref.watch(likedSongsProvider.notifier).isLiked(song.id)
                              ? Colors.red
                              : Colors.white,
                          size: 28,
                        ),
                        onPressed: () => ref.read(likedSongsProvider.notifier).toggleLike(song),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: const Color(0xFF8B5CF6),
                          inactiveTrackColor: Colors.grey[800],
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: playerState.position.inSeconds.toDouble(),
                          max: playerState.duration.inSeconds.toDouble().clamp(1, double.infinity),
                          onChanged: (value) => ref.read(playerProvider.notifier).seek(Duration(seconds: value.toInt())),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(playerState.position), style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                            Text(_formatDuration(playerState.duration), style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 48,
                        color: playerState.hasPrevious || playerState.position.inSeconds > 3
                            ? Colors.white
                            : Colors.grey[700],
                        onPressed: playerState.hasPrevious || playerState.position.inSeconds > 3
                            ? () => ref.read(playerProvider.notifier).playPrevious()
                            : null,
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B5CF6),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          iconSize: 40,
                          color: Colors.white,
                          onPressed: () => ref.read(playerProvider.notifier).togglePlayPause(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 48,
                        color: playerState.hasNext ? Colors.white : Colors.grey[700],
                        onPressed: playerState.hasNext
                            ? () => ref.read(playerProvider.notifier).playNext()
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
