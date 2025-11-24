import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class MusicRepository {
  static const _platform = MethodChannel('com.shrynex.auramusic/newpipe');

  Future<List<SongModel>> search(String query) async {
    try {
      final response = await http.post(
        Uri.parse('https://music.youtube.com/youtubei/v1/search?prettyPrint=false'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
          'Origin': 'https://music.youtube.com',
          'Referer': 'https://music.youtube.com/',
          'X-YouTube-Client-Name': '67',
          'X-YouTube-Client-Version': '1.20251117.03.00',
        },
        body: jsonEncode({
          'context': {
            'client': {
              'clientName': 'WEB_REMIX',
              'clientVersion': '1.20251117.03.00',
              'hl': 'en-GB',
              'gl': 'IN',
            },
          },
          'query': query,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseSearchResults(data);
      }
    } catch (e) {
      print('Search error: $e');
    }
    return [];
  }

  List<SongModel> _parseSearchResults(Map<String, dynamic> data) {
    final songs = <SongModel>[];
    try {
      final contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List?;
      if (contents == null || contents.length < 2) return songs;

      final items = contents[1]?['musicShelfRenderer']?['contents'] as List?;
      if (items == null) return songs;

      for (var item in items) {
        final renderer = item['musicResponsiveListItemRenderer'];
        if (renderer == null) continue;

        final videoId = renderer['playlistItemData']?['videoId'];
        if (videoId == null) continue;

        final flexColumns = renderer['flexColumns'] as List?;
        if (flexColumns == null || flexColumns.isEmpty) continue;

        final title = flexColumns[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'];
        String? artist;
        if (flexColumns.length > 1) {
          final runs = flexColumns[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
          if (runs != null && runs.length > 2) {
            final artistText = runs.skip(2).map((r) => r['text']?.toString() ?? '').join('').trim();
            artist = artistText.isNotEmpty ? artistText : null;
          }
        }

        final thumbnails = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
        final thumbnail = thumbnails?.isNotEmpty == true ? thumbnails!.last['url'] : null;

        if (title != null) {
          songs.add(SongModel(
            id: videoId,
            title: title,
            artist: artist ?? 'Unknown Artist',
            albumArt: thumbnail,
            url: 'https://www.youtube.com/watch?v=$videoId',
          ));
        }
        if (songs.length >= 20) break;
      }
    } catch (e) {
      print('Parse error: $e');
    }
    return songs;
  }

  Future<String?> getAudioUrl(String videoUrl) async {
    try {
      final result = await _platform.invokeMethod('getStreamInfo', {'url': videoUrl});
      return result['audioUrl'];
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await http.post(
        Uri.parse('https://music.youtube.com/youtubei/v1/music/get_search_suggestions?prettyPrint=false'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
          'Origin': 'https://music.youtube.com',
          'Referer': 'https://music.youtube.com/',
          'X-YouTube-Client-Name': '67',
          'X-YouTube-Client-Version': '1.20251117.03.00',
        },
        body: jsonEncode({
          'input': query,
          'context': {
            'client': {
              'clientName': 'WEB_REMIX',
              'clientVersion': '1.20251117.03.00',
              'hl': 'en-GB',
              'gl': 'IN',
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseSuggestions(data);
      }
    } catch (e) {
      print('Suggestions error: $e');
    }
    return [];
  }

  List<String> _parseSuggestions(Map<String, dynamic> data) {
    final suggestions = <String>[];
    try {
      final contents = data['contents'] as List?;
      if (contents == null || contents.isEmpty) return suggestions;

      final items = contents[0]?['searchSuggestionsSectionRenderer']?['contents'] as List?;
      if (items == null) return suggestions;

      for (var item in items) {
        final runs = item['searchSuggestionRenderer']?['suggestion']?['runs'] as List?;
        if (runs != null) {
          final suggestion = runs.map((r) => r['text']?.toString() ?? '').join('');
          if (suggestion.isNotEmpty) {
            suggestions.add(suggestion);
          }
        }
      }
    } catch (e) {
      print('Parse suggestions error: $e');
    }
    return suggestions;
  }

  void dispose() {}
}
