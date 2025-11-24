import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class ChartsRepository {
  Future<List<SongModel>> getYouTubeCharts() async {
    try {
      print('📊 Fetching YouTube Charts...');
      
      final response = await http.post(
        Uri.parse('https://charts.youtube.com/youtubei/v1/browse?alt=json'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
          'Origin': 'https://charts.youtube.com',
          'Referer': 'https://charts.youtube.com/',
          'X-YouTube-Client-Name': '31',
          'X-YouTube-Client-Version': '2.0',
        },
        body: jsonEncode({
          'context': {
            'client': {
              'clientName': 'WEB_MUSIC_ANALYTICS',
              'clientVersion': '2.0',
              'hl': 'en-GB',
              'gl': 'IN',
              'experimentIds': [],
              'experimentsToken': '',
              'theme': 'MUSIC',
            },
            'capabilities': {},
            'request': {
              'internalExperimentFlags': [],
            },
          },
          'browseId': 'FEmusic_analytics_charts_home',
          'query': 'perspective=CHART_DETAILS&chart_params_country_code=in&chart_params_chart_type=TRACKS&chart_params_period_type=WEEKLY',
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📝 Response keys: ${data.keys.toList()}');
        final songs = _parseChartsData(data);
        print('✅ Found ${songs.length} chart songs');
        return songs;
      } else {
        print('❌ Bad response: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching charts: $e');
    }
    return [];
  }

  Future<List<SongModel>> getTrendingShorts() async {
    try {
      print('🎬 Fetching Trending Shorts...');
      
      final response = await http.post(
        Uri.parse('https://charts.youtube.com/youtubei/v1/browse?alt=json'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
          'Origin': 'https://charts.youtube.com',
          'Referer': 'https://charts.youtube.com/',
          'X-YouTube-Client-Name': '31',
          'X-YouTube-Client-Version': '2.0',
        },
        body: jsonEncode({
          'context': {
            'client': {
              'clientName': 'WEB_MUSIC_ANALYTICS',
              'clientVersion': '2.0',
              'hl': 'en-GB',
              'gl': 'IN',
              'experimentIds': [],
              'experimentsToken': '',
              'theme': 'MUSIC',
            },
            'capabilities': {},
            'request': {
              'internalExperimentFlags': [],
            },
          },
          'browseId': 'FEmusic_analytics_charts_home',
          'query': 'perspective=CHART_DETAILS&chart_params_country_code=in&chart_params_chart_type=SHORTS_TRACKS_BY_USAGE&chart_params_period_type=DAILY',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final songs = _parseChartsData(data);
        print('✅ Found ${songs.length} trending shorts');
        return songs;
      }
    } catch (e) {
      print('❌ Error fetching shorts: $e');
    }
    return [];
  }

  Future<List<SongModel>> getDailyMusicVideos() async {
    try {
      print('🎥 Fetching Daily Music Videos...');
      
      final response = await http.post(
        Uri.parse('https://charts.youtube.com/youtubei/v1/browse?alt=json'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
          'Origin': 'https://charts.youtube.com',
          'Referer': 'https://charts.youtube.com/',
          'X-YouTube-Client-Name': '31',
          'X-YouTube-Client-Version': '2.0',
        },
        body: jsonEncode({
          'context': {
            'client': {
              'clientName': 'WEB_MUSIC_ANALYTICS',
              'clientVersion': '2.0',
              'hl': 'en-GB',
              'gl': 'IN',
              'experimentIds': [],
              'experimentsToken': '',
              'theme': 'MUSIC',
            },
            'capabilities': {},
            'request': {
              'internalExperimentFlags': [],
            },
          },
          'browseId': 'FEmusic_analytics_charts_home',
          'query': 'perspective=CHART_DETAILS&chart_params_country_code=in&chart_params_chart_type=VIDEOS&chart_params_period_type=DAILY',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final songs = _parseMusicVideos(data);
        print('✅ Found ${songs.length} music videos');
        return songs;
      }
    } catch (e) {
      print('❌ Error fetching music videos: $e');
    }
    return [];
  }

  List<SongModel> _parseMusicVideos(Map<String, dynamic> data) {
    final songs = <SongModel>[];
    try {
      final videos = data['contents']?['sectionListRenderer']?['contents']?[0]?['musicAnalyticsSectionRenderer']?['content']?['videos']?[0]?['videoViews'] as List?;
      if (videos != null) {
        for (var video in videos) {
          final videoId = video['id'];
          final title = video['title'];
          final artists = video['artists'] as List?;
          final artist = artists?.isNotEmpty == true ? artists![0]['name'] : 'Unknown Artist';
          final thumbnails = video['thumbnail']?['thumbnails'] as List?;
          final thumbnail = thumbnails?.isNotEmpty == true ? thumbnails!.last['url'] : null;

          if (videoId != null && title != null) {
            songs.add(SongModel(
              id: videoId,
              title: title,
              artist: artist,
              albumArt: thumbnail,
              url: 'https://www.youtube.com/watch?v=$videoId',
            ));
          }
          if (songs.length >= 50) break;
        }
      }
    } catch (e) {
      print('❌ Error parsing music videos: $e');
    }
    return songs;
  }

  List<SongModel> _parseChartsData(Map<String, dynamic> data) {
    final songs = <SongModel>[];
    try {
      print('🔍 Parsing YouTube Music Charts response...');
      if (data['contents'] is Map) {
        print('📝 Contents keys: ${(data['contents'] as Map).keys.toList()}');
      }
      
      final sectionList = data['contents']?['sectionListRenderer']?['contents'] as List?;
      if (sectionList == null || sectionList.isEmpty) {
        print('❌ No sectionListRenderer found');
        return songs;
      }

      print('📦 Found ${sectionList.length} sections');

      final analyticsSection = sectionList[0]['musicAnalyticsSectionRenderer'];
      
      if (analyticsSection != null) {
        print('✅ Found musicAnalyticsSectionRenderer');
        final content = analyticsSection['content'];
        if (content == null) {
          print('❌ No content in analyticsSection');
          return songs;
        }
        
        final trackTypes = content['trackTypes'] as List?;
        if (trackTypes != null && trackTypes.isNotEmpty) {
          final trackViews = trackTypes[0]['trackViews'] as List?;
          if (trackViews != null) {
            print('🎵 Found ${trackViews.length} tracks from analytics');
            for (var track in trackViews) {
              final videoId = track['encryptedVideoId'];
              final title = track['name'];
              final artistsList = track['artists'] as List?;
              final artist = artistsList?.isNotEmpty == true ? artistsList![0]['name'] : 'Unknown Artist';
              final thumbnails = track['thumbnail']?['thumbnails'] as List?;
              final thumbnail = thumbnails?.isNotEmpty == true ? thumbnails!.last['url'] : null;

              if (videoId != null && title != null) {
                print('✅ Parsed: $title by $artist');
                songs.add(SongModel(
                  id: videoId,
                  title: title,
                  artist: artist,
                  albumArt: thumbnail,
                  url: 'https://www.youtube.com/watch?v=$videoId',
                ));
              }
              if (songs.length >= 50) break;
            }
          }
        }
      } else {
        // Fallback to musicShelfRenderer
        print('🔄 Trying musicShelfRenderer');
        final shelf = sectionList[0]['musicShelfRenderer'];
        if (shelf != null) {
          final contents = shelf['contents'] as List?;
          if (contents != null) {
            print('🎵 Found ${contents.length} items from shelf');
            for (var item in contents) {
              final renderer = item['musicResponsiveListItemRenderer'];
              if (renderer == null) continue;

              final playlistData = renderer['playlistItemData'];
              final videoId = playlistData?['videoId'];
              
              final flexColumns = renderer['flexColumns'] as List?;
              String? title;
              String? artist;
              
              if (flexColumns != null && flexColumns.isNotEmpty) {
                title = flexColumns[0]['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'];
                if (flexColumns.length > 1) {
                  artist = flexColumns[1]['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'];
                }
              }
              
              final thumbnails = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
              final thumbnail = thumbnails?.isNotEmpty == true ? thumbnails!.last['url'] : null;

              if (videoId != null && title != null) {
                print('✅ Parsed: $title by ${artist ?? "Unknown"}');
                songs.add(SongModel(
                  id: videoId,
                  title: title,
                  artist: artist ?? 'Unknown Artist',
                  albumArt: thumbnail,
                  url: 'https://www.youtube.com/watch?v=$videoId',
                ));
              }
              if (songs.length >= 50) break;
            }
          }
        }
      }
    } catch (e, stack) {
      print('❌ Error parsing charts: $e');
      print('🔴 Stack: $stack');
    }
    return songs;
  }
}
