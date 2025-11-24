import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/services/audio_handler.dart';
import '../../data/services/local_storage.dart';

final musicRepositoryProvider = Provider((ref) => MusicRepository());

final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  final handler = AudioPlayerHandler();
  ref.onDispose(() => handler.dispose());
  return handler;
});

class PlayerState {
  final SongModel? currentSong;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final List<SongModel> queue;
  final int currentIndex;

  PlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = 0,
  });

  PlayerState copyWith({
    SongModel? currentSong,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    List<SongModel>? queue,
    int? currentIndex,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  bool get hasNext => currentIndex < queue.length - 1;
  bool get hasPrevious => currentIndex > 0;
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  final MusicRepository _repository;
  final AudioPlayerHandler _handler;
  Future<void>? _currentLoadOperation;
  final List<DateTime> _recentChanges = [];
  DateTime? _cooldownUntil;

  PlayerNotifier(this._repository, this._handler) : super(PlayerState()) {
    _handler.player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _handler.player.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(duration: dur);
    });
    _handler.player.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });
    _handler.player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.completed && mounted) {
        _onSongCompleted();
      }
    });
  }

  Future<void> playSong(SongModel song, {List<SongModel>? queue, int? index}) async {
    _recentChanges.clear();
    _cooldownUntil = null;
    
    if (queue != null) {
      final songIndex = index ?? queue.indexWhere((s) => s.id == song.id);
      state = state.copyWith(
        queue: queue,
        currentIndex: songIndex >= 0 ? songIndex : 0,
      );
    } else if (state.queue.isEmpty) {
      state = state.copyWith(queue: [song], currentIndex: 0);
    } else {
      final existingIndex = state.queue.indexWhere((s) => s.id == song.id);
      if (existingIndex >= 0) {
        state = state.copyWith(currentIndex: existingIndex);
      } else {
        final newQueue = [...state.queue, song];
        state = state.copyWith(queue: newQueue, currentIndex: newQueue.length - 1);
      }
    }
    await _playCurrentSong();
  }

  Future<void> _playCurrentSong() async {
    if (state.queue.isEmpty || state.currentIndex >= state.queue.length || state.currentIndex < 0) return;
    
    final song = state.queue[state.currentIndex];
    state = state.copyWith(isLoading: true, currentSong: song, position: Duration.zero);
    
    if (_currentLoadOperation != null) {
      try {
        await _handler.stop();
      } catch (e) {}
    }
    
    _currentLoadOperation = _loadAndPlay(song);
    await _currentLoadOperation;
    _currentLoadOperation = null;
  }

  Future<void> _loadAndPlay(SongModel song) async {
    try {
      await _handler.stop();
    } catch (e) {
      print('Error stopping player: $e');
    }
    
    try {
      final audioUrl = await _repository.getAudioUrl(song.url);
      if (audioUrl != null && mounted && state.currentSong?.id == song.id) {
        try {
          await _handler.setAudioUrl(audioUrl);
          if (mounted && state.currentSong?.id == song.id) {
            await _handler.play();
            await LocalStorage.addRecent(song);
          }
        } catch (e) {
          print('Error setting audio URL or playing: $e');
        }
      }
    } catch (e) {
      print('Error getting audio URL: $e');
    }
    
    if (mounted) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> playNext() async {
    if (!state.hasNext || !_canChangeTrack()) return;
    state = state.copyWith(currentIndex: state.currentIndex + 1);
    await _playCurrentSong();
  }

  Future<void> playPrevious() async {
    if (state.position.inSeconds > 3) {
      seek(Duration.zero);
    } else if (state.hasPrevious && _canChangeTrack()) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
      await _playCurrentSong();
    } else {
      seek(Duration.zero);
    }
  }

  bool _canChangeTrack() {
    final now = DateTime.now();
    
    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) {
      return false;
    }
    
    _recentChanges.removeWhere((time) => now.difference(time).inSeconds > 2);
    _recentChanges.add(now);
    
    if (_recentChanges.length >= 3) {
      _cooldownUntil = now.add(const Duration(seconds: 1));
      Future.delayed(const Duration(seconds: 1), () {
        _cooldownUntil = null;
        _recentChanges.clear();
      });
      return false;
    }
    
    return true;
  }

  Future<void> _onSongCompleted() async {
    if (state.hasNext) {
      await playNext();
    } else {
      state = state.copyWith(isPlaying: false, position: Duration.zero);
    }
  }

  void togglePlayPause() {
    if (state.isPlaying) {
      _handler.pause();
    } else {
      _handler.play();
    }
  }

  void seek(Duration position) => _handler.seek(position);
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  final repository = ref.watch(musicRepositoryProvider);
  final handler = ref.watch(audioHandlerProvider);
  return PlayerNotifier(repository, handler);
});
