class SongModel {
  final String id;
  final String title;
  final String artist;
  final String? albumArt;
  final String url;
  final Duration? duration;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArt,
    required this.url,
    this.duration,
  });
}
