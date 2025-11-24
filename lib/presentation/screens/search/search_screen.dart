import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/search_provider.dart';
import '../../providers/player_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    
    final repository = ref.read(musicRepositoryProvider);
    final suggestions = await repository.getSearchSuggestions(query);
    setState(() {
      _suggestions = suggestions;
      _showSuggestions = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Search songs, artists...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                          _controller.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        })
                      : null,
                ),
                onChanged: (value) {
                  _fetchSuggestions(value);
                },
                onSubmitted: (value) {
                  setState(() => _showSuggestions = false);
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              ),
            ),
            Expanded(
              child: _showSuggestions && _suggestions.isNotEmpty
                  ? ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.search, size: 20),
                          title: Text(suggestion),
                          onTap: () {
                            _controller.text = suggestion;
                            setState(() => _showSuggestions = false);
                            ref.read(searchQueryProvider.notifier).state = suggestion;
                          },
                        );
                      },
                    )
                  : searchResults.when(
                data: (songs) {
                  if (songs.isEmpty) {
                    return const Center(child: Text('Search for music'));
                  }
                  return ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final currentSong = ref.watch(playerProvider).currentSong;
                      final isPlaying = currentSong?.id == song.id;
                      return ListTile(
                        onTap: () => ref.read(playerProvider.notifier).playSong(song, queue: songs, index: index),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: song.albumArt ?? '',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[800]),
                            errorWidget: (context, url, error) => Container(color: Colors.grey[800], child: const Icon(Icons.music_note)),
                          ),
                        ),
                        title: Text(song.title, style: TextStyle(fontWeight: FontWeight.bold, color: isPlaying ? const Color(0xFF8B5CF6) : null), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(song.artist, style: TextStyle(color: Colors.grey[400]), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: isPlaying ? const Icon(Icons.graphic_eq, color: Color(0xFF8B5CF6)) : null,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
