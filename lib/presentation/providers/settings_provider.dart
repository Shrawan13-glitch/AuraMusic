import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool autoplay;
  final String audioQuality;

  SettingsState({
    this.autoplay = true,
    this.audioQuality = 'High',
  });

  SettingsState copyWith({
    bool? autoplay,
    String? audioQuality,
  }) {
    return SettingsState(
      autoplay: autoplay ?? this.autoplay,
      audioQuality: audioQuality ?? this.audioQuality,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        state = SettingsState(
          autoplay: prefs.getBool('autoplay') ?? true,
          audioQuality: prefs.getString('audioQuality') ?? 'High',
        );
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> setAutoplay(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoplay', value);
    state = state.copyWith(autoplay: value);
  }

  Future<void> setAudioQuality(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audioQuality', value);
    state = state.copyWith(audioQuality: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
