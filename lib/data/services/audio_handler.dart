import 'package:just_audio/just_audio.dart';

export 'package:just_audio/just_audio.dart' show ProcessingState;

class AudioPlayerHandler {
  final _player = AudioPlayer();

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setAudioUrl(String url) async {
    await _player.setUrl(url);
  }

  AudioPlayer get player => _player;
  
  void dispose() => _player.dispose();
}
